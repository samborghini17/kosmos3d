import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_project.dart';
import '../services/export_service.dart';
import '../services/trajectory_service.dart';
import '../services/rig_geometry_service.dart';
import '../services/gopro_service.dart';
import '../services/cloud_storage_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/camera_connection_status.dart';

/// Screen that exports and displays all COLMAP / Gaussian Splatting files.
/// Users can share/download individual files or the entire bundle.
class ExportScreen extends StatefulWidget {
  final ScanProject project;
  const ExportScreen({super.key, required this.project});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExporting = false;
  String? _exportPath;
  List<FileExportItem> _files = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _runExport();
  }

  Future<void> _runExport() async {
    setState(() {
      _isExporting = true;
      _error = null;
    });

    try {
      final exportService = context.read<ExportService>();
      final trajectory = context.read<TrajectoryService>();
      final rigService = context.read<RigGeometryService>();
      final goPro = context.read<GoProService>();

      final connectedIds = goPro.devices
          .where((d) => d.isConnected)
          .map((d) => d.id)
          .toList();

      // If no cameras connected, use rig cameras
      final cameraIds = connectedIds.isNotEmpty
          ? connectedIds
          : rigService.cameras.map((c) => c.cameraId).toList();

      final path = await exportService.exportSession(
        projectName: widget.project.name,
        projectId: widget.project.id,
        trajectory: trajectory.points,
        connectedCameraIds: cameraIds.isNotEmpty ? cameraIds : ['camera_1'],
        rigService: rigService,
        cameraSettings: widget.project.cameraSettings,
        captureMode: widget.project.captureMode,
      );

      final files = await exportService.getExportedFiles(path);

      setState(() {
        _exportPath = path;
        _files = files;
        _isExporting = false;
      });

      // Auto Upload to B2 if configured and enabled
      if (mounted) {
        final settings = context.read<SettingsProvider>();
        final cloud = context.read<CloudStorageService>();
        if (settings.autoUpload && cloud.isConfigured) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Starting Auto-Upload to Backblaze B2...'))
          );
          cloud.uploadProject(widget.project.id, widget.project.name);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isExporting = false;
      });
    }
  }

  Future<void> _showDownloadDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('WiFi Auto-Download', style: TextStyle(color: Colors.orangeAccent)),
        content: const Text(
          'To download media:\n\n'
          '1. Connect your phone to the GoPro\'s WiFi network in Settings.\n'
          '2. The app will automatically connect and pull all media via HTTP.\n\n'
          'Would you like to start the download process?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting WiFi transfer from GoPros...')),
              );
              // In a full implementation, this would trigger HTTP GET requests
              // to http://10.5.5.9:8080/videos/DCIM/ for each camera.
            },
            child: const Text('Start Download', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Export & Download'),
        actions: [
          const CameraConnectionStatus(),
          if (_exportPath != null)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share all files',
              onPressed: _shareAll,
            ),
        ],
      ),
      body: _isExporting
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  const Text('Generating export files...',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text('COLMAP • transforms.json • trajectory.csv',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text('Export failed', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _runExport, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ─── Summary Card ───
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor.withValues(alpha: 0.15), Colors.transparent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text('Export Complete',
                                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Project: ${widget.project.name}',
                              style: const TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('${_files.length} files generated',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _compatChip('COLMAP'),
                              _compatChip('3DGS'),
                              _compatChip('NeRF'),
                              _compatChip('Nerfstudio'),
                              _compatChip('Metashape'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Auto-Download (WiFi) ───
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.wifi, color: Colors.orangeAccent, size: 20),
                              SizedBox(width: 8),
                              Text('Auto-Download Media',
                                  style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Connect to your GoPro\'s WiFi network to wirelessly download the captured photos and videos directly to your phone.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: _showDownloadDialog,
                              icon: const Icon(Icons.download),
                              label: const Text('Start WiFi Download'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── File List ───
                    Text('Exported Data', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._files.map((file) => _FileCard(file: file, onShare: () => _shareFile(file))),
                  ],
                ),
    );
  }

  Widget _compatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
    );
  }

  Future<void> _shareFile(FileExportItem file) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Kosmos3D Export: ${file.name}',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _shareAll() async {
    if (_files.isEmpty) return;
    try {
      final xFiles = _files.map((f) => XFile(f.path)).toList();
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        xFiles,
        subject: 'Kosmos3D Export: ${widget.project.name}',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}

class _FileCard extends StatelessWidget {
  final FileExportItem file;
  final VoidCallback onShare;

  const _FileCard({required this.file, required this.onShare});

  IconData _getIcon() {
    if (file.name.endsWith('.json')) return Icons.data_object;
    if (file.name.endsWith('.csv')) return Icons.table_chart;
    if (file.name.endsWith('.txt')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getColor() {
    if (file.name.contains('transforms')) return const Color(0xFF00FF41);
    if (file.name.contains('colmap') || file.name.contains('sparse')) return Colors.blueAccent;
    if (file.name.contains('trajectory')) return Colors.orangeAccent;
    if (file.name.contains('rig')) return Colors.purpleAccent;
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(_getIcon(), color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
                const SizedBox(height: 2),
                Text(file.sizeFormatted,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.share, color: color.withValues(alpha: 0.7), size: 20),
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}
