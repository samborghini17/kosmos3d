import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/camera_device.dart';
import '../widgets/glass_card.dart';
import '../services/gopro_service.dart';
import '../providers/settings_provider.dart';

class DeviceManagerScreen extends StatefulWidget {
  const DeviceManagerScreen({super.key});

  @override
  State<DeviceManagerScreen> createState() => _DeviceManagerScreenState();
}

class _DeviceManagerScreenState extends State<DeviceManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goPro = context.read<GoProService>();
      if (!goPro.isScanning && goPro.devices.isEmpty) {
        _checkLocationAndScan(goPro);
      }
    });
  }

  Future<void> _checkLocationAndScan(GoProService goPro) async {
    if (await Permission.location.serviceStatus.isDisabled) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Location Services Required', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Android requires Location / GPS to be ON for Bluetooth scanning.\n\nPull down your quick settings and turn on Location.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK', style: TextStyle(color: Theme.of(context).primaryColor)),
              ),
            ],
          ),
        );
      }
      return;
    }
    goPro.startScan();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final goPro = context.watch<GoProService>();
    final cameras = goPro.devices;

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.translate('device_manager')),
        actions: [
          IconButton(
            icon: goPro.isScanning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh),
            onPressed: goPro.isScanning ? null : () => _checkLocationAndScan(goPro),
            tooltip: settings.translate('scanning'),
          ),
        ],
      ),
      body: SafeArea(
        child: cameras.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bluetooth_searching, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text(
                      goPro.isScanning ? settings.translate('scanning') : settings.translate('no_cameras_found'),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                    ),
                    if (!goPro.isScanning) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _checkLocationAndScan(goPro),
                        icon: const Icon(Icons.search),
                        label: const Text('Scan for Devices'),
                      ),
                    ],
                  ],
                ),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.all(16),
                itemCount: cameras.length,
                itemBuilder: (context, index) {
                  final cam = cameras[index];
                  return _buildCameraCard(context, cam, goPro, settings);
                },
              ),
      ),
    );
  }

  Widget _buildCameraCard(BuildContext context, CameraDevice cam, GoProService goPro, SettingsProvider settings) {
    final isGoPro = cam.name.toLowerCase().contains('gopro');
    final primaryColor = Theme.of(context).primaryColor;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: Name + Connection Status ───
            InkWell(
              onTap: () {
                if (!cam.isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${settings.translate('connecting')} ${cam.name}...')),
                  );
                  goPro.connectToDevice(cam.id);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  // Camera icon with connection indicator
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cam.isConnected
                              ? primaryColor.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isGoPro ? Icons.camera_alt : Icons.bluetooth,
                          color: cam.isConnected ? primaryColor : Colors.white38,
                          size: 24,
                        ),
                      ),
                      if (cam.isConnected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Name & status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cam.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cam.isConnected ? 'Connected' : 'Tap to connect',
                          style: TextStyle(
                            color: cam.isConnected ? primaryColor : Colors.white38,
                            fontSize: 12,
                            fontWeight: cam.isConnected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Battery indicator (only when connected)
                  if (cam.isConnected) _buildBatteryWidget(cam, primaryColor),
                ],
              ),
            ),

            // ─── Connected Camera Details ───
            if (cam.isConnected) ...[
              const SizedBox(height: 12),
              // Current settings chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: cam.currentSettings.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  // Photo Mode
                  _buildActionButton(
                    icon: Icons.photo_camera,
                    label: 'Photo',
                    onTap: () async {
                      await goPro.setPhotoMode(cam.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Switched to Photo mode'), backgroundColor: Colors.green),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // Video Mode
                  _buildActionButton(
                    icon: Icons.videocam,
                    label: 'Video',
                    onTap: () async {
                      await goPro.setVideoMode(cam.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Switched to Video mode'), backgroundColor: Colors.green),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // Shutter
                  _buildActionButton(
                    icon: Icons.circle,
                    label: cam.isRecording ? 'Stop' : 'Shutter',
                    color: cam.isRecording ? Colors.redAccent : null,
                    onTap: () {
                      goPro.toggleRecording(cam.id, !cam.isRecording);
                    },
                  ),
                  const SizedBox(width: 8),
                  // Settings
                  _buildActionButton(
                    icon: Icons.tune,
                    label: 'Settings',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => CameraSettingsDialog(
                          camera: cam,
                          goProService: goPro,
                          settingsProvider: settings,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryWidget(CameraDevice cam, Color primaryColor) {
    final batteryColor = cam.batteryLevel > 50
        ? primaryColor
        : cam.batteryLevel > 20
            ? Colors.orange
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: batteryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            cam.batteryLevel > 80
                ? Icons.battery_full
                : cam.batteryLevel > 50
                    ? Icons.battery_5_bar
                    : cam.batteryLevel > 20
                        ? Icons.battery_3_bar
                        : Icons.battery_alert,
            size: 16,
            color: batteryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${cam.batteryLevel}%',
            style: TextStyle(color: batteryColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, VoidCallback? onTap, Color? color}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: (color ?? Colors.white).withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color ?? Colors.white70),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: color ?? Colors.white54, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CAMERA SETTINGS DIALOG ─────────────────────────────────

class CameraSettingsDialog extends StatefulWidget {
  final CameraDevice camera;
  final GoProService goProService;
  final SettingsProvider settingsProvider;

  const CameraSettingsDialog({
    super.key,
    required this.camera,
    required this.goProService,
    required this.settingsProvider,
  });

  @override
  State<CameraSettingsDialog> createState() => _CameraSettingsDialogState();
}

class _CameraSettingsDialogState extends State<CameraSettingsDialog> {
  late Map<String, String> _settings;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _settings = Map.from(widget.camera.currentSettings);
  }

  Future<void> _applyAllSettings() async {
    setState(() => _isApplying = true);

    // Apply settings via BLE
    await widget.goProService.applySettingsToDevice(widget.camera.id, _settings);
    widget.goProService.updateCameraSettings(widget.camera.id, _settings);

    setState(() => _isApplying = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings applied to camera!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.camera.name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Apply all button
          TextButton.icon(
            onPressed: _isApplying ? null : _applyAllSettings,
            icon: _isApplying
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.send, size: 16, color: Theme.of(context).primaryColor),
            label: Text(
              'Apply',
              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _settings.keys.map((key) {
            final options = _getOptionsForKey(key);
            final currentValue = options.contains(_settings[key]) ? _settings[key] : options.first;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 95,
                    child: Text(key, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF2E2E2E),
                          value: currentValue,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          isExpanded: true,
                          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _settings[key] = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.settingsProvider.translate('close'), style: TextStyle(color: Theme.of(context).primaryColor)),
        ),
      ],
    );
  }

  List<String> _getOptionsForKey(String key) {
    switch (key) {
      case 'Resolution': return ['1080p', '2.7K', '4K', '5.3K'];
      case 'FPS': return ['24', '30', '60', '120'];
      case 'Lens': return ['Linear', 'Wide', 'SuperView'];
      case 'ISO Max': return ['100', '200', '400', '800', '1600'];
      case 'Shutter': return ['Auto', '1/60', '1/120', '1/240', '1/480'];
      case 'White Balance': return ['Auto', '3200K', '4000K', '5500K', '6500K'];
      case 'Bitrate': return ['Standard', 'High'];
      default: return [_settings[key] ?? ''];
    }
  }
}
