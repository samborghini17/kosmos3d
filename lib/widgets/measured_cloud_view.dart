import '../l10n/app_text.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/lidar_service.dart';

/// Only real ARKit depth samples are accepted. No synthetic scene geometry.
class MeasuredCloudView extends StatefulWidget {
  const MeasuredCloudView({super.key});
  @override
  State<MeasuredCloudView> createState() => _MeasuredCloudViewState();
}

class _MeasuredCloudViewState extends State<MeasuredCloudView> {
  double yaw = 0, pitch = 0.4, zoom = 1, startZoom = 1;
  @override
  Widget build(BuildContext context) {
    final lidar = context.watch<LidarService>();
    return Stack(
      children: [
        GestureDetector(
          onScaleStart: (_) => startZoom = zoom,
          onScaleUpdate: (d) => setState(() {
            if (d.pointerCount == 1) {
              yaw += d.focalPointDelta.dx * 0.01;
              pitch = (pitch + d.focalPointDelta.dy * 0.01).clamp(-1.5, 1.5);
            } else {
              zoom = (startZoom * d.scale).clamp(0.25, 8);
            }
          }),
          onDoubleTap: () => setState(() {
            yaw = 0;
            pitch = 0.4;
            zoom = 1;
          }),
          child: CustomPaint(
            painter: _MeasuredPainter(lidar.points, yaw, pitch, zoom),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: 12,
          top: 8,
          right: 12,
          child: AppText(
            'Measured LiDAR · ${lidar.points.length} displayed points · ${lidar.tracking}\n'
            'Colour = height. Unseen surfaces and photo overlap are not measured.',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
        if (lidar.points.isEmpty)
          const Center(
            child: AppText(
              'Move slowly to collect depth',
              style: TextStyle(color: Colors.white70),
            ),
          ),
      ],
    );
  }
}

class _MeasuredPainter extends CustomPainter {
  final List<List<double>> points;
  final double yaw, pitch, zoom;
  _MeasuredPainter(this.points, this.yaw, this.pitch, this.zoom);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff101612),
    );
    if (points.isEmpty) return;
    final center = List<double>.generate(
      3,
      (i) => points.fold(0.0, (n, p) => n + p[i]) / points.length,
    );
    var radius = 0.5;
    for (final p in points) {
      radius = max(
        radius,
        sqrt(
          pow(p[0] - center[0], 2) +
              pow(p[1] - center[1], 2) +
              pow(p[2] - center[2], 2),
        ),
      );
    }
    final scale = min(size.width, size.height) / (radius * 2.4) * zoom;
    final paint = Paint();
    for (final p in points) {
      final x = p[0] - center[0], y = p[1] - center[1], z = p[2] - center[2];
      final rx = x * cos(yaw) + z * sin(yaw), rz = -x * sin(yaw) + z * cos(yaw);
      final ry = y * cos(pitch) - rz * sin(pitch);
      paint.color = HSVColor.fromAHSV(
        0.85,
        (150 - y * 35).clamp(20, 220),
        0.8,
        1,
      ).toColor();
      canvas.drawCircle(
        Offset(size.width / 2 + rx * scale, size.height / 2 - ry * scale),
        1.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeasuredPainter old) => true;
}
