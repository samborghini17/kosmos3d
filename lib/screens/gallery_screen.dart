import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/scan_project.dart';
import '../services/upload_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/trajectory_service.dart';
import '../providers/settings_provider.dart';

/// Gallery screen for viewing captured images and managing project media.
class GalleryScreen extends StatefulWidget {
  final ScanProject project;

  const GalleryScreen({super.key, required this.project});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> _imageFiles = [];
  bool _isLoading = true;
  bool _selectMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final capturesDir = Directory('${appDir.path}/kosmos3d_projects/${widget.project.id}/captures');

      if (await capturesDir.exists()) {
        final files = capturesDir.listSync()
            .whereType<File>()
            .where((f) {
              final ext = f.path.split('.').last.toLowerCase();
              return ['jpg', 'jpeg', 'png', 'mp4', 'gpr'].contains(ext);
            })
            .toList();
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        _imageFiles = files;
      }
    } catch (e) {
      debugPrint("Error loading images: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Selected?', style: TextStyle(color: Colors.white)),
        content: Text('Delete ${_selectedIndices.length} file(s)?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final idx in _selectedIndices.toList().reversed) {
        await _imageFiles[idx].delete();
      }
      _selectedIndices.clear();
      _selectMode = false;
      await _loadImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final uploadService = context.watch<UploadService>();
    final cloud = context.watch<CloudStorageService>();
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          if (_selectMode) ...[
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _selectedIndices.isEmpty ? null : _deleteSelected,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selectMode = false;
                _selectedIndices.clear();
              }),
            ),
          ] else ...[
            // Upload to B2
            if (cloud.isConfigured)
              IconButton(
                icon: const Icon(Icons.cloud),
                tooltip: 'Upload to B2',
                onPressed: _imageFiles.isEmpty
                    ? null
                    : () => _showB2UploadDialog(context, cloud),
              ),
            // Upload to server
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              tooltip: 'Upload to server',
              onPressed: _imageFiles.isEmpty
                  ? null
                  : () => _showUploadDialog(context, uploadService),
            ),
            // Export trajectory
            IconButton(
              icon: const Icon(Icons.route),
              tooltip: 'Export trajectory',
              onPressed: () => _showTrajectoryExport(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadImages,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _imageFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 64, color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 16),
                      Text(
                        'No captures yet',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Images downloaded from GoPros will appear here',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Stats bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.white.withValues(alpha: 0.03),
                      child: Row(
                        children: [
                          Icon(Icons.photo, size: 16, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            '${_imageFiles.length} files',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            _formatTotalSize(),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          if (_selectMode) ...[
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedIndices.length} selected',
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Upload progress bar
                    if (uploadService.isUploading || cloud.isUploading) ...[
                      LinearProgressIndicator(
                        value: uploadService.isUploading ? uploadService.progress : cloud.progress,
                        color: primaryColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          uploadService.isUploading ? uploadService.statusMessage : cloud.statusMessage,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                    ],
                    // Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: _imageFiles.length,
                        itemBuilder: (context, index) {
                          final file = _imageFiles[index];
                          final isSelected = _selectedIndices.contains(index);
                          final ext = file.path.split('.').last.toLowerCase();
                          final isImage = ['jpg', 'jpeg', 'png'].contains(ext);

                          return GestureDetector(
                            onTap: () {
                              if (_selectMode) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIndices.remove(index);
                                  } else {
                                    _selectedIndices.add(index);
                                  }
                                });
                              } else if (isImage) {
                                _showImageViewer(context, file, index);
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                _selectMode = true;
                                _selectedIndices.add(index);
                              });
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: isImage
                                        ? Image.file(file, fit: BoxFit.cover, cacheWidth: 200)
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  ext == 'mp4' ? Icons.videocam : Icons.insert_drive_file,
                                                  color: Colors.white38,
                                                  size: 28,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '.$ext',
                                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                                // File name label
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      file.path.split('/').last,
                                      style: const TextStyle(color: Colors.white70, fontSize: 9),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                // Selection indicator
                                if (_selectMode)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? primaryColor : Colors.white.withValues(alpha: 0.3),
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 14, color: Colors.black)
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showImageViewer(BuildContext context, File file, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              file.path.split('/').last,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(file),
            ),
          ),
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context, UploadService uploadService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Upload Project', style: TextStyle(color: Colors.white)),
        content: Text(
          'Upload ${_imageFiles.length} files from "${widget.project.name}" to your configured server?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              uploadService.uploadProject(widget.project.id, widget.project.name);
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _showB2UploadDialog(BuildContext context, CloudStorageService cloud) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('☁️ Upload to Backblaze B2', style: TextStyle(color: Colors.white)),
        content: Text(
          'Upload ${_imageFiles.length} files + trajectory from "${widget.project.name}" to your B2 bucket?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              cloud.uploadProject(widget.project.id, widget.project.name);
            },
            child: const Text('Upload to B2'),
          ),
        ],
      ),
    );
  }

  void _showTrajectoryExport(BuildContext context) {
    final trajectoryService = context.read<TrajectoryService>();
    final points = trajectoryService.points;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Export Trajectory', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${points.length} trajectory points recorded.', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            if (points.isEmpty)
              const Text('No trajectory data available. Record some captures first.', style: TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          if (points.isNotEmpty) ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveTrajectory(trajectoryService, 'csv');
              },
              child: const Text('Export CSV'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveTrajectory(trajectoryService, 'json');
              },
              child: const Text('Export JSON'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveTrajectory(TrajectoryService service, String format) async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectDir = '${appDir.path}/kosmos3d_projects/${widget.project.id}';
    final content = format == 'csv' ? service.exportAsCsv() : service.exportAsJson();
    final file = File('$projectDir/trajectory.$format');
    await file.writeAsString(content);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trajectory exported to trajectory.$format'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatTotalSize() {
    int totalBytes = 0;
    for (final f in _imageFiles) {
      try {
        totalBytes += f.lengthSync();
      } catch (_) {}
    }
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024) return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
