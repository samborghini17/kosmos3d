import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_translations.dart';

/// Preset profile for quick camera configuration
class CameraPreset {
  final String name;
  final String icon;
  final Map<String, String> settings;

  const CameraPreset({required this.name, required this.icon, required this.settings});

  Map<String, dynamic> toJson() => {'name': name, 'icon': icon, 'settings': settings};

  factory CameraPreset.fromJson(Map<String, dynamic> json) => CameraPreset(
    name: json['name'] as String,
    icon: json['icon'] as String? ?? '📷',
    settings: Map<String, String>.from(json['settings'] as Map),
  );
}

class SettingsProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  ThemeMode _themeMode = ThemeMode.system;
  List<CameraPreset> _customPresets = [];
  bool _hapticFeedback = true;
  bool _autoUpload = false;
  bool _recordBarometer = true;
  int _sensorRate = 50; // ms
  int _gpsRate = 2; // seconds
  bool _stayAwake = true; // prevent phone sleep during scans
  bool _debugLogging = false; // verbose BLE/sensor logs
  bool _autoReconnect = true; // auto-reconnect lost cameras
  int _scanTimeout = 5; // BLE scan duration in seconds

  String get currentLanguage => _currentLanguage;
  ThemeMode get themeMode => _themeMode;
  bool get hapticFeedback => _hapticFeedback;
  bool get autoUpload => _autoUpload;
  bool get recordBarometer => _recordBarometer;
  int get sensorRate => _sensorRate;
  int get gpsRate => _gpsRate;
  bool get stayAwake => _stayAwake;
  bool get debugLogging => _debugLogging;
  bool get autoReconnect => _autoReconnect;
  int get scanTimeout => _scanTimeout;

  // ─── BUILT-IN PRESETS ────────────────────────────────────
  static const List<CameraPreset> builtInPresets = [
    CameraPreset(
      name: 'Interior Scan',
      icon: '🏠',
      settings: {
        'Resolution': '4K', 'FPS': '30', 'Lens': 'Linear',
        'ISO Max': '400', 'Shutter': 'Auto', 'White Balance': '5500K', 'Bitrate': 'High',
      },
    ),
    CameraPreset(
      name: 'Outdoor Scan',
      icon: '🌳',
      settings: {
        'Resolution': '4K', 'FPS': '60', 'Lens': 'Wide',
        'ISO Max': '100', 'Shutter': 'Auto', 'White Balance': 'Auto', 'Bitrate': 'High',
      },
    ),
    CameraPreset(
      name: 'Detail Scan',
      icon: '🔬',
      settings: {
        'Resolution': '5.3K', 'FPS': '24', 'Lens': 'Linear',
        'ISO Max': '200', 'Shutter': '1/60', 'White Balance': '5500K', 'Bitrate': 'High',
      },
    ),
    CameraPreset(
      name: 'Video Walk',
      icon: '🎬',
      settings: {
        'Resolution': '4K', 'FPS': '60', 'Lens': 'Linear',
        'ISO Max': '800', 'Shutter': 'Auto', 'White Balance': 'Auto', 'Bitrate': 'High',
      },
    ),
  ];

  List<CameraPreset> get allPresets => [...builtInPresets, ..._customPresets];
  List<CameraPreset> get customPresets => _customPresets;

  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en';

    // Theme mode
    final themeStr = prefs.getString('theme_mode') ?? 'system';
    _themeMode = themeStr == 'dark' ? ThemeMode.dark
        : themeStr == 'light' ? ThemeMode.light
        : ThemeMode.system;

    // Preferences
    _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
    _autoUpload = prefs.getBool('auto_upload') ?? false;
    _recordBarometer = prefs.getBool('record_barometer') ?? true;
    _sensorRate = prefs.getInt('sensor_rate') ?? 50;
    _gpsRate = prefs.getInt('gps_rate') ?? 2;
    _stayAwake = prefs.getBool('stay_awake') ?? true;
    _debugLogging = prefs.getBool('debug_logging') ?? false;
    _autoReconnect = prefs.getBool('auto_reconnect') ?? true;
    _scanTimeout = prefs.getInt('scan_timeout') ?? 5;

    // Load custom presets
    final presetsJson = prefs.getString('custom_presets');
    if (presetsJson != null) {
      try {
        final list = jsonDecode(presetsJson) as List;
        _customPresets = list.map((e) => CameraPreset.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    notifyListeners();
  }

  // ─── THEME ──────────────────────────────────────────────

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode == ThemeMode.dark ? 'dark'
        : mode == ThemeMode.light ? 'light' : 'system');
    notifyListeners();
  }

  // ─── LANGUAGE ───────────────────────────────────────────

  void toggleLanguage() async {
    _currentLanguage = _currentLanguage == 'en' ? 'de' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
    notifyListeners();
  }

  String translate(String key) {
    return AppTranslations.get(_currentLanguage, key);
  }

  // ─── APP SETTINGS ──────────────────────────────────────

  void setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_feedback', value);
    notifyListeners();
  }

  void setAutoUpload(bool value) async {
    _autoUpload = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_upload', value);
    notifyListeners();
  }

  void setRecordBarometer(bool value) async {
    _recordBarometer = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('record_barometer', value);
    notifyListeners();
  }

  void setSensorRate(int ms) async {
    _sensorRate = ms;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sensor_rate', ms);
    notifyListeners();
  }

  void setGpsRate(int seconds) async {
    _gpsRate = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gps_rate', seconds);
    notifyListeners();
  }

  void setStayAwake(bool value) async {
    _stayAwake = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('stay_awake', value);
    notifyListeners();
  }

  void setDebugLogging(bool value) async {
    _debugLogging = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debug_logging', value);
    notifyListeners();
  }

  void setAutoReconnect(bool value) async {
    _autoReconnect = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_reconnect', value);
    notifyListeners();
  }

  void setScanTimeout(int seconds) async {
    _scanTimeout = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scan_timeout', seconds);
    notifyListeners();
  }

  /// Reset all settings to defaults
  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticFeedback = true;
    _autoUpload = false;
    _recordBarometer = true;
    _sensorRate = 50;
    _gpsRate = 2;
    _stayAwake = true;
    _debugLogging = false;
    _autoReconnect = true;
    _scanTimeout = 5;
    _themeMode = ThemeMode.system;
    _currentLanguage = 'en';
    _customPresets = [];
    await prefs.clear();
    notifyListeners();
  }

  // ─── PRESET MANAGEMENT ──────────────────────────────────

  Future<void> addCustomPreset(CameraPreset preset) async {
    _customPresets.add(preset);
    await _saveCustomPresets();
    notifyListeners();
  }

  Future<void> removeCustomPreset(int index) async {
    if (index >= 0 && index < _customPresets.length) {
      _customPresets.removeAt(index);
      await _saveCustomPresets();
      notifyListeners();
    }
  }

  Future<void> _saveCustomPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_customPresets.map((p) => p.toJson()).toList());
    await prefs.setString('custom_presets', json);
  }

  // ─── DEFAULT SETTINGS ───────────────────────────────────

  Future<Map<String, String>> getDefaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('default_camera_settings');
    if (json != null) {
      try {
        return Map<String, String>.from(jsonDecode(json));
      } catch (_) {}
    }
    return builtInPresets[0].settings;
  }

  Future<void> setDefaultSettings(Map<String, String> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_camera_settings', jsonEncode(settings));
    notifyListeners();
  }
}
