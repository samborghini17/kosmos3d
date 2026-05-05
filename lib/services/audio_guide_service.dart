import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Audio guide service that provides voice and haptic feedback during scanning.
/// Uses iOS AVSpeechSynthesizer / Android TTS via platform channel,
/// with a fallback to haptic-only feedback.
class AudioGuideService extends ChangeNotifier {
  static const _channel = MethodChannel('com.kosmos3d/audio_guide');

  bool _isEnabled = true;
  bool _isSpeaking = false;
  String _lastMessage = '';
  DateTime? _lastSpokenAt;

  // Minimum interval between spoken messages (avoid spam)
  final Duration _cooldown = const Duration(seconds: 4);

  bool get isEnabled => _isEnabled;
  bool get isSpeaking => _isSpeaking;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  /// Speak a message using TTS. Falls back to haptic if TTS unavailable.
  Future<void> speak(String message, {bool force = false}) async {
    if (!_isEnabled && !force) return;

    // Cooldown to avoid rapid-fire messages
    if (!force && _lastSpokenAt != null &&
        DateTime.now().difference(_lastSpokenAt!) < _cooldown) {
      return;
    }

    // Don't repeat the same message
    if (!force && message == _lastMessage &&
        _lastSpokenAt != null &&
        DateTime.now().difference(_lastSpokenAt!) < const Duration(seconds: 10)) {
      return;
    }

    _lastMessage = message;
    _lastSpokenAt = DateTime.now();
    _isSpeaking = true;
    notifyListeners();

    try {
      if (_isMobilePlatform) {
        await _channel.invokeMethod('speak', {'text': message});
      }
    } catch (e) {
      // TTS not available — use haptic feedback instead
      debugPrint('TTS not available, using haptic: $e');
      await HapticFeedback.mediumImpact();
    }

    _isSpeaking = false;
    notifyListeners();
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    try {
      if (_isMobilePlatform) {
        await _channel.invokeMethod('stop');
      }
    } catch (_) {}
    _isSpeaking = false;
    notifyListeners();
  }

  // ─── Pre-built Guidance Messages ─────────────────────────

  /// Called when movement is too fast
  Future<void> warnTooFast(double speedMs) async {
    await speak('Slow down. Moving too fast.');
  }

  /// Called when there's a large coverage gap
  Future<void> suggestDirection(String direction, int degrees) async {
    await speak('Turn $direction to fill coverage gap.');
  }

  /// Called when captures are too close together
  Future<void> warnTooClose() async {
    await speak('Rotate more before next capture.');
  }

  /// Called when captures are too far apart
  Future<void> warnLargeGap(int degrees) async {
    await speak('Large gap detected. Move slower.');
  }

  /// Called when coverage is excellent
  Future<void> announceGoodCoverage(int percentage) async {
    await speak('Good coverage at $percentage percent.');
  }

  /// Called when scan quality is excellent
  Future<void> announceExcellentQuality(int score) async {
    await speak('Excellent quality. Score $score out of 100.');
  }

  /// Called at capture trigger
  Future<void> confirmCapture(int count) async {
    // Just haptic for captures — too frequent for voice
    await HapticFeedback.heavyImpact();
  }

  /// Called when battery is low on a camera
  Future<void> warnLowBattery(String cameraName, int percentage) async {
    await speak('$cameraName battery low at $percentage percent.', force: true);
  }

  /// Called when SD card is nearly full
  Future<void> warnLowStorage(String cameraName) async {
    await speak('$cameraName storage almost full.', force: true);
  }

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
