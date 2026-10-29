"""KOSMOS 3D file receiver. Python 3.10+, standard library only."""
import argparse
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlsplit

def sha256_file(path):
    digest = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()

def make_handler(root, token, max_bytes=100 * 1024 ** 3):
    root = Path(root).resolve()
    root.mkdir(parents=True, exist_ok=True)
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            # Never log the Authorization header or file contents.
            print("%s %s" % (self.address_string(), fmt % args))
        def authorized(self):
            value = self.headers.get('Authorization', '')
            if not hmac.compare_digest(value, 'Bearer ' + token):
                self.respond(401, {'error': 'Authentication required'})
                return False
            return True
        def respond(self, status, data):
            payload = json.dumps(data).encode()
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(payload)))
            self.send_header('Connection', 'close')
            self.end_headers()
            self.close_connection = True
            if self.command != 'HEAD':
                self.wfile.write(payload)
        def destination(self):
            path = unquote(urlsplit(self.path).path)
            if not path.startswith('/files/'):
                raise ValueError('Unknown route')
            parts = path[len('/files/'):].split('/')
            if len(parts) < 2 or any(p in ('', '.', '..') or '\\' in p or ':' in p or '\x00' in p for p in parts):
                raise ValueError('Invalid path')
            target = root.joinpath(*parts).resolve()
            if not target.is_relative_to(root):
                raise ValueError('Path outside storage')
            return target
        def do_GET(self):
            if not self.authorized():
                return
            if urlsplit(self.path).path == '/health':
                self.respond(200, {'service': 'kosmos-transfer', 'version': 1, 'checksum': 'sha256'})
            else:
                self.respond(404, {'error': 'Unknown route'})
        def do_HEAD(self):
            if not self.authorized():
                return
            try:
                target = self.destination()
                if not target.is_file():
                    self.respond(404, {'error': 'Not found'})
                    return
                digest = sha256_file(target)
                self.send_response(200)
                self.send_header('Content-Length', str(target.stat().st_size))
                self.send_header('X-Content-SHA256', digest)
                self.send_header('Connection', 'close')
                self.end_headers()
                self.close_connection = True
            except ValueError as exc:
                self.respond(400, {'error': str(exc)})
        def do_PUT(self):
            if not self.authorized():
                return
            temporary = None
            try:
                target = self.destination()
                expected = self.headers.get('X-Content-SHA256', '')
                if not re.fullmatch(r'[0-9a-f]{64}', expected):
                    raise ValueError('SHA-256 required')
                length = int(self.headers.get('Content-Length', '-1'))
                if length < 0 or length > max_bytes:
                    raise ValueError('Invalid file length')
                self.connection.settimeout(30)
                target.parent.mkdir(parents=True, exist_ok=True)
                digest = hashlib.sha256()
                remaining = length
                with tempfile.NamedTemporaryFile(prefix='.kosmos-', suffix='.part', dir=target.parent, delete=False) as output:
                    temporary = Path(output.name)
                    while remaining:
                        block = self.rfile.read(min(256 * 1024, remaining))
                        if not block:
                            raise ValueError('Incomplete upload')
                        output.write(block)
                        digest.update(block)
                        remaining -= len(block)
                    output.flush()
                    os.fsync(output.fileno())
                actual = digest.hexdigest()
                if not hmac.compare_digest(actual, expected):
                    self.respond(422, {'error': 'Checksum mismatch'})
                    return
                os.replace(temporary, target)
                temporary = None
                self.respond(201, {'sha256': actual, 'bytes': length})
            except (ValueError, OSError) as exc:
                self.respond(400, {'error': str(exc)})
            finally:
                if temporary is not None:
                    temporary.unlink(missing_ok=True)
    return Handler

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', required=True, help='Directory for received projects')
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=8787)
    args = parser.parse_args()
    token = os.environ.get('KOSMOS_TRANSFER_TOKEN', '')
    if len(token) < 16:
        parser.error('Set KOSMOS_TRANSFER_TOKEN to an access token with at least 16 characters.')
    server = ThreadingHTTPServer((args.host, args.port), make_handler(args.root, token))
    print(f'KOSMOS receiver on {args.host}:{args.port}; storage: {Path(args.root).resolve()}')
    print('Use HTTPS through a reverse proxy for access outside a trusted local network.')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()

if __name__ == '__main__':
    main()
