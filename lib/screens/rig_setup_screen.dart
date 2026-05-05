import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rig_geometry_service.dart';
import '../services/gopro_service.dart';
import '../providers/settings_provider.dart';

/// Screen for configuring the physical position and rotation of each GoPro
/// on the rig, relative to the phone mount point.
class RigSetupScreen extends StatelessWidget {
  const RigSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rigService = context.watch<RigGeometryService>();
    final goPro = context.watch<GoProService>();
    final settings = context.watch<SettingsProvider>();
    final primaryColor = Theme.of(context).primaryColor;
    final connectedCams = goPro.devices.where((d) => d.isConnected).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.translate('camera_rig')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Auto-add connected cameras',
            onPressed: () {
              for (final cam in connectedCams) {
                rigService.addCamera(cam.id, cam.displayName);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${connectedCams.length} cameras to rig'),
                  backgroundColor: primaryColor,
                ),
              );
            },
          ),
        ],
      ),
      body: rigService.cameras.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_in_ar, size: 64, color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 16),
                  Text('No cameras in rig layout',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Connect cameras and tap + to add them',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
                  if (connectedCams.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        for (final cam in connectedCams) {
                          rigService.addCamera(cam.id, cam.displayName);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text('Add ${connectedCams.length} connected cameras'),
                    ),
                  ],
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Naming Template ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('File Naming Template',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: rigService.namingTemplate,
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '{project}_{camera}_{index}',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          helperText: 'Variables: {project} {camera} {index} {date} {time}',
                          helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onFieldSubmitted: (val) => rigService.setNamingTemplate(val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Camera Cards ───
                ...rigService.cameras.map((cam) => _CameraRigCard(camera: cam)),
              ],
            ),
    );
  }
}

class _CameraRigCard extends StatelessWidget {
  final RigCamera camera;
  const _CameraRigCard({required this.camera});

  @override
  Widget build(BuildContext context) {
    final rigService = context.read<RigGeometryService>();
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.camera_alt, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(camera.label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => rigService.removeCamera(camera.cameraId),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('ID: ${camera.cameraId}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11, fontFamily: 'monospace')),
          const SizedBox(height: 12),

          // ─── Position Offsets ───
          Text('Position (meters from phone mount)',
              style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _OffsetField(label: 'X (left/right)', value: camera.offsetX, unit: 'm',
                  onChanged: (v) => rigService.updateCamera(camera.cameraId, x: v)),
              const SizedBox(width: 8),
              _OffsetField(label: 'Y (up/down)', value: camera.offsetY, unit: 'm',
                  onChanged: (v) => rigService.updateCamera(camera.cameraId, y: v)),
              const SizedBox(width: 8),
              _OffsetField(label: 'Z (forward)', value: camera.offsetZ, unit: 'm',
                  onChanged: (v) => rigService.updateCamera(camera.cameraId, z: v)),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Rotation Offsets ───
          Text('Rotation (degrees relative to phone)',
              style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _OffsetField(label: 'Yaw', value: camera.rotYaw, unit: '°',
                  onChanged: (v) => rigService.updateCamera(camera.cameraId, yaw: v)),
              const SizedBox(width: 8),
              _OffsetField(label: 'Pitch', value: camera.rotPitch, unit: '°',
                  onChanged: (v) => rigService.updateCamera(camera.cameraId, pitch: v)),
              const SizedBox(width: 8),
              _OffsetField(label: 'Roll', value: camera.rotRoll, unit: '°',
                  onChanged: (v) => rigService.updateCamera(camera.cameraId, roll: v)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OffsetField extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final ValueChanged<double> onChanged;

  const _OffsetField({
    required this.label,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextFormField(
              initialValue: value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: InputBorder.none,
                suffixText: unit,
                suffixStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
              ),
              onFieldSubmitted: (val) {
                final parsed = double.tryParse(val);
                if (parsed != null) onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
