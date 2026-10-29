import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
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
  StreamSubscription<Position>? _gpsSub;
  DateTime? _gpsTimestamp;
  Position? latestPosition;
  final Map<String, String> sensorAvailability = {};
  final Map<String, DateTime> _sensorTimes = {};
  IOSink? _rawSink;
  Timer? _rawTimer;
  final Stopwatch _clock = Stopwatch();
  void _seen(String sensor) {
    _sensorTimes[sensor] = DateTime.now().toUtc();
    if (sensorAvailability[sensor] != 'available') {
      sensorAvailability[sensor] = 'available';
      notifyListeners();
    }
  }

  // Current sensor values
  double _ax = 0, _ay = 0, _az = 0; // accelerometer (m/s²)
  double _gx = 0, _gy = 0, _gz = 0; // gyroscope (rad/s)
  double _mx = 0, _my = 0, _mz = 0; // magnetometer (µT)
  double _pressure = 0; // barometer (hPa)
  double _lat = 0, _lon = 0, _alt = 0; // GPS
  double _speed = 0; // GPS speed (m/s)
  double _accuracy = 0; // GPS accuracy (meters)
  double _heading = 0; // GPS heading (degrees)

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

  Future<void> startRecording({String? outputDirectory}) async {
    if (_isRecording) return;
    _isRecording = true;
    _points.clear();
    _gpsTimestamp = null;
    latestPosition = null;
    _sensorTimes.clear();
    sensorAvailability.clear();
    _clock.reset();
    _clock.start();
    if (outputDirectory != null) {
      await Directory(outputDirectory).create(recursive: true);
      _rawSink = File(
        '$outputDirectory/sensors_${DateTime.now().toUtc().microsecondsSinceEpoch}.jsonl',
      ).openWrite();
      _rawTimer = Timer.periodic(Duration(milliseconds: _sensorRateMs), (_) {
        if (!_isRecording) return;
        _rawSink?.writeln(
          jsonEncode({
            'utc': DateTime.now().toUtc().toIso8601String(),
            'monotonicUs': _clock.elapsedMicroseconds,
            'sampleUtc': _sensorTimes.map(
              (key, value) => MapEntry(key, value.toIso8601String()),
            ),
            'accelerometer': _sensorTimes.containsKey('accelerometer')
                ? [_ax, _ay, _az]
                : null,
            'gyroscope': _sensorTimes.containsKey('gyroscope')
                ? [_gx, _gy, _gz]
                : null,
            'magnetometer': _sensorTimes.containsKey('magnetometer')
                ? [_mx, _my, _mz]
                : null,
            'pressureHpa': _sensorTimes.containsKey('barometer')
                ? _pressure
                : null,
            'gps': latestPosition?.toJson(),
            'status': sensorAvailability,
          }),
        );
      });
    }

    final sensorDuration = Duration(milliseconds: _sensorRateMs);

    // Accelerometer — available on all devices
    _accelSub = accelerometerEventStream(samplingPeriod: sensorDuration).listen(
      (event) {
        _seen('accelerometer');
        _ax = event.x;
        _ay = event.y;
        _az = event.z;
      },
      onError: (Object e) {
        sensorAvailability['accelerometer'] = 'unavailable';
        debugPrint('Accelerometer unavailable: $e');
      },
    );

    // Gyroscope — available on iPhone 12 and most Android
    _gyroSub = gyroscopeEventStream(samplingPeriod: sensorDuration).listen(
      (event) {
        _seen('gyroscope');
        _gx = event.x;
        _gy = event.y;
        _gz = event.z;
      },
      onError: (Object e) {
        debugPrint('Gyroscope unavailable: $e');
        sensorAvailability['gyroscope'] = 'unavailable';
      },
    );

    // Magnetometer — available on iPhone 12 and most Android
    _magSub = magnetometerEventStream(samplingPeriod: sensorDuration).listen(
      (event) {
        _seen('magnetometer');
        _mx = event.x;
        _my = event.y;
        _mz = event.z;
      },
      onError: (Object e) {
        debugPrint('Magnetometer unavailable: $e');
        sensorAvailability['magnetometer'] = 'unavailable';
      },
    );

    // Barometer — available on iPhone 12, some Android
    if (_recordBarometer) {
      _baroSub = barometerEventStream(samplingPeriod: sensorDuration).listen(
        (event) {
          _seen('barometer');
          _pressure = event.pressure;
        },
        onError: (Object e) {
          debugPrint('Barometer unavailable: $e');
          sensorAvailability['barometer'] = 'unavailable';
        },
      );
    }

    _gpsSub =
        Geolocator.getPositionStream(
          locationSettings: Platform.isAndroid
              ? AndroidSettings(
                  accuracy: LocationAccuracy.bestForNavigation,
                  intervalDuration: Duration(seconds: _gpsRateSec),
                )
              : const LocationSettings(
                  accuracy: LocationAccuracy.bestForNavigation,
                ),
        ).listen(
          (pos) {
            _seen('gps');
            latestPosition = pos;
            _lat = pos.latitude;
            _lon = pos.longitude;
            _alt = pos.altitude;
            _speed = pos.speed;
            _accuracy = pos.accuracy;
            _heading = pos.heading;
            _gpsTimestamp = pos.timestamp;
          },
          onError: (Object e) {
            debugPrint('Location unavailable: $e');
            sensorAvailability['gps'] = 'unavailable or permission denied';
          },
        );

    notifyListeners();
  }

  Future<void> stopRecording() async {
    _isRecording = false;
    _rawTimer?.cancel();
    _clock.stop();
    final sink = _rawSink;
    _rawSink = null;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _baroSub?.cancel();
    _gpsSub?.cancel();
    notifyListeners();
    await sink?.flush();
    await sink?.close();
  }

  /// Record a snapshot of all sensor data at the moment of a capture trigger.
  void recordCapturePoint(
    int captureIndex, {
    DateTime? timestamp,
    double? heading,
    double? pitch,
    double? roll,
    List<double>? quaternion,
  }) {
    // 3D tilt-compensated attitude fallback if not passed directly from OrientationService
    double compHeading = heading ?? 0.0;
    double compPitch = pitch ?? 0.0;
    double compRoll = roll ?? 0.0;
    List<double> quat = quaternion ?? [1.0, 0.0, 0.0, 0.0];

    if (heading == null) {
      final aNorm = sqrt(_ax * _ax + _ay * _ay + _az * _az);
      if (aNorm > 0.1) {
        final upX = -_ax / aNorm, upY = -_ay / aNorm, upZ = -_az / aNorm;
        double eX = _my * upZ - _mz * upY;
        double eY = _mz * upX - _mx * upZ;
        double eZ = _mx * upY - _my * upX;
        final eNorm = sqrt(eX * eX + eY * eY + eZ * eZ);
        if (eNorm > 0.001) {
          eX /= eNorm;
          eY /= eNorm;
          eZ /= eNorm;
          final nZ = upX * eY - upY * eX;
          final worldEast = -eZ;
          final worldNorth = -nZ;
          compHeading = atan2(worldEast, worldNorth) * (180.0 / pi);
          if (compHeading < 0) compHeading += 360.0;
          compPitch = asin((-upZ).clamp(-1.0, 1.0)) * (180.0 / pi);
          compRoll = atan2(-_ax, -_ay) * (180.0 / pi);
        }
      }
    }

    _points.add(
      TrajectoryPoint(
        index: captureIndex,
        gpsTimestamp: _gpsTimestamp,
        timestamp: timestamp ?? DateTime.now().toUtc(),
        latitude: _lat,
        longitude: _lon,
        altitude: _alt,
        heading: compHeading,
        pitch: compPitch,
        roll: compRoll,
        quaternion: quat,
        gpsHeading: _heading,
        speed: _speed,
        accuracy: _accuracy,
        pressure: _pressure,
        accelX: _ax,
        accelY: _ay,
        accelZ: _az,
        gyroX: _gx,
        gyroY: _gy,
        gyroZ: _gz,
        magX: _mx,
        magY: _my,
        magZ: _mz,
      ),
    );
    notifyListeners();
  }

  /// Export trajectory as JSON (compatible with custom pipelines)
  String exportAsJson() {
    final data = _points.map((p) => p.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'kosmos3d_trajectory',
      'version': '4.0',
      'event_type': 'acknowledged_shutter_dispatch',
      'exposure_timestamp_verified': false,
      'pose_quality': 'phone_sensor_prior_not_slam',
      'quaternion_order': 'wxyz',
      'orientation_frame': 'device_to_ENU',
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
    buf.writeln(
      'index,timestamp,lat,lon,alt,heading,pitch,roll,qw,qx,qy,qz,gps_heading,speed_ms,accuracy_m,pressure_hpa,ax,ay,az,gx,gy,gz,mx,my,mz',
    );
    for (final p in _points) {
      final q = p.quaternion;
      buf.writeln(
        '${p.index},${p.timestamp.toIso8601String()},'
        '${p.latitude},${p.longitude},${p.altitude},'
        '${p.heading.toStringAsFixed(2)},${p.pitch.toStringAsFixed(2)},${p.roll.toStringAsFixed(2)},'
        '${q[0].toStringAsFixed(4)},${q[1].toStringAsFixed(4)},${q[2].toStringAsFixed(4)},${q[3].toStringAsFixed(4)},'
        '${p.gpsHeading.toStringAsFixed(1)},${p.speed.toStringAsFixed(2)},${p.accuracy.toStringAsFixed(1)},'
        '${p.pressure.toStringAsFixed(1)},'
        '${p.accelX.toStringAsFixed(4)},${p.accelY.toStringAsFixed(4)},${p.accelZ.toStringAsFixed(4)},'
        '${p.gyroX.toStringAsFixed(4)},${p.gyroY.toStringAsFixed(4)},${p.gyroZ.toStringAsFixed(4)},'
        '${p.magX.toStringAsFixed(4)},${p.magY.toStringAsFixed(4)},${p.magZ.toStringAsFixed(4)}',
      );
    }
    return buf.toString();
  }

  /// Sensor priors are not calibrated camera poses. Use ReconstructionManifest
  /// with real media paths, intrinsics and camera-to-world poses from SfM/VIO.
  String exportAsTransformsJson({
    double focalLength = 3200,
    int width = 3840,
    int height = 2160,
  }) {
    throw StateError(
      'Calibrated camera poses and matched media are required. Export trajectory JSON as sensor priors.',
    );
  }

  @override
  void dispose() {
    stopRecording();
    super.dispose();
  }
}

class TrajectoryPoint {
  final int index;
  final DateTime? gpsTimestamp;
  final DateTime timestamp;
  final double latitude, longitude, altitude;
  final double heading, pitch, roll;
  final List<double> quaternion;
  final double gpsHeading;
  final double speed, accuracy;
  final double pressure;
  final double accelX, accelY, accelZ;
  final double gyroX, gyroY, gyroZ;
  final double magX, magY, magZ;

  TrajectoryPoint({
    required this.index,
    this.gpsTimestamp,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.heading,
    this.pitch = 0.0,
    this.roll = 0.0,
    this.quaternion = const [1.0, 0.0, 0.0, 0.0],
    required this.gpsHeading,
    required this.speed,
    required this.accuracy,
    required this.pressure,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.magX,
    required this.magY,
    required this.magZ,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'timestamp': timestamp.toIso8601String(),
    'gps_valid': gpsTimestamp != null,
    'gps_sample_utc': gpsTimestamp?.toUtc().toIso8601String(),
    'gps': {
      'lat': gpsTimestamp == null ? null : latitude,
      'lon': gpsTimestamp == null ? null : longitude,
      'alt': gpsTimestamp == null ? null : altitude,
      'heading': gpsHeading,
      'speed_ms': speed,
      'accuracy_m': accuracy,
    },
    'attitude_6dof': {
      'heading': heading,
      'pitch': pitch,
      'roll': roll,
      'quaternion': quaternion,
    },
    'barometer': {'pressure_hpa': pressure},
    'accelerometer': {'x': accelX, 'y': accelY, 'z': accelZ},
    'gyroscope': {'x': gyroX, 'y': gyroY, 'z': gyroZ},
    'magnetometer': {'x': magX, 'y': magY, 'z': magZ},
  };
}
