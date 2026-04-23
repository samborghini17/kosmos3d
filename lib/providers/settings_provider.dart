import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_translations.dart';

class SettingsProvider extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  void toggleLanguage() async {
    _currentLanguage = _currentLanguage == 'en' ? 'de' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
    notifyListeners();
  }

  String translate(String key) {
    return AppTranslations.get(_currentLanguage, key);
  }
}
