import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// LiDAR depth capture service for iOS devices with LiDAR scanner.
/// Uses platform channel to ARKit for depth map capture.
/// Compatible with: iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro, iPad Pro (2020+)
///
/// On non-LiDAR devices, [isAvailable] returns false and methods are no-ops.
class LidarService extends ChangeNotifier {
  static const _channel = MethodChannel('com.kosmos3d/lidar');

  bool _isAvailable = false;
  bool _isCapturing = false;
  int _depthFrameCount = 0;
  String? _lastDepthPath;

  bool get isAvailable => _isAvailable;
  bool get isCapturing => _isCapturing;
  int get depthFrameCount => _depthFrameCount;
  String? get lastDepthPath => _lastDepthPath;

  /// Check if device has LiDAR hardware
  Future<void> checkAvailability() async {
    if (!_isIOSPlatform) {
      _isAvailable = false;
      notifyListeners();
      return;
    }
    try {
      _isAvailable = await _channel.invokeMethod<bool>('checkLidarAvailable') ?? false;
    } catch (e) {
      debugPrint('LiDAR check error: $e');
      _isAvailable = false;
    }
    notifyListeners();
  }

  /// Start capturing depth frames alongside photo captures
  Future<void> startCapture({String? outputDir}) async {
    if (!_isAvailable || _isCapturing) return;
    try {
      await _channel.invokeMethod('startDepthCapture', {'outputDir': outputDir});
      _isCapturing = true;
      _depthFrameCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('LiDAR start error: $e');
    }
  }

  /// Capture a single depth frame (call at each photo trigger)
  Future<String?> captureDepthFrame(int index) async {
    if (!_isAvailable || !_isCapturing) return null;
    try {
      final path = await _channel.invokeMethod<String>('captureDepthFrame', {'index': index});
      _depthFrameCount++;
      _lastDepthPath = path;
      notifyListeners();
      return path;
    } catch (e) {
      debugPrint('LiDAR capture error: $e');
      return null;
    }
  }

  /// Stop depth capture session
  Future<void> stopCapture() async {
    if (!_isCapturing) return;
    try {
      await _channel.invokeMethod('stopDepthCapture');
    } catch (e) {
      debugPrint('LiDAR stop error: $e');
    }
    _isCapturing = false;
    notifyListeners();
  }

  /// Export point cloud from captured depth data
  Future<String?> exportPointCloud({String format = 'ply'}) async {
    if (!_isAvailable) return null;
    try {
      return await _channel.invokeMethod<String>('exportPointCloud', {'format': format});
    } catch (e) {
      debugPrint('Point cloud export error: $e');
      return null;
    }
  }

  bool get _isIOSPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    stopCapture();
    super.dispose();
  }
}
