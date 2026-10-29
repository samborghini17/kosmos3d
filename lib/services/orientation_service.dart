import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 3D Attitude and Sensor Fusion Service.
/// Specifically calibrated for phones held standing upright in portrait mode on scanner rigs.
/// Computes tilt-compensated 3D heading, pitch, roll, and 6-DOF quaternions for Gaussian Splatting.
class OrientationService extends ChangeNotifier {
  StreamSubscription? _accelSub;
  StreamSubscription? _magSub;

  // Raw sensor values
  double _ax = 0, _ay = -9.8, _az = 0; // Accelerometer (m/s²)
  double _mx = 0, _my = 0, _mz = -30; // Magnetometer (µT)

  // Filtered attitude
  double _heading = 0.0; // 0°–360° (Yaw in World East-North plane)
  double _pitch = 0.0; // -90° to +90° (Camera optical axis elevation)
  double _roll = 0.0; // -180° to +180° (Camera tilt around optical axis)

  // 6-DOF Quaternion (w, x, y, z) for Gaussian Splatting / COLMAP
  List<double> _quaternion = [1.0, 0.0, 0.0, 0.0];

  // Camera forward unit vector in World Coordinates [East, North, Up]
  List<double> _cameraForwardWorld = [0.0, 1.0, 0.0];

  bool _isRunning = false;
  bool _hasAccel = false, _hasMag = false;
  DateTime? sampleTime;
  bool get hasSample => _hasAccel && _hasMag && sampleTime != null;

  // Getters
  double get heading => _heading;
  double get pitch => _pitch;
  double get roll => _roll;
  List<double> get quaternion => List.unmodifiable(_quaternion);
  List<double> get cameraForwardWorld => List.unmodifiable(_cameraForwardWorld);
  bool get isRunning => _isRunning;

  /// Start streaming and fusing sensor data
  void start({int updateRateMs = 30}) {
    if (_isRunning) return;
    _isRunning = true;
    final samplePeriod = Duration(milliseconds: updateRateMs);

    _accelSub = accelerometerEventStream(samplingPeriod: samplePeriod).listen(
      (e) {
        _hasAccel = true;
        // Low-pass filter on accelerometer
        const alpha = 0.25;
        _ax = _ax * (1 - alpha) + e.x * alpha;
        _ay = _ay * (1 - alpha) + e.y * alpha;
        _az = _az * (1 - alpha) + e.z * alpha;
        _computeOrientation();
      },
      onError: (Object e) {
        debugPrint('Orientation sensor unavailable: $e');
      },
    );

    _magSub = magnetometerEventStream(samplingPeriod: samplePeriod).listen(
      (e) {
        _hasMag = true;
        // Low-pass filter on magnetometer
        const alpha = 0.2;
        _mx = _mx * (1 - alpha) + e.x * alpha;
        _my = _my * (1 - alpha) + e.y * alpha;
        _mz = _mz * (1 - alpha) + e.z * alpha;
        _computeOrientation();
      },
      onError: (Object e) {
        debugPrint('Orientation sensor unavailable: $e');
      },
    );
  }

  /// Stop sensor streaming
  void stop() {
    _isRunning = false;
    _accelSub?.cancel();
    _magSub?.cancel();
  }

  /// 3D Tilt-Compensated Sensor Fusion:
  /// Handles upright portrait phone, tilted handheld scanning, and arbitrary gimbal mounts.
  void _computeOrientation() {
    if (!_hasAccel || !_hasMag) return;
    final aNorm = sqrt(_ax * _ax + _ay * _ay + _az * _az);
    if (aNorm < 0.1) return;

    // 1. World Vertical UP vector in device coordinate system
    // Accelerometer includes support acceleration: stationary reading points UP.
    final upX = _ax / aNorm;
    final upY = _ay / aNorm;
    final upZ = _az / aNorm;

    // 2. World EAST vector in device coordinate system
    // East = Magnetometer (M) x Up (normalized)
    double eX = _my * upZ - _mz * upY;
    double eY = _mz * upX - _mx * upZ;
    double eZ = _mx * upY - _my * upX;
    final eNorm = sqrt(eX * eX + eY * eY + eZ * eZ);
    if (eNorm < 0.001) return;
    eX /= eNorm;
    eY /= eNorm;
    eZ /= eNorm;

    // 3. World NORTH vector in device coordinate system
    // North = Up x East
    final nX = upY * eZ - upZ * eY;
    final nY = upZ * eX - upX * eZ;
    final nZ = upX * eY - upY * eX;

    // 4. Scanner / Back-Camera View Direction in Device Frame
    // In Android/iOS device coordinates:
    // +X = Right, +Y = Top of phone (Up when standing), +Z = Out of screen (towards user), -Z = Back Camera
    const camX = 0.0;
    const camY = 0.0;
    const camZ = -1.0; // Back camera optical axis pointing into the scene

    // 5. Project Camera Optical Axis into World Frame [East, North, Up]
    final worldEast = camX * eX + camY * eY + camZ * eZ; // = -eZ
    final worldNorth = camX * nX + camY * nY + camZ * nZ; // = -nZ
    final worldUp = camX * upX + camY * upY + camZ * upZ; // = -upZ

    _cameraForwardWorld = [worldEast, worldNorth, worldUp];

    // 6. Camera Azimuth / Heading (Yaw) in Horizontal World Plane (0° = North, 90° = East, 180° = South, 270° = West)
    double rawHeading = atan2(worldEast, worldNorth) * (180.0 / pi);
    if (rawHeading < 0) rawHeading += 360.0;

    // Smooth heading using shortest angular distance
    double diff = (rawHeading - _heading + 540.0) % 360.0 - 180.0;
    _heading = (_heading + diff * 0.35 + 360.0) % 360.0;

    // 7. Camera Optical Axis Pitch (Elevation angle: -90° looking down, 0° horizontal, +90° looking up)
    final rawPitch = asin(worldUp.clamp(-1.0, 1.0)) * (180.0 / pi);
    _pitch = _pitch * 0.7 + rawPitch * 0.3;

    // 8. Camera Roll (Tilt around optical axis: -180° to +180°)
    // Derived from device right vector projection
    final rawRoll = atan2(_ax, _ay) * (180.0 / pi);
    _roll = _roll * 0.7 + rawRoll * 0.3;

    // 9. Compute 3D Rotation Quaternion from Direction Cosine Matrix (DCM)
    // World axes are rows of device-to-ENU; pass column-major arguments.
    _computeQuaternion(eX, nX, upX, eY, nY, upY, eZ, nZ, upZ);
    sampleTime = DateTime.now().toUtc();

    notifyListeners();
  }

  /// Converts 3x3 rotation matrix to unit quaternion [w, x, y, z]
  void _computeQuaternion(
    double r00,
    double r10,
    double r20,
    double r01,
    double r11,
    double r21,
    double r02,
    double r12,
    double r22,
  ) {
    final tr = r00 + r11 + r22;
    double w, x, y, z;

    if (tr > 0) {
      final s = sqrt(tr + 1.0) * 2;
      w = 0.25 * s;
      x = (r21 - r12) / s;
      y = (r02 - r20) / s;
      z = (r10 - r01) / s;
    } else if ((r00 > r11) && (r00 > r22)) {
      final s = sqrt(1.0 + r00 - r11 - r22) * 2;
      w = (r21 - r12) / s;
      x = 0.25 * s;
      y = (r01 + r10) / s;
      z = (r02 + r20) / s;
    } else if (r11 > r22) {
      final s = sqrt(1.0 + r11 - r00 - r22) * 2;
      w = (r02 - r20) / s;
      x = (r01 + r10) / s;
      y = 0.25 * s;
      z = (r12 + r21) / s;
    } else {
      final s = sqrt(1.0 + r22 - r00 - r11) * 2;
      w = (r10 - r01) / s;
      x = (r02 + r20) / s;
      y = (r12 + r21) / s;
      z = 0.25 * s;
    }

    final qNorm = sqrt(w * w + x * x + y * y + z * z);
    if (qNorm > 0) {
      _quaternion = [w / qNorm, x / qNorm, y / qNorm, z / qNorm];
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
