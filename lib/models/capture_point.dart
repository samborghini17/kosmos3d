/// Data point for a single capture event in 3D spatial scanning.
class CapturePoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final double heading; // compass heading in degrees (0 = North)
  final double pitch; // device tilt up/down (radians or degrees)
  final double roll; // device roll left/right
  final DateTime timestamp;

  CapturePoint({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    required this.heading,
    this.pitch = 0.0,
    this.roll = 0.0,
    required this.timestamp,
  });
}
