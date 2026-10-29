import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kosmos3d/providers/settings_provider.dart';
import 'package:kosmos3d/l10n/ui_dictionary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'new installations use English, one second, outdoor photo and coverage',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.ready;
      final defaults = await settings.getDefaultSettings();
      expect(settings.currentLanguage, 'en');
      expect(settings.captureInterval, '1s');
      expect(settings.coverageVisualizer, true);
      expect(defaults['Mode'], 'photo');
      expect(defaults['Photo Format'], 'Standard Photo');
      expect(defaults['Lens'], 'Linear');
      expect(defaults['Target ISO'], '100');
      expect(defaults['Orientation'], 'Portrait');
      // A recommendation must never masquerade as a verified API override.
      expect(defaults['ISO Max'], 'Camera preset');
      settings.dispose();
    },
  );
  test(
    'German translates dynamic transfer labels without modifying protocol values',
    () {
      expect(
        UiDictionary.translate('de', 'Import all files from 3 cameras'),
        'Alle Dateien von 3 Kameras importieren',
      );
      expect(
        UiDictionary.translate('de', '12 local files'),
        '12 lokale Dateien',
      );
      expect(UiDictionary.translate('en', '12 local files'), '12 local files');
      expect(UiDictionary.translate('de', 'KOSMOS 3D'), 'KOSMOS 3D');
    },
  );
}
