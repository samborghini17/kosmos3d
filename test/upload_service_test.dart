import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosmos3d/services/upload_service.dart';

void main() {
  late Directory directory;
  late HttpServer server;
  late UploadService upload;
  final stored = <String, List<int>>{};
  var puts = 0;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kosmos_upload_');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    stored.clear();
    puts = 0;
    upload = UploadService(
      documents: () async => directory,
      configLoader: () async => {
        'url': 'http://127.0.0.1:${server.port}',
        'api_key': 'test-token',
        'transport': 'kosmos',
      },
    );
  });
  tearDown(() async {
    upload.cancel();
    await server.close(force: true);
    await directory.delete(recursive: true);
  });

  void receive(HttpRequest request) async {
    expect(request.headers.value('authorization'), 'Bearer test-token');
    final key = request.uri.path;
    if (request.method == 'HEAD') {
      final bytes = stored[key];
      request.response.statusCode = bytes == null ? 404 : 200;
      if (bytes != null) {
        request.response.headers.set(
          'X-Content-SHA256',
          sha256.convert(bytes).toString(),
        );
        request.response.contentLength = bytes.length;
      }
    } else {
      puts++;
      final bytes = await request.fold<List<int>>([], (a, b) => a..addAll(b));
      stored[key] = bytes;
      request.response.statusCode = 201;
      request.response.write(
        jsonEncode({
          'sha256': sha256.convert(bytes).toString(),
          'bytes': bytes.length,
        }),
      );
    }
    await request.response.close();
  }

  test(
    'complete project includes originals and metadata; retry verifies and skips stored files',
    () async {
      server.listen(receive);
      final root = Directory('${directory.path}/kosmos3d_projects/p1');
      await Directory('${root.path}/captures').create(recursive: true);
      await File('${root.path}/captures/photo.jpg').writeAsBytes([1, 2, 3]);
      await File(
        '${root.path}/captures/video.mp4',
      ).writeAsBytes(List.filled(100000, 5));
      await File(
        '${root.path}/shutter_events.jsonl',
      ).writeAsString('{"capture":1}\n');
      await File('${root.path}/project.json').writeAsString('{}');
      await File(
        '${root.path}/captures/incomplete.mp4.part',
      ).writeAsString('partial');
      expect(await upload.uploadProject('p1', 'Test project'), isTrue);
      expect(stored.length, 4);
      expect(
        stored.keys.any((p) => p.endsWith('shutter_events.jsonl')),
        isTrue,
      );
      expect(upload.progress, 1);
      expect(await upload.uploadProject('p1', 'Test project'), isTrue);
      expect(puts, 4);
    },
  );

  test('authentication rejection never reports completion', () async {
    server.listen((request) async {
      request.response.statusCode = 401;
      await request.response.close();
    });
    final file = await File('${directory.path}/a.jpg').writeAsBytes([1]);
    expect(await upload.uploadFile(file), isFalse);
    expect(upload.lastError, contains('authentication'));
    expect(upload.progress, lessThan(1));
    expect(upload.isUploading, isFalse);
  });

  test('checksum mismatch is rejected even after HTTP success', () async {
    server.listen((request) async {
      await request.drain<void>();
      if (request.method == 'HEAD') {
        request.response.statusCode = 404;
      } else {
        request.response.write('{"sha256":"incorrect","bytes":1}');
      }
      await request.response.close();
    });
    final file = await File('${directory.path}/a.jpg').writeAsBytes([1]);
    expect(await upload.uploadFile(file), isFalse);
    expect(upload.lastError, contains('checksum'));
    expect(upload.progress, lessThan(1));
  });

  test(
    'cancellation closes pending request and prevents concurrent batch',
    () async {
      final arrived = Completer<void>();
      server.listen((request) async {
        if (!arrived.isCompleted) arrived.complete();
      });
      final file = await File('${directory.path}/a.jpg').writeAsBytes([1]);
      final first = upload.uploadFile(file);
      await arrived.future;
      expect(await upload.uploadFile(file), isFalse);
      upload.cancel();
      expect(await first, isFalse);
      expect(upload.lastError, contains('cancelled'));
      expect(upload.isUploading, isFalse);
    },
  );
}
