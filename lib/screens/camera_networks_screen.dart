import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../l10n/app_text.dart';
import '../models/camera_device.dart';
import '../services/gopro_service.dart';
import '../services/system_settings_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gopro_media_transfer_dialog.dart';

/// Standard Wi-Fi QR payload understood by the iOS and Android camera apps.
String wifiQrPayload(String ssid, String password) {
  String esc(String v) =>
      v.replaceAllMapped(RegExp(r'([\\;,":])'), (m) => '\\${m[1]}');
  return 'WIFI:T:WPA;S:${esc(ssid)};P:${esc(password)};;';
}

/// Every connected camera's Wi-Fi in one place: name, password, a QR the
/// phone camera can scan to join, and one-tap join.
class CameraNetworksScreen extends StatefulWidget {
  const CameraNetworksScreen({super.key});

  @override
  State<CameraNetworksScreen> createState() => _CameraNetworksScreenState();
}

class _CameraNetworksScreenState extends State<CameraNetworksScreen> {
  final Map<String, ({String ssid, String password})> _credentials = {};
  final Map<String, String> _errors = {};
  final Set<String> _visible = {};
  String? _joining;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _readAll());
  }

  Future<void> _readAll() async {
    if (_loading) return;
    final service = context.read<GoProService>();
    setState(() => _loading = true);
    for (final camera in service.devices.where((d) => d.isConnected)) {
      try {
        _credentials[camera.id] = await service.readWifiCredentials(camera.id);
        _errors.remove(camera.id);
      } catch (e) {
        _errors[camera.id] = '$e';
      }
      if (mounted) setState(() {});
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _join(CameraDevice camera) async {
    final service = context.read<GoProService>();
    setState(() => _joining = camera.id);
    try {
      await service.joinCameraWifi(camera.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            '{name} Wi-Fi joined'.replaceAll('{name}', camera.name),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AppText('$e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _joining = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GoProService>();
    final cameras = service.devices.where((d) => d.isConnected).toList();
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.65);
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Camera networks'),
        actions: [
          IconButton(
            tooltip: 'Read again',
            onPressed: _loading ? null : _readAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Download from every camera',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                AppText(
                  'The phone joins each camera Wi-Fi in turn, copies all originals into the project and moves on. Passwords are read over Bluetooth, so you never type them.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: cameras.isEmpty || service.isSyncingMedia
                      ? null
                      : () => GoProMediaTransferDialog.show(context),
                  icon: const Icon(Icons.download),
                  label: AppText(
                    cameras.length == 1
                        ? 'Import all files from 1 camera'
                        : 'Import all files from ${cameras.length} cameras',
                  ),
                ),
                const SizedBox(height: 12),
                AppText(
                  Platform.isIOS
                      ? 'iPhone: confirm the "Join network" prompt once per camera. Turn Personal Hotspot off while importing.'
                      : 'Android: confirm the connection prompt once per camera. Mobile data stays available for the rest of the phone.',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (cameras.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppText(
                'Connect GoPros over Bluetooth first',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            ),
          for (final camera in cameras) _cameraCard(camera, muted),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const AppText('Why not the phone hotspot?'),
            children: [
              AppText(
                'HERO12 and HERO13 can join a phone hotspot (Camera on Home Network, COHN). Then all cameras are reachable at the same time and can download in parallel. This needs per-camera certificate setup over Bluetooth and is planned for a later version. HERO11 and older only offer their own Wi-Fi, which is what this screen uses.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: SystemSettingsService.openWifiSettings,
                  icon: const Icon(Icons.wifi, size: 16),
                  label: const AppText('Open Wi-Fi settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cameraCard(CameraDevice camera, Color muted) {
    final credentials = _credentials[camera.id];
    final error = _errors[camera.id];
    final visible = _visible.contains(camera.id);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                camera.isWifiConnected ? Icons.wifi : Icons.wifi_off,
                color: camera.isWifiConnected
                    ? Theme.of(context).primaryColor
                    : muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  camera.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (_joining == camera.id)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: credentials == null || _joining != null
                      ? null
                      : () => _join(camera),
                  child: const AppText('Join'),
                ),
            ],
          ),
          if (error != null)
            AppText(
              error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            )
          else if (credentials == null)
            const LinearProgressIndicator()
          else ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Network',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                      SelectableText(
                        credentials.ssid,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        'Password',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: SelectableText(
                              visible
                                  ? credentials.password
                                  : '•' * credentials.password.length,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              visible ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () => setState(
                              () => visible
                                  ? _visible.remove(camera.id)
                                  : _visible.add(camera.id),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Copy password',
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () => Clipboard.setData(
                              ClipboardData(text: credentials.password),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (visible)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(6),
                    child: QrImageView(
                      data: wifiQrPayload(
                        credentials.ssid,
                        credentials.password,
                      ),
                      size: 112,
                    ),
                  ),
              ],
            ),
            if (visible)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppText(
                  'Scan the QR with another phone or laptop camera to join this GoPro directly.',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
