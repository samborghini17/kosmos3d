import hashlib
import http.client
import json
from pathlib import Path
import tempfile
import threading
import unittest
from http.server import ThreadingHTTPServer
from kosmos_receiver import make_handler

class ReceiverTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.server = ThreadingHTTPServer(('127.0.0.1', 0), make_handler(self.temp.name, 'test-token'))
        self.worker = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.worker.start()
    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.worker.join()
        self.temp.cleanup()
    def request(self, method, path, body=b'', token='test-token', digest=None):
        connection = http.client.HTTPConnection('127.0.0.1', self.server.server_port, timeout=5)
        connection.request(method, path, body, {'Authorization': 'Bearer ' + token,
            'X-Content-SHA256': digest or hashlib.sha256(body).hexdigest()})
        response = connection.getresponse()
        result = response.status, dict(response.getheaders()), response.read()
        connection.close()
        return result
    def test_verified_upload_and_head(self):
        data = b'original-media' * 10000
        status, _, body = self.request('PUT', '/files/project/captures/clip.mp4', data)
        self.assertEqual(status, 201)
        self.assertEqual(json.loads(body)['sha256'], hashlib.sha256(data).hexdigest())
        status, headers, _ = self.request('HEAD', '/files/project/captures/clip.mp4')
        self.assertEqual(status, 200)
        self.assertEqual(int(headers['Content-Length']), len(data))
        self.assertEqual((Path(self.temp.name)/'project/captures/clip.mp4').read_bytes(), data)
    def test_checksum_mismatch_never_publishes(self):
        self.assertEqual(self.request('PUT', '/files/project/clip.mp4', b'bad', digest='0'*64)[0], 422)
        self.assertEqual(list(Path(self.temp.name).rglob('*.mp4')), [])
        self.assertEqual(list(Path(self.temp.name).rglob('*.part')), [])
    def test_traversal_is_rejected(self):
        self.assertEqual(self.request('PUT', '/files/project/%2e%2e/%2e%2e/escape', b'bad')[0], 400)
    def test_auth_required(self):
        self.assertEqual(self.request('PUT', '/files/project/clip.mp4', b'bad', token='wrong')[0], 401)
        self.assertEqual(self.request('GET', '/health')[0], 200)

if __name__ == '__main__':
    unittest.main()
