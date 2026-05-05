import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/scan_project.dart';
import '../providers/settings_provider.dart';
import '../services/gopro_service.dart';
import '../services/project_service.dart';
import '../services/trajectory_service.dart';
import '../services/audio_guide_service.dart';
import '../services/lidar_service.dart';
import 'export_screen.dart';

/// Data point for a single capture event.
class CapturePoint {
  final double latitude;
  final double longitude;
  final double heading; // compass heading in degrees
  final DateTime timestamp;

  CapturePoint({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.timestamp,
  });
}

/// The live capture session screen with coverage heatmap.
class CaptureSessionScreen extends StatefulWidget {
  final ScanProject project;

  const CaptureSessionScreen({super.key, required this.project});

  @override
  State<CaptureSessionScreen> createState() => _CaptureSessionScreenState();
}

class _CaptureSessionScreenState extends State<CaptureSessionScreen> with TickerProviderStateMixin {
  late ScanProject _project;
  bool _isCapturing = false;
  int _sessionCaptureCount = 0;
  final Stopwatch _sessionTimer = Stopwatch();
  Timer? _uiTimer;

  // Coverage tracking
  final List<CapturePoint> _capturePoints = [];
  double _currentHeading = 0;
  Position? _currentPosition;
  StreamSubscription? _magnetometerSub;
  bool _hasLocationPermission = false;

  // Timelapse mode
  bool _timelapseActive = false;
  Timer? _timelapseTimer;
  int _timelapseInterval = 5; // seconds

  // Quality scoring
  double _qualityScore = 0;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _sessionCaptureCount = _project.captureCount;
    _sessionTimer.start();

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _flashAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    _initSensors();

    // Start trajectory and LiDAR recording
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrajectoryService>().startRecording();
      final lidar = context.read<LidarService>();
      lidar.checkAvailability().then((_) {
        if (lidar.isAvailable) {
          lidar.startCapture(outputDir: '${_project.id}/lidar');
        }
      });
    });
  }

  Future<void> _initSensors() async {
    // Magnetometer for compass heading (portrait mode — phone upright)
    _magnetometerSub = magnetometerEventStream().listen((event) {
      // Portrait: phone Y-axis points up, X-axis points right
      // atan2(x, y) gives heading where 0° = North (towards top of phone)
      double heading = atan2(event.x, event.y) * (180 / pi);
      if (heading < 0) heading += 360;
      heading = (360 - heading) % 360; // Correct for clockwise bearing
      setState(() => _currentHeading = heading);
    });

    // GPS
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        _hasLocationPermission = true;
        _currentPosition = await Geolocator.getCurrentPosition();
      }
    } catch (e) {
      debugPrint("GPS init error: $e");
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _timelapseTimer?.cancel();
    _sessionTimer.stop();
    _pulseController.dispose();
    _flashController.dispose();
    _magnetometerSub?.cancel();
    // Stop trajectory and LiDAR recording
    try { context.read<TrajectoryService>().stopRecording(); } catch (_) {}
    try { context.read<LidarService>().stopCapture(); } catch (_) {}
    super.dispose();
  }

  String get _elapsedTime {
    final elapsed = _sessionTimer.elapsed;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = elapsed.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  Future<void> _triggerCapture() async {
    if (_isCapturing) return;

    final goPro = context.read<GoProService>();
    final connectedCams = goPro.devices.where((d) => d.isConnected).toList();

    if (connectedCams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cameras connected!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isCapturing = true);

    // Quality-based haptic feedback
    final preCaptureCoverage = _coveragePercentage;
    HapticFeedback.heavyImpact();
    _flashController.forward().then((_) => _flashController.reverse());

    // Get current position for coverage tracking
    if (_hasLocationPermission) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
      } catch (_) {}
    }

    // Record capture point
    _capturePoints.add(CapturePoint(
      latitude: _currentPosition?.latitude ?? 0,
      longitude: _currentPosition?.longitude ?? 0,
      heading: _currentHeading,
      timestamp: DateTime.now(),
    ));

    // Record trajectory point
    context.read<TrajectoryService>().recordCapturePoint(_sessionCaptureCount);

    // Capture LiDAR frame
    final lidar = context.read<LidarService>();
    if (lidar.isAvailable && lidar.isCapturing) {
      await lidar.captureDepthFrame(_sessionCaptureCount);
    }

    // Trigger shutter on all cameras
    await goPro.triggerAllShutters();

    await Future.delayed(const Duration(milliseconds: 300));

    // Quality-based haptic: double vibrate if coverage improved significantly
    final postCaptureCoverage = _coveragePercentage;
    if (postCaptureCoverage - preCaptureCoverage > 2) {
      HapticFeedback.mediumImpact();
    }

    // Calculate quality score
    _qualityScore = _calculateQualityScore();

    setState(() {
      _sessionCaptureCount++;
      _isCapturing = false;
    });

    // Audio guidance feedback
    final audioGuide = context.read<AudioGuideService>();
    if (_capturePoints.length >= 2) {
      final last = _capturePoints.last;
      final prev = _capturePoints[_capturePoints.length - 2];
      final angleDiff = (last.heading - prev.heading).abs();
      final normalizedDiff = angleDiff > 180 ? 360 - angleDiff : angleDiff;
      if (normalizedDiff > 40) {
        audioGuide.warnLargeGap(normalizedDiff.toInt());
      } else if (normalizedDiff < 5) {
        audioGuide.warnTooClose();
      }
    }
    if (postCaptureCoverage >= 90 && preCaptureCoverage < 90) {
      audioGuide.announceGoodCoverage(postCaptureCoverage.toInt());
    }

    // Update project
    _project.captureCount = _sessionCaptureCount;
    final projectService = context.read<ProjectService>();
    await projectService.updateProject(_project);
  }

  Future<void> _endSession() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('End Capture Phase?', style: TextStyle(color: Colors.white)),
        content: Text(
          '$_sessionCaptureCount frames captured.\nReady to process or export data?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Resume')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Capture & Go to Export', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _sessionTimer.stop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ExportScreen(project: _project)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final goPro = context.watch<GoProService>();
    final connectedCams = goPro.devices.where((d) => d.isConnected).toList();
    final screenSize = MediaQuery.of(context).size;
    final primaryColor = Theme.of(context).primaryColor;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _endSession();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // ─── Top Bar ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                          onPressed: _endSession,
                        ),
                        Expanded(
                          child: Text(
                            _project.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_elapsedTime, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                  // ─── Camera Status Strip ───
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: connectedCams.length,
                      itemBuilder: (context, index) {
                        final cam = connectedCams[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, size: 14, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(cam.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                              const SizedBox(width: 6),
                              Text('${cam.batteryLevel}%', style: TextStyle(color: cam.batteryLevel > 20 ? Colors.white54 : Colors.redAccent, fontSize: 11)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ─── Coverage Heatmap ───
                  Expanded(
                    flex: 3,
                    child: _buildCoverageWidget(primaryColor),
                  ),

                  // ─── AI Capture Hint ───
                  if (_capturePoints.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _coveragePercentage >= 90
                              ? primaryColor.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _coveragePercentage >= 90 ? Icons.check_circle : Icons.assistant_navigation,
                              size: 16,
                              color: _coveragePercentage >= 90 ? primaryColor : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getAiHint(),
                                style: TextStyle(
                                  color: _coveragePercentage >= 90 ? primaryColor : Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ─── Capture Counter ───
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_sessionCaptureCount',
                          style: TextStyle(color: primaryColor, fontSize: 48, fontWeight: FontWeight.w200, fontFamily: 'monospace'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          settings.translate('captures'),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),

                  // ─── CAPTURE BUTTON ───
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isCapturing ? 0.92 : _pulseAnimation.value,
                          child: GestureDetector(
                            onTap: _triggerCapture,
                            child: Container(
                              width: screenSize.width * 0.28,
                              height: screenSize.width * 0.28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                                ),
                                boxShadow: [
                                  BoxShadow(color: primaryColor.withValues(alpha: 0.35), blurRadius: 25, spreadRadius: 6),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _project.captureMode == 'video' ? Icons.videocam : Icons.camera_alt,
                                  size: 36,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ─── Timelapse Toggle ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: _timelapseActive ? primaryColor : Colors.white38),
                        const SizedBox(width: 6),
                        Text(settings.translate('timelapse_mode'),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                        const Spacer(),
                        if (_timelapseActive)
                          GestureDetector(
                            onTap: _showTimelapseSettings,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text('${_timelapseInterval}s',
                                      style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 12, color: primaryColor),
                                ],
                              ),
                            ),
                          ),
                        Switch(
                          value: _timelapseActive,
                          activeColor: primaryColor,
                          onChanged: (val) {
                            if (val && _timelapseInterval == 5 && !_timelapseActive) { // Default starting point or give user choice
                               _toggleTimelapse(val);
                            } else {
                               _toggleTimelapse(val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // ─── Bottom Info ───
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBottomStat(Icons.camera_alt, '${connectedCams.length}', 'Cams'),
                        _buildBottomStat(Icons.aspect_ratio, _project.cameraSettings['Resolution'] ?? '4K', 'Res'),
                        _buildBottomStat(Icons.explore, '${_currentHeading.toInt()}°', 'Heading'),
                        _buildBottomStat(
                          _coveragePercentage > 80 ? Icons.check_circle : Icons.pie_chart,
                          '${_coveragePercentage.toInt()}%',
                          'Coverage',
                        ),
                        _buildBottomStat(Icons.star, '${_qualityScore.toInt()}', 'Score'),
                      ],
                    ),
                  ),
                  
                  // ─── LiDAR Status ───
                  Consumer<LidarService>(
                    builder: (context, lidar, child) {
                      if (!lidar.isAvailable) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8, left: 24, right: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radar, size: 14, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'LiDAR Active: ${lidar.depthFrameCount} frames',
                              style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Flash overlay
            AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return _flashAnimation.value > 0
                    ? Container(color: Colors.white.withValues(alpha: _flashAnimation.value))
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Coverage Visualization ─────────────────────────────────

  /// Calculate coverage as percentage of 360° that has been covered
  double get _coveragePercentage {
    if (_capturePoints.isEmpty) return 0;
    // Divide 360° into 36 sectors of 10° each
    final sectors = List<bool>.filled(36, false);
    for (final p in _capturePoints) {
      final sector = (p.heading / 10).floor() % 36;
      sectors[sector] = true;
      // Also mark adjacent sectors (camera has field of view)
      sectors[(sector + 1) % 36] = true;
      sectors[(sector - 1 + 36) % 36] = true;
    }
    return (sectors.where((s) => s).length / 36) * 100;
  }

  Widget _buildCoverageWidget(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: _capturePoints.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar, size: 48, color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 8),
                  Text(
                    'Coverage map will appear here',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start capturing to track coverage',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11),
                  ),
                ],
              ),
            )
          : CustomPaint(
              painter: CoverageHeatmapPainter(
                capturePoints: _capturePoints,
                currentHeading: _currentHeading,
                primaryColor: primaryColor,
              ),
              child: const SizedBox.expand(),
            ),
    );
  }

  Widget _buildBottomStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9)),
      ],
    );
  }

  // ─── TIMELAPSE ──────────────────────────────────────────────

  void _toggleTimelapse(bool active) {
    setState(() => _timelapseActive = active);
    if (active) {
      _timelapseTimer?.cancel();
      _timelapseTimer = Timer.periodic(Duration(seconds: _timelapseInterval), (_) {
        if (!_isCapturing) _triggerCapture();
      });
    } else {
      _timelapseTimer?.cancel();
    }
  }

  void _showTimelapseSettings() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Auto-Trigger Interval', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [3, 5, 10, 15, 30].map((sec) {
              return ListTile(
                title: Text('$sec Seconds', style: const TextStyle(color: Colors.white70)),
                trailing: _timelapseInterval == sec
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  setState(() => _timelapseInterval = sec);
                  if (_timelapseActive) {
                    _toggleTimelapse(true); // Restart timer with new interval
                  }
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ─── QUALITY SCORING ────────────────────────────────────────

  double _calculateQualityScore() {
    if (_capturePoints.length < 2) return 0;
    double score = 0;

    // Coverage contributes 40% of score
    score += (_coveragePercentage / 100) * 40;

    // Overlap consistency contributes 30%
    double overlapScore = 0;
    for (int i = 1; i < _capturePoints.length; i++) {
      final angleDiff = (_capturePoints[i].heading - _capturePoints[i - 1].heading).abs();
      final normalizedDiff = angleDiff > 180 ? 360 - angleDiff : angleDiff;
      // Ideal overlap: 15-30 degrees between captures
      if (normalizedDiff >= 10 && normalizedDiff <= 35) {
        overlapScore += 1.0;
      } else if (normalizedDiff < 10) {
        overlapScore += 0.5; // Too close
      } else {
        overlapScore += 0.2; // Too far apart
      }
    }
    score += (overlapScore / (_capturePoints.length - 1)) * 30;

    // Capture density contributes 30% (target: 50+ captures)
    score += min(_capturePoints.length / 50, 1.0) * 30;

    return score.clamp(0, 100);
  }

  /// AI Capture Hint: Analyzes coverage gaps, overlap, speed, and suggests direction.
  String _getAiHint() {
    if (_coveragePercentage >= 95) return '✅ Excellent coverage! Quality: ${_qualityScore.toInt()}/100';
    if (_coveragePercentage >= 90) return '🎯 Great coverage. A few more for safety.';

    // Check overlap between last captures
    if (_capturePoints.length >= 2) {
      final last = _capturePoints.last;
      final prev = _capturePoints[_capturePoints.length - 2];
      final angleDiff = (last.heading - prev.heading).abs();
      final normalizedDiff = angleDiff > 180 ? 360 - angleDiff : angleDiff;

      if (normalizedDiff > 40) {
        return '⚠️ Large gap (${normalizedDiff.toInt()}°) between last captures. Move slower.';
      }
      if (normalizedDiff < 5) {
        return '↔️ Too similar to previous. Rotate more before next capture.';
      }

      // Check speed (if GPS available)
      if (last.latitude != 0 && prev.latitude != 0) {
        final dt = last.timestamp.difference(prev.timestamp).inSeconds;
        if (dt > 0) {
          final dx = last.latitude - prev.latitude;
          final dy = last.longitude - prev.longitude;
          final dist = sqrt(dx * dx + dy * dy) * 111320; // meters
          final speed = dist / dt; // m/s
          if (speed > 2.0) {
            return '🏃 Moving too fast (${speed.toStringAsFixed(1)} m/s). Slow down for sharp images.';
          }
        }
      }
    }

    // Find the largest gap
    final sectors = List<bool>.filled(36, false);
    for (final p in _capturePoints) {
      final sector = (p.heading / 10).floor() % 36;
      sectors[sector] = true;
      sectors[(sector + 1) % 36] = true;
      sectors[(sector - 1 + 36) % 36] = true;
    }

    int maxGapStart = 0, maxGapLen = 0, curStart = -1, curLen = 0;
    for (int i = 0; i < 72; i++) {
      if (!sectors[i % 36]) {
        if (curStart == -1) curStart = i;
        curLen++;
        if (curLen > maxGapLen) { maxGapLen = curLen; maxGapStart = curStart; }
      } else {
        curStart = -1; curLen = 0;
      }
    }

    if (maxGapLen == 0) return '🔄 Good coverage. Keep scanning for density.';

    final gapCenter = ((maxGapStart + maxGapLen / 2) % 36) * 10;
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final dirIndex = ((gapCenter + 22.5) / 45).floor() % 8;

    return '🧭 Gap ${directions[dirIndex]} (${gapCenter.toInt()}°). Turn that way and capture.';
  }
}

// ─── COVERAGE HEATMAP PAINTER ───────────────────────────────

class CoverageHeatmapPainter extends CustomPainter {
  final List<CapturePoint> capturePoints;
  final double currentHeading;
  final Color primaryColor;

  CoverageHeatmapPainter({
    required this.capturePoints,
    required this.currentHeading,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;

    // Draw concentric rings
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), ringPaint);
    }

    // Draw compass lines (N, E, S, W)
    final compassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (int deg = 0; deg < 360; deg += 90) {
      final rad = deg * pi / 180;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * sin(rad), center.dy - radius * cos(rad)),
        compassPaint,
      );
    }

    // Draw compass labels
    final textStyle = TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10);
    _drawText(canvas, 'N', Offset(center.dx - 4, center.dy - radius - 14), textStyle);
    _drawText(canvas, 'E', Offset(center.dx + radius + 4, center.dy - 5), textStyle);
    _drawText(canvas, 'S', Offset(center.dx - 4, center.dy + radius + 4), textStyle);
    _drawText(canvas, 'W', Offset(center.dx - radius - 14, center.dy - 5), textStyle);

    // Draw coverage sectors (36 sectors of 10°)
    final sectorCounts = List<int>.filled(36, 0);
    for (final p in capturePoints) {
      final sector = (p.heading / 10).floor() % 36;
      sectorCounts[sector]++;
    }

    final maxCount = sectorCounts.reduce(max).clamp(1, 100);

    for (int i = 0; i < 36; i++) {
      if (sectorCounts[i] == 0) continue;

      final startAngle = (i * 10 - 90) * pi / 180; // -90 to align N to top
      const sweepAngle = 10 * pi / 180;
      final intensity = sectorCounts[i] / maxCount;

      final sectorPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.1 + intensity * 0.5)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, sweepAngle, true, sectorPaint);
    }

    // Draw capture points as dots
    for (int i = 0; i < capturePoints.length; i++) {
      final p = capturePoints[i];
      final rad = (p.heading - 90) * pi / 180;
      // Place dots at varying distances from center to avoid overlap
      final dist = radius * 0.3 + (i % 5) * (radius * 0.12);
      final dotPos = Offset(center.dx + dist * cos(rad), center.dy + dist * sin(rad));

      final dotPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dotPos, 3, dotPaint);
    }

    // Draw current heading arrow
    final arrowRad = (currentHeading - 90) * pi / 180;
    final arrowEnd = Offset(
      center.dx + (radius + 8) * cos(arrowRad),
      center.dy + (radius + 8) * sin(arrowRad),
    );
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, arrowEnd, arrowPaint);

    // Arrow tip
    canvas.drawCircle(arrowEnd, 4, Paint()..color = Colors.white.withValues(alpha: 0.7));
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CoverageHeatmapPainter oldDelegate) {
    return capturePoints.length != oldDelegate.capturePoints.length ||
        currentHeading != oldDelegate.currentHeading;
  }
}
