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
  List<CameraPreset> _customPresets = [];

  String get currentLanguage => _currentLanguage;

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

  void toggleLanguage() async {
    _currentLanguage = _currentLanguage == 'en' ? 'de' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
    notifyListeners();
  }

  String translate(String key) {
    return AppTranslations.get(_currentLanguage, key);
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
