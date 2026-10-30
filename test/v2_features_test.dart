import 'package:flutter_test/flutter_test.dart';
import 'package:kosmos3d/l10n/ui_dictionary.dart';
import 'package:kosmos3d/screens/camera_networks_screen.dart';
import 'package:kosmos3d/services/cloud_storage_service.dart';
import 'package:kosmos3d/services/gopro_protocol.dart';
import 'package:kosmos3d/services/gopro_setting_catalog.dart';
import 'package:kosmos3d/widgets/gaussian_labs_qr.dart';

void main() {
  group('German dictionary', () {
    String de(String text) => UiDictionary.translate('de', text);

    test('specific template wins over a generic one', () {
      expect(de('Transferred 12 files'), '12 Dateien übertragen');
      expect(de('12 files'), '12 Dateien');
    });

    test('error prefixes are translated together with the message', () {
      expect(
        de('Bad state: Stop capture first'),
        'Fehler: Zuerst die Aufnahme beenden',
      );
      expect(
        de('Bad state: Camera AA:BB is disconnected; reconnect it'),
        'Fehler: Kamera AA:BB ist getrennt; neu verbinden',
      );
    });

    test('multi-line status translates line by line', () {
      expect(
        de('Import complete: 4 local files.\nStored in: /x'),
        'Import abgeschlossen: 4 lokale Dateien.\nGespeichert in: /x',
      );
    });

    test('every catalog setting name has German', () {
      final missing = goProSettingCatalog
          .map((s) => s.name)
          .where((n) => de(n) == n && !{'GPS', 'LED'}.contains(n))
          .toList();
      expect(missing, isEmpty);
    });

    test('English is returned unchanged', () {
      expect(
        UiDictionary.translate('en', 'Stop capture first'),
        'Stop capture first',
      );
    });
  });

  group('S3 storage', () {
    const config = StorageServerConfig(
      endpoint: 's3.eu-central-003.backblazeb2.com',
      region: '',
      bucket: 'bucket',
      accessKeyId: 'AKID',
      secretKey: 'secret',
    );

    test('region and base URI are derived from the endpoint', () {
      expect(config.effectiveRegion, 'eu-central-003');
      expect(
        config.baseUri.toString(),
        'https://s3.eu-central-003.backblazeb2.com',
      );
      expect(
        const StorageServerConfig(
          endpoint: 'https://abc.r2.cloudflarestorage.com',
          region: '',
          bucket: 'b',
          accessKeyId: 'a',
          secretKey: 's',
        ).effectiveRegion,
        'auto',
      );
    });

    test('keys are RFC 3986 encoded and the request is signed', () {
      expect(S3Signer.encode('a b+c (1)!'), 'a%20b%2Bc%20%281%29%21');
      expect(S3Signer.encode('x/y z', keepSlash: true), 'x/y%20z');
      final signed = S3Signer(config).sign(
        method: 'PUT',
        key: 'kosmos3d/Scan 1/captures/GX01.JPG',
        now: DateTime.utc(2026, 10, 30, 12),
      );
      expect(
        signed.uri.toString(),
        'https://s3.eu-central-003.backblazeb2.com/bucket/kosmos3d/Scan%201/captures/GX01.JPG',
      );
      expect(signed.headers['x-amz-date'], '20261030T120000Z');
      expect(
        signed.headers['authorization'],
        startsWith(
          'AWS4-HMAC-SHA256 Credential=AKID/20261030/eu-central-003/s3/aws4_request, '
          'SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=',
        ),
      );
    });

    test('project folder names are safe', () {
      expect(
        CloudStorageService.safeSegment('Haus Müller / Süd'),
        'Haus-M-ller-S-d',
      );
      expect(CloudStorageService.safeSegment('  '), 'project');
    });
  });

  test('capability responses keep every repeated option', () {
    final payload = [0x32, 0, 122, 1, 27, 122, 1, 28, 125, 1, 0, 125, 1, 1];
    expect(decodeTlvMulti(payload), {
      122: [
        [27],
        [28],
      ],
      125: [
        [0],
        [1],
      ],
    });
  });

  test('Wi-Fi QR escapes special characters', () {
    expect(
      wifiQrPayload('GP;123', 'pa:ss,word'),
      r'WIFI:T:WPA;S:GP\;123;P:pa\:ss\,word;;',
    );
  });

  test('Labs exposure recipe encodes ISO, white balance and clock', () {
    expect(
      exposureLabsRecipe(
        iso: 100,
        kelvin: 5500,
        now: DateTime(2026, 10, 30, 9, 5, 7, 42),
      ),
      'i1M1w55oT261030090507.042',
    );
    expect(
      exposureLabsRecipe(iso: 400, kelvin: null, now: DateTime(2026)),
      startsWith('i4M4wAoT'),
    );
  });
}
