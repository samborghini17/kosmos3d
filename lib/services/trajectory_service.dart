import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

/// Records ALL phone sensor data (accelerometer, gyroscope, magnetometer,
/// barometer, GPS + speed + accuracy) during a capture session.
/// Compatible with iPhone 12 (all sensors) and Android devices.
/// Exports in JSON, CSV, and COLMAP-compatible transforms.json format.
class TrajectoryService extends ChangeNotifier {
  final List<TrajectoryPoint> _points = [];
  bool _isRecording = false;
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magSub;
  StreamSubscription? _baroSub;
  Timer? _gpsPollTimer;

  // Current sensor values
  double _ax = 0, _ay = 0, _az = 0; // accelerometer (m/s²)
  double _gx = 0, _gy = 0, _gz = 0; // gyroscope (rad/s)
  double _mx = 0, _my = 0, _mz = 0; // magnetometer (µT)
  double _pressure = 0;               // barometer (hPa)
  double _lat = 0, _lon = 0, _alt = 0; // GPS
  double _speed = 0;                   // GPS speed (m/s)
  double _accuracy = 0;                // GPS accuracy (meters)
  double _heading = 0;                 // GPS heading (degrees)

  int _sensorRateMs = 50;
  int _gpsRateSec = 2;
  bool _recordBarometer = true;

  List<TrajectoryPoint> get points => List.unmodifiable(_points);
  bool get isRecording => _isRecording;
  double get currentSpeed => _speed;
  double get currentAccuracy => _accuracy;

  void configure({int? sensorRateMs, int? gpsRateSec, bool? recordBarometer}) {
    if (sensorRateMs != null) _sensorRateMs = sensorRateMs;
    if (gpsRateSec != null) _gpsRateSec = gpsRateSec;
    if (recordBarometer != null) _recordBarometer = recordBarometer;
  }

  void startRecording() {
    if (_isRecording) return;
    _isRecording = true;
    _points.clear();

    final sensorDuration = Duration(milliseconds: _sensorRateMs);

    // Accelerometer — available on all devices
    _accelSub = accelerometerEventStream(
      samplingPeriod: sensorDuration,
    ).listen((event) {
      _ax = event.x; _ay = event.y; _az = event.z;
    });

    // Gyroscope — available on iPhone 12 and most Android
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: sensorDuration,
    ).listen((event) {
      _gx = event.x; _gy = event.y; _gz = event.z;
    });

    // Magnetometer — available on iPhone 12 and most Android
    _magSub = magnetometerEventStream(
      samplingPeriod: sensorDuration,
    ).listen((event) {
      _mx = event.x; _my = event.y; _mz = event.z;
    });

    // Barometer — available on iPhone 12, some Android
    if (_recordBarometer) {
      _baroSub = barometerEventStream(
        samplingPeriod: sensorDuration,
      ).listen((event) {
        _pressure = event.pressure;
      });
    }

    // GPS poll — high accuracy mode for best GS data
    _gpsPollTimer = Timer.periodic(Duration(seconds: _gpsRateSec), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
        );
        _lat = pos.latitude;
        _lon = pos.longitude;
        _alt = pos.altitude;
        _speed = pos.speed;
        _accuracy = pos.accuracy;
        _heading = pos.heading;
      } catch (_) {}
    });

    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _baroSub?.cancel();
    _gpsPollTimer?.cancel();
    notifyListeners();
  }

  /// Record a snapshot of all sensor data at the moment of a capture trigger.
  void recordCapturePoint(int captureIndex) {
    final compassHeading = atan2(_my, _mx) * (180 / pi);

    _points.add(TrajectoryPoint(
      index: captureIndex,
      timestamp: DateTime.now(),
      latitude: _lat,
      longitude: _lon,
      altitude: _alt,
      heading: compassHeading < 0 ? compassHeading + 360 : compassHeading,
      gpsHeading: _heading,
      speed: _speed,
      accuracy: _accuracy,
      pressure: _pressure,
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
      'version': '2.0',
      'point_count': data.length,
      'sensor_rate_ms': _sensorRateMs,
      'gps_rate_sec': _gpsRateSec,
      'barometer_enabled': _recordBarometer,
      'points': data,
    });
  }

  /// Export as CSV for spreadsheet / COLMAP import
  String exportAsCsv() {
    final buf = StringBuffer();
    buf.writeln('index,timestamp,lat,lon,alt,heading,gps_heading,speed_ms,accuracy_m,pressure_hpa,ax,ay,az,gx,gy,gz,mx,my,mz');
    for (final p in _points) {
      buf.writeln(
        '${p.index},${p.timestamp.toIso8601String()},'
        '${p.latitude},${p.longitude},${p.altitude},${p.heading.toStringAsFixed(1)},'
        '${p.gpsHeading.toStringAsFixed(1)},${p.speed.toStringAsFixed(2)},${p.accuracy.toStringAsFixed(1)},'
        '${p.pressure.toStringAsFixed(1)},'
        '${p.accelX.toStringAsFixed(4)},${p.accelY.toStringAsFixed(4)},${p.accelZ.toStringAsFixed(4)},'
        '${p.gyroX.toStringAsFixed(4)},${p.gyroY.toStringAsFixed(4)},${p.gyroZ.toStringAsFixed(4)},'
        '${p.magX.toStringAsFixed(4)},${p.magY.toStringAsFixed(4)},${p.magZ.toStringAsFixed(4)}'
      );
    }
    return buf.toString();
  }

  /// Export as transforms.json format (NeRF / 3D Gaussian Splatting compatible)
  String exportAsTransformsJson({double focalLength = 3200, int width = 3840, int height = 2160}) {
    final frames = <Map<String, dynamic>>[];
    for (final p in _points) {
      final rad = p.heading * pi / 180;
      // Simple rotation matrix from heading (yaw only for now)
      final transform = [
        [cos(rad), 0, sin(rad), p.longitude * 111320],
        [0, 1, 0, p.altitude],
        [-sin(rad), 0, cos(rad), p.latitude * 110540],
        [0, 0, 0, 1],
      ];
      frames.add({
        'file_path': 'images/capture_${p.index.toString().padLeft(4, '0')}.jpg',
        'transform_matrix': transform,
      });
    }
    return const JsonEncoder.withIndent('  ').convert({
      'camera_angle_x': 2 * atan(width / (2 * focalLength)),
      'camera_angle_y': 2 * atan(height / (2 * focalLength)),
      'fl_x': focalLength,
      'fl_y': focalLength,
      'cx': width / 2.0,
      'cy': height / 2.0,
      'w': width,
      'h': height,
      'frames': frames,
    });
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
  final double heading, gpsHeading;
  final double speed, accuracy;
  final double pressure;
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
    required this.gpsHeading,
    required this.speed,
    required this.accuracy,
    required this.pressure,
    required this.accelX, required this.accelY, required this.accelZ,
    required this.gyroX, required this.gyroY, required this.gyroZ,
    required this.magX, required this.magY, required this.magZ,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'timestamp': timestamp.toIso8601String(),
    'gps': {'lat': latitude, 'lon': longitude, 'alt': altitude, 'heading': gpsHeading,
            'speed_ms': speed, 'accuracy_m': accuracy},
    'compass_heading': heading,
    'barometer': {'pressure_hpa': pressure},
    'accelerometer': {'x': accelX, 'y': accelY, 'z': accelZ},
    'gyroscope': {'x': gyroX, 'y': gyroY, 'z': gyroZ},
    'magnetometer': {'x': magX, 'y': magY, 'z': magZ},
  };
}
