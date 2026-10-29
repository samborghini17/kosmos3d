import '../l10n/app_text.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/trajectory_service.dart';
import '../providers/settings_provider.dart';

/// Interactive 3D trajectory preview using projected custom painting.
/// Renders capture positions, camera frustums, and directional path.
class PointCloudPreviewScreen extends StatefulWidget {
  const PointCloudPreviewScreen({super.key});

  @override
  State<PointCloudPreviewScreen> createState() =>
      _PointCloudPreviewScreenState();
}

class _PointCloudPreviewScreenState extends State<PointCloudPreviewScreen> {
  double _rotX = 0.35; // Pitch (radians)
  double _rotY = 0.0; // Yaw (radians)
  double _zoom = 1.0;
  Offset _pan = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final trajectory = context.watch<TrajectoryService>();
    final settings = context.watch<SettingsProvider>();
    final points = trajectory.points
        .where((p) => p.gpsTimestamp != null)
        .toList();
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      appBar: AppBar(
        title: AppText(settings.translate('trajectory_preview')),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset View',
            onPressed: () => setState(() {
              _rotX = 0.35;
              _rotY = 0.0;
              _zoom = 1.0;
              _pan = Offset.zero;
            }),
          ),
        ],
      ),
      body: points.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_in_ar,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    settings.translate('no_trajectory'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'Record a capture session to see the 3D preview',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Stats bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: Colors.white.withValues(alpha: 0.03),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(Icons.location_on, '${points.length}', 'Points'),
                      _stat(
                        Icons.straighten,
                        _calcPathLength(points),
                        'Distance',
                      ),
                      _stat(Icons.schedule, _calcDuration(points), 'Duration'),
                    ],
                  ),
                ),
                // 3D viewport
                Expanded(
                  child: GestureDetector(
                    onScaleStart: (_) {},
                    onScaleUpdate: (details) {
                      setState(() {
                        if (details.pointerCount == 1) {
                          _rotY += details.focalPointDelta.dx * 0.008;
                          _rotX += details.focalPointDelta.dy * 0.008;
                          _rotX = _rotX.clamp(-pi / 2, pi / 2);
                        } else {
                          _zoom = (_zoom * details.scale).clamp(0.3, 5.0);
                          _pan += details.focalPointDelta;
                        }
                      });
                    },
                    child: CustomPaint(
                      painter: Trajectory3DPainter(
                        points: points,
                        rotX: _rotX,
                        rotY: _rotY,
                        zoom: _zoom,
                        pan: _pan,
                        primaryColor: primaryColor,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                // Controls hint
                Container(
                  padding: const EdgeInsets.all(12),
                  child: AppText(
                    'Approximate GPS / phone attitude; not reconstructed surface coverage. Drag to rotate; pinch to zoom.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(height: 2),
        AppText(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        AppText(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _calcPathLength(List<TrajectoryPoint> points) {
    if (points.length < 2) return '0m';
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      final dx = points[i].latitude - points[i - 1].latitude;
      final dy = points[i].longitude - points[i - 1].longitude;
      final longitudeScale = cos(points[i].latitude * pi / 180);
      total +=
          sqrt(dx * dx + dy * dy * longitudeScale * longitudeScale) *
          111320; // Approx meters per degree
    }
    if (total > 1000) return '${(total / 1000).toStringAsFixed(1)}km';
    return '${total.toStringAsFixed(0)}m';
  }

  String _calcDuration(List<TrajectoryPoint> points) {
    if (points.length < 2) return '0s';
    final dur = points.last.timestamp.difference(points.first.timestamp);
    if (dur.inMinutes > 0) return '${dur.inMinutes}m ${dur.inSeconds % 60}s';
    return '${dur.inSeconds}s';
  }
}

/// 3D painter that projects trajectory points with rotation and zoom
class Trajectory3DPainter extends CustomPainter {
  final List<TrajectoryPoint> points;
  final double rotX, rotY, zoom;
  final Offset pan;
  final Color primaryColor;

  Trajectory3DPainter({
    required this.points,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.pan,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final center = Offset(size.width / 2 + pan.dx, size.height / 2 + pan.dy);

    // Normalize points to fit viewport
    double minLat = double.infinity, maxLat = -double.infinity;
    double minLon = double.infinity, maxLon = -double.infinity;
    double minAlt = double.infinity, maxAlt = -double.infinity;

    for (final p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLon = min(minLon, p.longitude);
      maxLon = max(maxLon, p.longitude);
      minAlt = min(minAlt, p.altitude);
      maxAlt = max(maxAlt, p.altitude);
    }

    final longitudeScale = cos(
      (minLat + maxLat) * pi / 360,
    ).abs().clamp(0.001, 1.0);
    final span = max(
      1.0,
      max(
        (maxLat - minLat) * 111320,
        max((maxLon - minLon) * 111320 * longitudeScale, maxAlt - minAlt),
      ),
    );
    final scale = min(size.width, size.height) * 0.35 * zoom;
    final midLat = (minLat + maxLat) / 2;
    final midLon = (minLon + maxLon) / 2;
    final midAlt = (minAlt + maxAlt) / 2;

    // 3D rotation matrix application
    Offset project(double x, double y, double z) {
      // Apply Y rotation (yaw)
      final cosY = cos(rotY), sinY = sin(rotY);
      final rx = x * cosY - z * sinY;
      final rz = x * sinY + z * cosY;
      // Apply X rotation (pitch)
      final cosX = cos(rotX), sinX = sin(rotX);
      final ry = y * cosX - rz * sinX;
      final rz2 = y * sinX + rz * cosX;
      // Simple perspective
      final perspective = 1.0 + rz2 * 0.001;
      return Offset(
        center.dx + rx * scale / perspective,
        center.dy - ry * scale / perspective,
      );
    }

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (int i = -5; i <= 5; i++) {
      final f = i / 5.0;
      final p1 = project(f, 0, -1);
      final p2 = project(f, 0, 1);
      canvas.drawLine(p1, p2, gridPaint);
      final p3 = project(-1, 0, f);
      final p4 = project(1, 0, f);
      canvas.drawLine(p3, p4, gridPaint);
    }

    // Draw axis indicators
    final axisLen = 0.15;
    // X axis (red)
    canvas.drawLine(
      project(0, 0, 0),
      project(axisLen, 0, 0),
      Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
    // Y axis (green)
    canvas.drawLine(
      project(0, 0, 0),
      project(0, axisLen, 0),
      Paint()
        ..color = Colors.greenAccent.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
    // Z axis (blue)
    canvas.drawLine(
      project(0, 0, 0),
      project(0, 0, axisLen),
      Paint()
        ..color = Colors.blueAccent.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );

    // Plot trajectory path and points
    final projected = <Offset>[];
    for (final p in points) {
      final nx = (p.latitude - midLat) * 111320 / span;
      final ny = (p.altitude - midAlt) / span;
      final nz = (p.longitude - midLon) * 111320 * longitudeScale / span;
      projected.add(project(nx, ny, nz));
    }

    // Draw connecting lines
    final pathPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 1; i < projected.length; i++) {
      canvas.drawLine(projected[i - 1], projected[i], pathPaint);
    }

    // Draw camera frustums and points
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final pos = projected[i];
      final t = points.length > 1 ? i / (points.length - 1) : 0.5;

      // Color gradient from green (start) to primary (end)
      final color = Color.lerp(Colors.greenAccent, primaryColor, t)!;

      // Draw point
      canvas.drawCircle(pos, 4 * zoom.clamp(0.5, 2.0), Paint()..color = color);
      canvas.drawCircle(
        pos,
        6 * zoom.clamp(0.5, 2.0),
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // Draw mini frustum (camera direction indicator)
      final headingRad = p.heading * pi / 180;
      final nx = (p.latitude - midLat) * 111320 / span;
      final ny = (p.altitude - midAlt) / span;
      final nz = (p.longitude - midLon) * 111320 * longitudeScale / span;
      const length = 0.08;
      final pitch = p.pitch * pi / 180, roll = p.roll * pi / 180;
      final forward = [
        cos(pitch) * cos(headingRad),
        sin(pitch),
        cos(pitch) * sin(headingRad),
      ];
      final right = [-sin(headingRad), 0.0, cos(headingRad)];
      final up = [
        -sin(pitch) * cos(headingRad),
        cos(pitch),
        -sin(pitch) * sin(headingRad),
      ];
      final corners = <Offset>[];
      for (final sign in [
        [-1, -1],
        [1, -1],
        [1, 1],
        [-1, 1],
      ]) {
        final offset = List.generate(
          3,
          (j) =>
              forward[j] * length +
              sign[0] *
                  length *
                  0.4 *
                  (right[j] * cos(roll) + up[j] * sin(roll)) +
              sign[1] *
                  length *
                  0.3 *
                  (-right[j] * sin(roll) + up[j] * cos(roll)),
        );
        corners.add(project(nx + offset[0], ny + offset[1], nz + offset[2]));
      }
      final frustumPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      for (var j = 0; j < 4; j++) {
        canvas.drawLine(pos, corners[j], frustumPaint);
        canvas.drawLine(corners[j], corners[(j + 1) % 4], frustumPaint);
      }
    }

    // Draw start/end labels
    if (projected.isNotEmpty) {
      _drawLabel(
        canvas,
        'START',
        projected.first + const Offset(8, -8),
        Colors.greenAccent,
      );
      if (projected.length > 1) {
        _drawLabel(
          canvas,
          'END',
          projected.last + const Offset(8, -8),
          primaryColor,
        );
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant Trajectory3DPainter old) => true;
}
