import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

/// Records phone IMU data (accelerometer, gyroscope, magnetometer, GPS)
/// during a capture session for camera trajectory estimation.
/// Exports in formats compatible with COLMAP, Reality Capture, and Lichtfeld Studio.
class TrajectoryService extends ChangeNotifier {
  final List<TrajectoryPoint> _points = [];
  bool _isRecording = false;
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magSub;
  Timer? _gpsPollTimer;

  // Current sensor values
  double _ax = 0, _ay = 0, _az = 0; // accelerometer
  double _gx = 0, _gy = 0, _gz = 0; // gyroscope
  double _mx = 0, _my = 0, _mz = 0; // magnetometer
  double _lat = 0, _lon = 0, _alt = 0; // GPS

  List<TrajectoryPoint> get points => List.unmodifiable(_points);
  bool get isRecording => _isRecording;

  void startRecording() {
    if (_isRecording) return;
    _isRecording = true;
    _points.clear();

    // Accelerometer
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((event) {
      _ax = event.x;
      _ay = event.y;
      _az = event.z;
    });

    // Gyroscope
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((event) {
      _gx = event.x;
      _gy = event.y;
      _gz = event.z;
    });

    // Magnetometer
    _magSub = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((event) {
      _mx = event.x;
      _my = event.y;
      _mz = event.z;
    });

    // GPS poll every 2 seconds
    _gpsPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        _lat = pos.latitude;
        _lon = pos.longitude;
        _alt = pos.altitude;
      } catch (_) {}
    });

    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _gpsPollTimer?.cancel();
    notifyListeners();
  }

  /// Record a snapshot of all sensor data at the moment of a capture trigger.
  void recordCapturePoint(int captureIndex) {
    final heading = atan2(_my, _mx) * (180 / pi);

    _points.add(TrajectoryPoint(
      index: captureIndex,
      timestamp: DateTime.now(),
      latitude: _lat,
      longitude: _lon,
      altitude: _alt,
      heading: heading < 0 ? heading + 360 : heading,
      accelX: _ax, accelY: _ay, accelZ: _az,
      gyroX: _gx, gyroY: _gy, gyroZ: _gz,
      magX: _mx, magY: _my, magZ: _mz,
    ));
    notifyListeners();
  }

  /// Export trajectory as JSON (compatible with custom pipelines)
  String exportAsJson() {
    final data = _points.map((p) => p.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'kosmos3d_trajectory',
      'version': '1.0',
      'point_count': data.length,
      'points': data,
    });
  }

  /// Export as CSV for spreadsheet / COLMAP import
  String exportAsCsv() {
    final buf = StringBuffer();
    buf.writeln('index,timestamp,lat,lon,alt,heading,ax,ay,az,gx,gy,gz,mx,my,mz');
    for (final p in _points) {
      buf.writeln(
        '${p.index},${p.timestamp.toIso8601String()},'
        '${p.latitude},${p.longitude},${p.altitude},${p.heading.toStringAsFixed(1)},'
        '${p.accelX.toStringAsFixed(4)},${p.accelY.toStringAsFixed(4)},${p.accelZ.toStringAsFixed(4)},'
        '${p.gyroX.toStringAsFixed(4)},${p.gyroY.toStringAsFixed(4)},${p.gyroZ.toStringAsFixed(4)},'
        '${p.magX.toStringAsFixed(4)},${p.magY.toStringAsFixed(4)},${p.magZ.toStringAsFixed(4)}'
      );
    }
    return buf.toString();
  }

  @override
  void dispose() {
    stopRecording();
    super.dispose();
  }
}

class TrajectoryPoint {
  final int index;
  final DateTime timestamp;
  final double latitude, longitude, altitude;
  final double heading;
  final double accelX, accelY, accelZ;
  final double gyroX, gyroY, gyroZ;
  final double magX, magY, magZ;

  TrajectoryPoint({
    required this.index,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.heading,
    required this.accelX, required this.accelY, required this.accelZ,
    required this.gyroX, required this.gyroY, required this.gyroZ,
    required this.magX, required this.magY, required this.magZ,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'timestamp': timestamp.toIso8601String(),
    'gps': {'lat': latitude, 'lon': longitude, 'alt': altitude},
    'heading': heading,
    'accelerometer': {'x': accelX, 'y': accelY, 'z': accelZ},
    'gyroscope': {'x': gyroX, 'y': gyroY, 'z': gyroZ},
    'magnetometer': {'x': magX, 'y': magY, 'z': magZ},
  };
}
