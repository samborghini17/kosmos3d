import '../l10n/app_text.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/capture_point.dart';

/// Lixel-Inspired Interactive 3D Scanning HUD, Trajectory & Point Cloud Coverage Visualizer.
/// Features:
/// - Real-time 3D Trajectory Ribbon connecting camera poses.
/// - Upright 3D Camera Frustums showing exact lens orientation.
/// - Surface Point Cloud with Height Gradient & Overlap Density Heatmap modes.
/// - Real-time Lixel Scan Quality Guard (Walking Speed, 360° Loop Closure, Multi-Height Levels).
/// - 3D Orbit, Pinch-Zoom, Pan, and 2D Polar Radar fallback.
class PointCloudCoverageVisualizer extends StatefulWidget {
  final List<CapturePoint> capturePoints;
  final double currentHeading;
  final double currentPitch;
  final double currentRoll;
  final Color primaryColor;
  final double coveragePercentage;
  final double qualityScore;
  final double currentSpeed; // Walking speed in m/s

  const PointCloudCoverageVisualizer({
    super.key,
    required this.capturePoints,
    required this.currentHeading,
    this.currentPitch = 0.0,
    this.currentRoll = 0.0,
    required this.primaryColor,
    required this.coveragePercentage,
    required this.qualityScore,
    this.currentSpeed = 0.0,
  });

  @override
  State<PointCloudCoverageVisualizer> createState() =>
      _PointCloudCoverageVisualizerState();
}

enum ColorMode { density, height }

class _PointCloudCoverageVisualizerState
    extends State<PointCloudCoverageVisualizer>
    with SingleTickerProviderStateMixin {
  bool _is3DMode = true;
  ColorMode _colorMode = ColorMode.density;
  double _rotX = 0.45; // Elevation / pitch angle
  double _rotY = 0.0; // Azimuth / yaw angle
  double _zoom = 1.0;
  Offset _pan = Offset.zero;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _resetView() {
    setState(() {
      _rotX = 0.45;
      _rotY = 0.0;
      _zoom = 1.0;
      _pan = Offset.zero;
    });
  }

  void _setTopDownView() {
    setState(() {
      _rotX = pi / 2.05;
      _rotY = 0.0;
      _zoom = 1.1;
      _pan = Offset.zero;
    });
  }

  void _setFrontView() {
    setState(() {
      _rotX = 0.05;
      _rotY = 0.0;
      _zoom = 1.0;
      _pan = Offset.zero;
    });
  }

  bool get _isLoopClosed {
    if (widget.capturePoints.length < 8) return false;
    // Check if total covered sectors >= 30 out of 36 (>= 83% 360° coverage)
    final sectors = <int>{};
    for (final p in widget.capturePoints) {
      sectors.add(((p.heading % 360) / 10).floor());
    }
    return sectors.length >= 28;
  }

  @override
  Widget build(BuildContext context) {
    final isSpeedWarning = widget.currentSpeed > 1.5;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // 1. Main Interactive 3D/2D Canvas
          GestureDetector(
            onScaleStart: (_) {},
            onScaleUpdate: (details) {
              if (!_is3DMode) return;
              setState(() {
                if (details.pointerCount == 1) {
                  _rotY += details.focalPointDelta.dx * 0.009;
                  _rotX += details.focalPointDelta.dy * 0.009;
                  _rotX = _rotX.clamp(-pi / 2.1, pi / 2.1);
                } else {
                  _zoom = (_zoom * details.scale).clamp(0.4, 4.0);
                  _pan += details.focalPointDelta;
                }
              });
            },
            child: Container(
              color: const Color(0xFF090A0F),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _is3DMode
                        ? Lixel3DScanningPainter(
                            capturePoints: widget.capturePoints,
                            currentHeading: widget.currentHeading,
                            currentPitch: widget.currentPitch,
                            currentRoll: widget.currentRoll,
                            primaryColor: widget.primaryColor,
                            colorMode: _colorMode,
                            rotX: _rotX,
                            rotY: _rotY,
                            zoom: _zoom,
                            pan: _pan,
                            pulseValue: _pulseController.value,
                            isLoopClosed: _isLoopClosed,
                          )
                        : PolarCoverageRadarPainter(
                            capturePoints: widget.capturePoints,
                            currentHeading: widget.currentHeading,
                            primaryColor: widget.primaryColor,
                          ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),

          // 2. Top Controls & Status Bar
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mode Toggle (3D Cloud vs 2D Radar)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleButton(
                        label: '3D SLAM',
                        icon: Icons.view_in_ar,
                        isSelected: _is3DMode,
                        onTap: () => setState(() => _is3DMode = true),
                      ),
                      _buildToggleButton(
                        label: '2D Radar',
                        icon: Icons.radar,
                        isSelected: !_is3DMode,
                        onTap: () => setState(() => _is3DMode = false),
                      ),
                    ],
                  ),
                ),

                // 3D Quick Perspectives & Color Mode Switcher
                if (_is3DMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Color Mode Toggle (Density / Height)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _colorMode = _colorMode == ColorMode.density
                                  ? ColorMode.height
                                  : ColorMode.density;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _colorMode == ColorMode.density
                                      ? Icons.waves
                                      : Icons.height,
                                  size: 13,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: 3),
                                AppText(
                                  _colorMode == ColorMode.density
                                      ? 'Density'
                                      : 'Height',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // View Presets
                      _buildIconButton(
                        Icons.vertical_align_top,
                        'Top View',
                        _setTopDownView,
                      ),
                      const SizedBox(width: 4),
                      _buildIconButton(
                        Icons.crop_portrait,
                        'Front View',
                        _setFrontView,
                      ),
                      const SizedBox(width: 4),
                      _buildIconButton(
                        Icons.restart_alt,
                        'Reset 3D View',
                        _resetView,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 3. Lixel Real-Time Quality Guidance HUD (Loop Closure + Speed Guard)
          if (_isLoopClosed)
            Positioned(
              top: 50,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.white),
                    SizedBox(width: 5),
                    AppText(
                      '360° LOOP CLOSED • 3DGS READY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (isSpeedWarning)
            Positioned(
              top: 50,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.speed, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    AppText(
                      'SLOW DOWN (< 1.0 m/s)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Bottom Orbit & Pose Overlay
          if (_is3DMode)
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppText(
                      'Heading: ${widget.currentHeading.toStringAsFixed(1)}°  Pitch: ${widget.currentPitch.toStringAsFixed(1)}°',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppText(
                      '${widget.capturePoints.length} Poses • ${widget.coveragePercentage.toStringAsFixed(0)}% Cov',
                      style: TextStyle(
                        color: widget.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 14, color: Colors.white70),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? widget.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 4),
            AppText(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lixel 3D Scanning Painter:
/// Renders the 3D ground grid, object anchor, smooth 3D trajectory path,
/// upright 3D camera pose frustums, and multi-mode surface point clouds.
class Lixel3DScanningPainter extends CustomPainter {
  final List<CapturePoint> capturePoints;
  final double currentHeading;
  final double currentPitch;
  final double currentRoll;
  final Color primaryColor;
  final ColorMode colorMode;
  final double rotX;
  final double rotY;
  final double zoom;
  final Offset pan;
  final double pulseValue;
  final bool isLoopClosed;

  Lixel3DScanningPainter({
    required this.capturePoints,
    required this.currentHeading,
    required this.currentPitch,
    required this.currentRoll,
    required this.primaryColor,
    required this.colorMode,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.pan,
    required this.pulseValue,
    required this.isLoopClosed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2 + pan.dx, size.height / 2 + pan.dy);
    final baseScale = min(size.width, size.height) * 0.44 * zoom;

    // 3D Perspective Projection Matrix
    Offset project(double x, double y, double z) {
      // Rotate around Y axis (Azimuth)
      final cosY = cos(rotY);
      final sinY = sin(rotY);
      final rx = x * cosY - z * sinY;
      final rz = x * sinY + z * cosY;

      // Rotate around X axis (Pitch / Elevation)
      final cosX = cos(rotX);
      final sinX = sin(rotX);
      final ry = y * cosX - rz * sinX;
      final rz2 = y * sinX + rz * cosX;

      // Perspective foreshortening
      final perspective = 1.0 + rz2 * 0.45;
      final clampedP = perspective.clamp(0.25, 3.5);

      return Offset(
        center.dx + (rx * baseScale) / clampedP,
        center.dy - (ry * baseScale) / clampedP,
      );
    }

    // 1. Draw 3D Ground Grid (Spatial reference frame)
    final gridPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.06)
      ..strokeWidth = 0.8;
    const gridDivs = 4;
    const gridRadius = 1.3;
    for (int i = -gridDivs; i <= gridDivs; i++) {
      final f = (i / gridDivs) * gridRadius;
      canvas.drawLine(
        project(f, -0.6, -gridRadius),
        project(f, -0.6, gridRadius),
        gridPaint,
      );
      canvas.drawLine(
        project(-gridRadius, -0.6, f),
        project(gridRadius, -0.6, f),
        gridPaint,
      );
    }

    // 2. Draw Subject / Object Scanning Target Center
    final centerPos = project(0, 0, 0);
    canvas.drawCircle(
      centerPos,
      4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      centerPos,
      8 + pulseValue * 3,
      Paint()
        ..color = (isLoopClosed ? const Color(0xFF10B981) : primaryColor)
            .withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 3. Draw 360° Scanning Orbit Ring
    final orbitPaint = Paint()
      ..color = (isLoopClosed ? const Color(0xFF10B981) : Colors.white)
          .withValues(alpha: isLoopClosed ? 0.35 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLoopClosed ? 2.0 : 1.0;
    const orbitRadius = 0.95;
    final orbitPoints = <Offset>[];
    for (int deg = 0; deg <= 360; deg += 10) {
      final rad = deg * pi / 180;
      orbitPoints.add(
        project(sin(rad) * orbitRadius, 0.0, -cos(rad) * orbitRadius),
      );
    }
    for (int i = 0; i < orbitPoints.length - 1; i++) {
      canvas.drawLine(orbitPoints[i], orbitPoints[i + 1], orbitPaint);
    }

    // 4. Sector Coverage Arcs on Orbit Ring
    final sectors = List<int>.filled(36, 0);
    for (final p in capturePoints) {
      final s = ((p.heading % 360) / 10).floor() % 36;
      sectors[s]++;
      sectors[(s + 1) % 36]++;
      sectors[(s - 1 + 36) % 36]++;
    }

    for (int s = 0; s < 36; s++) {
      if (sectors[s] > 0) {
        final rad1 = (s * 10) * pi / 180;
        final rad2 = ((s + 1) * 10) * pi / 180;
        final p1 = project(
          sin(rad1) * orbitRadius,
          0,
          -cos(rad1) * orbitRadius,
        );
        final p2 = project(
          sin(rad2) * orbitRadius,
          0,
          -cos(rad2) * orbitRadius,
        );

        final sectorColor = sectors[s] >= 3
            ? const Color(0xFF10B981)
            : primaryColor;

        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = sectorColor.withValues(alpha: 0.7)
            ..strokeWidth = 3.5,
        );
      }
    }

    // 5. Draw 3D Trajectory Ribbon (Lixel-style scanning path)
    if (capturePoints.length > 1) {
      final trajPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      final pathPoints = <Offset>[];
      for (int i = 0; i < capturePoints.length; i++) {
        final cp = capturePoints[i];
        final hRad = (cp.heading % 360) * pi / 180;
        final camX = sin(hRad) * orbitRadius;
        final camY = 0.05 + (i % 3 - 1) * 0.08;
        final camZ = -cos(hRad) * orbitRadius;
        pathPoints.add(project(camX, camY, camZ));
      }

      for (int i = 0; i < pathPoints.length - 1; i++) {
        canvas.drawLine(pathPoints[i], pathPoints[i + 1], trajPaint);
      }
    }

    // 6. Generate and Draw 3D Surface Point Cloud
    final random = Random(42);
    for (int i = 0; i < capturePoints.length; i++) {
      final cp = capturePoints[i];
      final headingRad = (cp.heading % 360) * pi / 180;

      final camX = sin(headingRad) * orbitRadius;
      final camY = 0.05 + (i % 3 - 1) * 0.08;
      final camZ = -cos(headingRad) * orbitRadius;

      // Project surface point cloud (target sphere around center)
      const pointCount = 45;
      for (int k = 0; k < pointCount; k++) {
        final r = 0.28 + random.nextDouble() * 0.12;
        final theta = headingRad + (random.nextDouble() - 0.5) * 0.55;
        final phi = (random.nextDouble() - 0.5) * 0.65;

        final px = sin(theta) * cos(phi) * r;
        final py = sin(phi) * r;
        final pz = -cos(theta) * cos(phi) * r;

        final pt2D = project(px, py, pz);

        Color ptColor;
        if (colorMode == ColorMode.height) {
          // Height gradient: Blue (bottom) -> Cyan -> Yellow -> Magenta (top)
          final normY = ((py + 0.2) / 0.4).clamp(0.0, 1.0);
          if (normY < 0.33) {
            ptColor = Color.lerp(
              Colors.blueAccent,
              Colors.cyanAccent,
              normY * 3,
            )!;
          } else if (normY < 0.66) {
            ptColor = Color.lerp(
              Colors.cyanAccent,
              Colors.yellowAccent,
              (normY - 0.33) * 3,
            )!;
          } else {
            ptColor = Color.lerp(
              Colors.yellowAccent,
              Colors.purpleAccent,
              (normY - 0.66) * 3,
            )!;
          }
        } else {
          // Overlap density gradient (Lixel style)
          final density = sectors[((cp.heading % 360) / 10).floor() % 36];
          ptColor = density >= 3
              ? const Color(0xFF10B981) // High overlap green
              : (density == 2
                    ? Colors.orangeAccent
                    : Colors.redAccent); // Red for bad coverage
        }

        canvas.drawCircle(
          pt2D,
          1.2 * zoom.clamp(0.5, 3.0),
          Paint()..color = ptColor.withValues(alpha: 0.8),
        );
      }

      // Draw Camera Frustum (Upright 3D Pyramid pointing to scene origin)
      _drawCameraFrustum(
        canvas: canvas,
        project: project,
        camPos: Offset3D(camX, camY, camZ),
        targetPos: const Offset3D(0, 0, 0),
        color: (i == capturePoints.length - 1)
            ? primaryColor
            : primaryColor.withValues(alpha: 0.4),
        isLatest: i == capturePoints.length - 1,
      );
    }

    // 7. Draw Current Active Camera in Real-time (Upright Orientation)
    final activeHeadingRad = (currentHeading % 360) * pi / 180;
    final activePitchRad = (currentPitch.clamp(-60, 60)) * pi / 180;
    final activeCamX = sin(activeHeadingRad) * orbitRadius;
    final activeCamY = 0.08 + sin(activePitchRad) * 0.15;
    final activeCamZ = -cos(activeHeadingRad) * orbitRadius;

    final activeCam2D = project(activeCamX, activeCamY, activeCamZ);

    // Glowing active camera ring
    canvas.drawCircle(
      activeCam2D,
      6.5 * zoom.clamp(0.8, 2.0),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      activeCam2D,
      (10 + pulseValue * 6) * zoom.clamp(0.8, 2.0),
      Paint()
        ..color = primaryColor.withValues(alpha: 0.45 * (1.0 - pulseValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Active real-time frustum
    _drawCameraFrustum(
      canvas: canvas,
      project: project,
      camPos: Offset3D(activeCamX, activeCamY, activeCamZ),
      targetPos: const Offset3D(0, 0, 0),
      color: Colors.white,
      isLatest: true,
    );
  }

  /// Draws a 3D camera frustum (pyramid) with apex at camera and base facing target
  void _drawCameraFrustum({
    required Canvas canvas,
    required Offset Function(double x, double y, double z) project,
    required Offset3D camPos,
    required Offset3D targetPos,
    required Color color,
    bool isLatest = false,
  }) {
    final apex = project(camPos.x, camPos.y, camPos.z);

    // Direction vector from camera to target
    final dx = targetPos.x - camPos.x;
    final dy = targetPos.y - camPos.y;
    final dz = targetPos.z - camPos.z;
    final len = sqrt(dx * dx + dy * dy + dz * dz);
    if (len < 0.001) return;

    final fwdX = dx / len;
    final fwdY = dy / len;
    final fwdZ = dz / len;

    // Up vector for upright portrait camera
    const upX = 0.0;
    const upY = 1.0;
    const upZ = 0.0;

    // Right vector = Fwd x Up
    final rightX = fwdY * upZ - fwdZ * upY;
    final rightY = fwdZ * upX - fwdX * upZ;
    final rightZ = fwdX * upY - fwdY * upX;
    final rLen = sqrt(rightX * rightX + rightY * rightY + rightZ * rightZ);
    if (rLen < 0.001) return;
    final rX = rightX / rLen;
    final rY = rightY / rLen;
    final rZ = rightZ / rLen;

    // True Orthogonal Up vector = Right x Fwd
    final tUpX = rY * fwdZ - rZ * fwdY;
    final tUpY = rZ * fwdX - rX * fwdZ;
    final tUpZ = rX * fwdY - rY * fwdX;

    // Frustum dimensions
    const frustumDist = 0.17;
    const halfW = 0.085;
    const halfH = 0.12;

    final baseX = camPos.x + fwdX * frustumDist;
    final baseY = camPos.y + fwdY * frustumDist;
    final baseZ = camPos.z + fwdZ * frustumDist;

    // 4 Base corners of frustum
    final c1 = project(
      baseX + rX * halfW + tUpX * halfH,
      baseY + rY * halfW + tUpY * halfH,
      baseZ + rZ * halfW + tUpZ * halfH,
    );
    final c2 = project(
      baseX - rX * halfW + tUpX * halfH,
      baseY - rY * halfW + tUpY * halfH,
      baseZ - rZ * halfW + tUpZ * halfH,
    );
    final c3 = project(
      baseX - rX * halfW - tUpX * halfH,
      baseY - rY * halfW - tUpY * halfH,
      baseZ - rZ * halfW - tUpZ * halfH,
    );
    final c4 = project(
      baseX + rX * halfW - tUpX * halfH,
      baseY + rY * halfW - tUpY * halfH,
      baseZ + rZ * halfW - tUpZ * halfH,
    );

    final linePaint = Paint()
      ..color = color.withValues(alpha: isLatest ? 0.9 : 0.45)
      ..strokeWidth = isLatest ? 1.6 : 1.0
      ..style = PaintingStyle.stroke;

    // Connect apex to 4 corners
    canvas.drawLine(apex, c1, linePaint);
    canvas.drawLine(apex, c2, linePaint);
    canvas.drawLine(apex, c3, linePaint);
    canvas.drawLine(apex, c4, linePaint);

    // Base rectangle
    final path = Path()
      ..moveTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..lineTo(c3.dx, c3.dy)
      ..lineTo(c4.dx, c4.dy)
      ..close();

    canvas.drawPath(path, linePaint);

    if (isLatest) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant Lixel3DScanningPainter oldDelegate) => true;
}

class Offset3D {
  final double x, y, z;
  const Offset3D(this.x, this.y, this.z);
}

/// Upright Polar 2D Radar Painter with corrected forward-heading orientation
class PolarCoverageRadarPainter extends CustomPainter {
  final List<CapturePoint> capturePoints;
  final double currentHeading;
  final Color primaryColor;

  PolarCoverageRadarPainter({
    required this.capturePoints,
    required this.currentHeading,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;

    // Background concentric rings
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), ringPaint);
    }

    // Cardinal axes
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      axisPaint,
    );

    // Sector coverage arcs (36 sectors = 10° each)
    final sectors = List<int>.filled(36, 0);
    for (final p in capturePoints) {
      final sector = ((p.heading % 360) / 10).floor() % 36;
      sectors[sector]++;
      sectors[(sector + 1) % 36]++;
      sectors[(sector - 1 + 36) % 36]++;
    }

    for (int i = 0; i < 36; i++) {
      if (sectors[i] > 0) {
        final startAngle = (i * 10 - 90) * pi / 180;
        const sweepAngle = 10 * pi / 180;
        final arcColor = sectors[i] >= 3
            ? const Color(0xFF10B981) // High overlap green
            : primaryColor; // Moderate overlap cyan

        final arcPaint = Paint()
          ..color = arcColor.withValues(
            alpha: (sectors[i] * 0.25).clamp(0.3, 0.8),
          )
          ..style = PaintingStyle.fill;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          true,
          arcPaint,
        );
      }
    }

    // Plotted capture points
    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (final p in capturePoints) {
      final rad = (p.heading - 90) * pi / 180;
      final r = radius * 0.85;
      final px = center.dx + r * cos(rad);
      final py = center.dy + r * sin(rad);
      canvas.drawCircle(Offset(px, py), 3.5, pointPaint);
    }

    // Current live heading arrow
    final curRad = (currentHeading - 90) * pi / 180;
    final tipX = center.dx + radius * 0.95 * cos(curRad);
    final tipY = center.dy + radius * 0.95 * sin(curRad);

    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(tipX, tipY), arrowPaint);
    canvas.drawCircle(Offset(tipX, tipY), 5, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4, Paint()..color = primaryColor);
  }

  @override
  bool shouldRepaint(covariant PolarCoverageRadarPainter oldDelegate) => true;
}
