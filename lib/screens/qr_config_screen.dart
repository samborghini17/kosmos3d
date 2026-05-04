import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/gopro_service.dart';

/// QR Code camera configuration: generate QR codes to quickly
/// share camera settings across devices.
class QrConfigScreen extends StatelessWidget {
  const QrConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(settings.translate('qr_config'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(settings.translate('qr_config_desc'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.qr_code,
                        title: settings.translate('generate_qr'),
                        subtitle: settings.translate('generate_qr_desc'),
                        onTap: () => _showGenerateQr(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.content_paste,
                        title: 'Paste Config',
                        subtitle: 'Import settings from clipboard',
                        onTap: () => _pasteConfig(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGenerateQr(BuildContext context) {
    final goPro = context.read<GoProService>();
    final connectedCams = goPro.devices.where((d) => d.isConnected).toList();

    Map<String, String> settingsToEncode;
    if (connectedCams.isNotEmpty) {
      settingsToEncode = connectedCams.first.currentSettings;
    } else {
      settingsToEncode = {
        'Resolution': '4K', 'FPS': '30', 'Lens': 'Linear',
        'ISO Max': '400', 'Shutter': 'Auto', 'White Balance': '5500K', 'Bitrate': 'High',
      };
    }

    final qrData = jsonEncode({'kosmos3d': '1.0', 'settings': settingsToEncode});

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardTheme.color,
        title: const Text('📱 Camera Settings QR', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => _FullScreenQr(data: qrData, settings: settingsToEncode),
              )),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(data: qrData, version: QrVersions.auto, size: 260),
              ),
            ),
            const SizedBox(height: 8),
            Text('Tap QR to view fullscreen',
                style: TextStyle(color: Theme.of(ctx).primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Scan from another phone to apply settings',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color?.withValues(alpha: 0.5), fontSize: 11)),
            const SizedBox(height: 8),
            ...settingsToEncode.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color?.withValues(alpha: 0.4), fontSize: 11)),
                  Text(e.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy to clipboard'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: qrData));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Settings JSON copied!'), backgroundColor: Colors.green),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _pasteConfig(BuildContext context) async {
    final goPro = context.read<GoProService>();
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null || data!.text!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clipboard is empty'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      final parsed = jsonDecode(data.text!);
      if (parsed['kosmos3d'] != null && parsed['settings'] != null) {
        final settings = Map<String, String>.from(parsed['settings'] as Map);

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('✅ Settings Found!', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: settings.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await goPro.applySettingsToAll(settings);
                    for (final cam in goPro.devices.where((d) => d.isConnected)) {
                      goPro.updateCameraSettings(cam.id, settings);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Applied to ${goPro.devices.where((d) => d.isConnected).length} cameras'),
                            backgroundColor: Colors.green),
                      );
                    }
                  },
                  child: const Text('Apply to All Cameras'),
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid settings format'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: primary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen QR view for easy scanning
class _FullScreenQr extends StatelessWidget {
  final String data;
  final Map<String, String> settings;

  const _FullScreenQr({required this.data, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Scan this QR', style: TextStyle(color: Colors.black87)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              QrImageView(data: data, version: QrVersions.auto, size: MediaQuery.of(context).size.width * 0.85),
              const SizedBox(height: 24),
              const Text('KOSMOS 3D Camera Settings',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...settings.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(color: Colors.black45, fontSize: 14)),
                    Text(e.value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              const Text('Scan with any QR reader app\nor share screenshot to another device',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
