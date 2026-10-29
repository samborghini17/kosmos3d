import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kosmos3d/services/upload_service.dart';
import 'package:kosmos3d/services/system_settings_service.dart';

/// Opt-in real-device test. Uses a configured receiver, sends only a generated
/// diagnostic JSON, and exports that JSON to Downloads. Never reads camera media.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real phone uploads a diagnostic and exports it to Downloads', (tester) async {
    if (!const bool.fromEnvironment('KOSMOS_RUN_DEVICE_SMOKE')) return;
    final root = await getApplicationDocumentsDirectory();
    final file = File('${root.path}/kosmos-transfer-test.json');
    await file.writeAsString('{"type":"kosmos-device-acceptance","cameraMedia":false}');
    final service = UploadService();
    try {
      expect(await service.testConnection(), isTrue, reason: service.lastError);
      expect(await service.uploadFiles([file], projectName: 'Device acceptance'), isTrue, reason: service.lastError);
      final exported = await SystemSettingsService.saveToDownloads(file.path, relativePath: 'Diagnostics/kosmos-transfer-test.json');
      expect(exported, isNotEmpty);
      expect(service.progress, 1);
    } finally { service.dispose(); await file.delete(); }
  });
}
