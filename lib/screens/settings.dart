import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import 'device_manager.dart';
import '../providers/settings_provider.dart';
import '../services/cloud_storage_service.dart';
import '../services/rig_geometry_service.dart';
import '../services/lidar_service.dart';
import '../services/gopro_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cloud = context.watch<CloudStorageService>();
    final rig = context.watch<RigGeometryService>();
    final lidar = context.watch<LidarService>();

    return Scaffold(
      appBar: AppBar(title: Text(settings.translate('settings'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ─── APPEARANCE ─────────────────────────────
            _buildSectionHeader(context, 'Appearance'),
            GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.brightness_6, size: 24),
                    title: const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(settings.themeMode == ThemeMode.system ? 'System Default'
                        : settings.themeMode == ThemeMode.dark ? 'Dark' : 'Light'),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android, size: 16)),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 16)),
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 16)),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (v) => settings.setThemeMode(v.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Text(settings.currentLanguage == 'en' ? '🇬🇧' : '🇩🇪', style: const TextStyle(fontSize: 24)),
                    title: Text(settings.translate('language'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(settings.currentLanguage == 'en' ? 'English' : 'Deutsch'),
                    trailing: Switch(
                      value: settings.currentLanguage == 'de',
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (_) => settings.toggleLanguage(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── DEVICE MANAGER ─────────────────────────
            _buildSectionHeader(context, settings.translate('device_manager')),
            _buildSettingCard(context,
              title: settings.translate('device_manager'),
              subtitle: settings.translate('manage_gopros'),
              icon: Icons.camera_alt,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceManagerScreen())),
            ),
            const SizedBox(height: 16),

            // ─── SCANNING PRESETS ───────────────────────
            _buildSectionHeader(context, settings.translate('scanning_presets')),
            ...settings.allPresets.map((preset) => GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Text(preset.icon, style: const TextStyle(fontSize: 24)),
                title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${preset.settings['Resolution']} · ${preset.settings['FPS']}fps · ${preset.settings['Lens']}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5), fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showPresetDetail(context, preset, settings),
              ),
            )),
            _buildSettingCard(context,
              title: settings.translate('create_preset'),
              subtitle: settings.translate('create_preset_desc'),
              icon: Icons.add_circle_outline,
              onTap: () => _showCreatePresetDialog(context, settings),
            ),
            const SizedBox(height: 16),

            // ─── SENSOR SETTINGS ────────────────────────
            _buildSectionHeader(context, 'Sensor & Capture'),
            GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: const Icon(Icons.vibration, size: 22),
                    title: const Text('Haptic Feedback', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Vibrate on capture events', style: TextStyle(fontSize: 12)),
                    value: settings.hapticFeedback,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (v) => settings.setHapticFeedback(v),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: const Icon(Icons.speed, size: 22),
                    title: const Text('Barometer (Altitude)', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Record pressure sensor for elevation', style: TextStyle(fontSize: 12)),
                    value: settings.recordBarometer,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (v) => settings.setRecordBarometer(v),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(Icons.sensors, size: 22),
                    title: const Text('IMU Sample Rate', style: TextStyle(fontSize: 14)),
                    subtitle: Text('${settings.sensorRate}ms (${(1000 / settings.sensorRate).round()} Hz)', style: const TextStyle(fontSize: 12)),
                    trailing: DropdownButton<int>(
                      value: settings.sensorRate,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 20, child: Text('20ms (50Hz)')),
                        DropdownMenuItem(value: 50, child: Text('50ms (20Hz)')),
                        DropdownMenuItem(value: 100, child: Text('100ms (10Hz)')),
                      ],
                      onChanged: (v) { if (v != null) settings.setSensorRate(v); },
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(Icons.gps_fixed, size: 22),
                    title: const Text('GPS Poll Rate', style: TextStyle(fontSize: 14)),
                    subtitle: Text('Every ${settings.gpsRate}s', style: const TextStyle(fontSize: 12)),
                    trailing: DropdownButton<int>(
                      value: settings.gpsRate,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1s (fast)')),
                        DropdownMenuItem(value: 2, child: Text('2s (normal)')),
                        DropdownMenuItem(value: 5, child: Text('5s (battery)')),
                      ],
                      onChanged: (v) { if (v != null) settings.setGpsRate(v); },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── RIG GEOMETRY & NAMING ──────────────────
            _buildSectionHeader(context, 'Rig Layout & File Naming'),
            GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.text_fields, size: 22),
                    title: const Text('Naming Template', style: TextStyle(fontSize: 14)),
                    subtitle: Text(rig.namingTemplate, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () => _showNamingDialog(context, rig),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.view_in_ar, size: 22),
                    title: Text('Camera Positions (${rig.cameras.length})', style: const TextStyle(fontSize: 14)),
                    subtitle: const Text('Define rig offsets for each camera', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RigLayoutScreen())),
                  ),
                ],
              ),
            ),
            if (lidar.isAvailable) ...[
              GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(Icons.radar, size: 28, color: Theme.of(context).primaryColor),
                  title: const Text('LiDAR Scanner', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(lidar.isCapturing ? 'Capturing (${lidar.depthFrameCount} frames)' : 'Available — auto-captures with photos'),
                  trailing: Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 20),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildSectionHeader(context, settings.translate('cloud_storage')),
            _buildSettingCard(context,
              title: 'Backblaze B2',
              subtitle: cloud.isConfigured ? settings.translate('cloud_configured') : settings.translate('cloud_not_configured'),
              icon: Icons.cloud,
              onTap: () => showDialog(context: context, builder: (_) => const CloudStorageDialog()),
            ),
            GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                secondary: const Icon(Icons.cloud_upload, size: 22),
                title: const Text('Auto-Upload', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Upload to B2 after each session', style: TextStyle(fontSize: 12)),
                value: settings.autoUpload,
                activeColor: Theme.of(context).primaryColor,
                onChanged: cloud.isConfigured ? (v) => settings.setAutoUpload(v) : null,
              ),
            ),
            const SizedBox(height: 16),

            // ─── FUTURE: GS PROCESSING ──────────────────
            _buildSectionHeader(context, 'Gaussian Splat Processing'),
            GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const Icon(Icons.cloud_sync, size: 28),
                title: Text('Processing Server', style: TextStyle(fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3))),
                subtitle: Text('Coming soon — COLMAP / GS processing',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.2))),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('ROADMAP', style: TextStyle(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3), fontSize: 10, letterSpacing: 1)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── ABOUT ─────────────────────────────────
            _buildSectionHeader(context, 'About'),
            GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(Icons.info_outline, size: 22),
                    title: Text('KOSMOS 3D', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('v1.0.0 • Open Source (MIT)'),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.school, size: 22),
                    title: const Text('KIO Kreativ Institut', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Gaussian Splatting Rig Controller', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () {},
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(Icons.phone_iphone, size: 22),
                    title: Text('Supported Sensors', style: TextStyle(fontSize: 14)),
                    subtitle: Text('Accelerometer • Gyroscope • Magnetometer\nBarometer • GPS • Compass', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPresetDetail(BuildContext context, CameraPreset preset, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            Text(preset.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(preset.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: preset.settings.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                Text(e.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setDefaultSettings(preset.settings);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${preset.name} set as default'), backgroundColor: Theme.of(context).primaryColor),
              );
            },
            child: const Text('Set as Default'),
          ),
        ],
      ),
    );
  }

  void _showCreatePresetDialog(BuildContext context, SettingsProvider settings) {
    final nameCtrl = TextEditingController();
    String resolution = '4K', fps = '30', lens = 'Linear';
    String isoMax = '400', shutter = 'Auto', wb = '5500K', bitrate = 'High';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Create Preset', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Preset Name', labelStyle: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 12),
                _dropdownRow('Resolution', resolution, ['1080p', '2.7K', '4K', '5.3K'], (v) => setState(() => resolution = v)),
                _dropdownRow('FPS', fps, ['24', '30', '60', '120'], (v) => setState(() => fps = v)),
                _dropdownRow('Lens', lens, ['Linear', 'Wide', 'SuperView'], (v) => setState(() => lens = v)),
                _dropdownRow('ISO Max', isoMax, ['100', '200', '400', '800', '1600'], (v) => setState(() => isoMax = v)),
                _dropdownRow('Shutter', shutter, ['Auto', '1/60', '1/120', '1/240', '1/480'], (v) => setState(() => shutter = v)),
                _dropdownRow('White Balance', wb, ['Auto', '3200K', '4000K', '5500K', '6500K'], (v) => setState(() => wb = v)),
                _dropdownRow('Bitrate', bitrate, ['Standard', 'High'], (v) => setState(() => bitrate = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                settings.addCustomPreset(CameraPreset(
                  name: nameCtrl.text.trim(), icon: '⭐',
                  settings: {
                    'Resolution': resolution, 'FPS': fps, 'Lens': lens,
                    'ISO Max': isoMax, 'Shutter': shutter, 'White Balance': wb, 'Bitrate': bitrate,
                  },
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownRow(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value, dropdownColor: const Color(0xFF2E2E2E), isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (v) { if (v != null) onChanged(v); },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold,
      )),
    );
  }

  Widget _buildSettingCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showNamingDialog(BuildContext context, RigGeometryService rig) {
    final ctrl = TextEditingController(text: rig.namingTemplate);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('File Naming Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Template')),
            const SizedBox(height: 12),
            Text('Available variables:', style: TextStyle(color: Theme.of(ctx).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('{project} — Project name\n{camera} — Camera label\n{index} — Capture number (0001)\n{date} — Date (2026-04-30)\n{time} — Time (143025)',
                style: TextStyle(fontSize: 11, height: 1.6)),
            const SizedBox(height: 8),
            Text('Preview: ${rig.generateFileName(projectName: "MyScan", cameraLabel: "CAM1", index: 1)}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { rig.setNamingTemplate(ctrl.text.trim()); Navigator.pop(ctx); },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Screen for configuring camera rig positions
class RigLayoutScreen extends StatelessWidget {
  const RigLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rig = context.watch<RigGeometryService>();
    final goPro = context.watch<GoProService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rig Camera Layout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'Define each camera\'s position relative to the phone mount (center of rig).\n'
              'X = left/right, Y = up/down, Z = forward/back (meters).\n'
              'Rotation: yaw, pitch, roll (degrees).',
              style: TextStyle(fontSize: 12),
            ),
          ),
          // Auto-add connected cameras that aren't in rig yet
          if (goPro.devices.where((d) => d.isConnected).any((d) => !rig.cameras.any((c) => c.cameraId == d.id)))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Connected Cameras'),
                onPressed: () {
                  for (final cam in goPro.devices.where((d) => d.isConnected)) {
                    rig.addCamera(cam.id, cam.name);
                  }
                },
              ),
            ),
          ...rig.cameras.map((cam) => GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: const Icon(Icons.videocam),
              title: Text(cam.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Offset: (${cam.offsetX}, ${cam.offsetY}, ${cam.offsetZ})m', style: const TextStyle(fontSize: 11)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _offsetRow(context, 'Label', cam.label, (v) => rig.updateCamera(cam.cameraId, label: v)),
                      _numRow(context, 'X (left/right)', cam.offsetX, (v) => rig.updateCamera(cam.cameraId, x: v)),
                      _numRow(context, 'Y (up/down)', cam.offsetY, (v) => rig.updateCamera(cam.cameraId, y: v)),
                      _numRow(context, 'Z (fwd/back)', cam.offsetZ, (v) => rig.updateCamera(cam.cameraId, z: v)),
                      _numRow(context, 'Yaw°', cam.rotYaw, (v) => rig.updateCamera(cam.cameraId, yaw: v)),
                      _numRow(context, 'Pitch°', cam.rotPitch, (v) => rig.updateCamera(cam.cameraId, pitch: v)),
                      _numRow(context, 'Roll°', cam.rotRoll, (v) => rig.updateCamera(cam.cameraId, roll: v)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                        label: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        onPressed: () => rig.removeCamera(cam.cameraId),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _offsetRow(BuildContext context, String label, String value, ValueChanged<String> onChanged) {
    final ctrl = TextEditingController(text: value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(child: TextField(
            controller: ctrl, style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
            onSubmitted: onChanged,
          )),
        ],
      ),
    );
  }

  Widget _numRow(BuildContext context, String label, double value, ValueChanged<double> onChanged) {
    final ctrl = TextEditingController(text: value.toStringAsFixed(3));
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(child: TextField(
            controller: ctrl, style: const TextStyle(fontSize: 13),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
            onSubmitted: (v) { final d = double.tryParse(v); if (d != null) onChanged(d); },
          )),
        ],
      ),
    );
  }
}

// ─── CLOUD STORAGE DIALOG ───────────────────────────────────

class CloudStorageDialog extends StatefulWidget {
  const CloudStorageDialog({super.key});

  @override
  State<CloudStorageDialog> createState() => _CloudStorageDialogState();
}

class _CloudStorageDialogState extends State<CloudStorageDialog> {
  final _keyIdCtrl = TextEditingController();
  final _appKeyCtrl = TextEditingController();
  final _bucketCtrl = TextEditingController();
  final _endpointCtrl = TextEditingController(text: 's3.eu-central-003.backblazeb2.com');
  final _regionCtrl = TextEditingController(text: 'eu-central-003');
  bool _obscureKey = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadCreds();
  }

  Future<void> _loadCreds() async {
    final cloud = context.read<CloudStorageService>();
    final creds = await cloud.getDisplayCredentials();
    setState(() {
      _keyIdCtrl.text = creds['keyId'] ?? '';
      _bucketCtrl.text = creds['bucketName'] ?? '';
      _endpointCtrl.text = creds['endpoint'] ?? 's3.eu-central-003.backblazeb2.com';
      _regionCtrl.text = creds['region'] ?? 'eu-central-003';
    });
  }

  Future<void> _testConnection() async {
    setState(() { _isTesting = true; _testResult = null; });
    final cloud = context.read<CloudStorageService>();
    await cloud.saveCredentials(
      keyId: _keyIdCtrl.text.trim(),
      applicationKey: _appKeyCtrl.text.trim(),
      bucketName: _bucketCtrl.text.trim(),
      endpoint: _endpointCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
    );
    final ok = await cloud.testConnection();
    setState(() {
      _isTesting = false;
      _testResult = ok ? '✅ Connection successful!' : '❌ ${cloud.lastError ?? "Failed"}';
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final cloud = context.read<CloudStorageService>();
    await cloud.saveCredentials(
      keyId: _keyIdCtrl.text.trim(),
      applicationKey: _appKeyCtrl.text.trim(),
      bucketName: _bucketCtrl.text.trim(),
      endpoint: _endpointCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
    );
    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Cloud storage configured'), backgroundColor: Theme.of(context).primaryColor),
      );
    }
  }

  @override
  void dispose() {
    _keyIdCtrl.dispose(); _appKeyCtrl.dispose(); _bucketCtrl.dispose();
    _endpointCtrl.dispose(); _regionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('☁️ Backblaze B2 Cloud Storage', style: TextStyle(color: Colors.white, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your B2 Application Key credentials.\nUse a restricted key, not the master key!',
                style: TextStyle(color: Colors.orange, fontSize: 12)),
            const SizedBox(height: 16),
            _field('Key ID', _keyIdCtrl, Icons.key),
            const SizedBox(height: 10),
            _field('Application Key', _appKeyCtrl, Icons.lock, obscure: _obscureKey,
              suffix: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            const SizedBox(height: 10),
            _field('Bucket Name', _bucketCtrl, Icons.folder),
            const SizedBox(height: 10),
            _field('S3 Endpoint', _endpointCtrl, Icons.language),
            const SizedBox(height: 10),
            _field('Region', _regionCtrl, Icons.map),
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Text(_testResult!, style: TextStyle(
                color: _testResult!.startsWith('✅') ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
              )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: _isTesting ? null : _testConnection,
          child: _isTesting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Test'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: ctrl, obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor), borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}



