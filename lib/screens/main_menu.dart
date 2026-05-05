import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scan_project.dart';
import '../providers/settings_provider.dart';
import '../services/project_service.dart';
import '../services/gopro_service.dart';

import '../widgets/glass_card.dart';
import '../widgets/camera_connection_status.dart';
import 'settings.dart';
import 'project_flow.dart';
import 'capture_session.dart';
import 'gallery_screen.dart';
import 'point_cloud_preview.dart';
import 'qr_config_screen.dart';
import 'device_manager.dart';
import 'export_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final projectService = context.watch<ProjectService>();
    final goPro = context.watch<GoProService>();
    final connectedCount = goPro.devices.where((d) => d.isConnected).length;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.translate('app_title')),
        actions: [
          // Connected cameras badge
          if (connectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                avatar: Icon(Icons.camera_alt, size: 14, color: primary),
                label: Text('$connectedCount',
                    style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12)),
                backgroundColor: primary.withValues(alpha: 0.1),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          const CameraConnectionStatus(),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: settings.translate('settings'),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── QUICK TOOLS BAR ─────────────────────
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _quickTool(context, Icons.qr_code, settings.translate('qr_config'), () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const QrConfigScreen()))),
                    _quickTool(context, Icons.view_in_ar, settings.translate('trajectory_preview'), () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PointCloudPreviewScreen()))),
                    _quickTool(context, Icons.camera_alt, settings.translate('device_manager'), () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceManagerScreen()))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── PROJECT LIST ────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
                child: Text(
                  settings.translate('project_overview'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: projectService.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : projectService.projects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.view_in_ar, size: 64, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                Text(settings.translate('no_projects'),
                                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5), fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(settings.translate('create_first_project'),
                                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3), fontSize: 14)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => projectService.loadProjects(),
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                              itemCount: projectService.projects.length,
                              itemBuilder: (context, index) {
                                final project = projectService.projects[index];
                                return _buildProjectCard(context, project, settings, projectService);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProjectFlowScreen())),
        icon: const Icon(Icons.add),
        label: Text(settings.translate('new_project')),
      ),
    );
  }

  Widget _quickTool(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 88,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: primary),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 10),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ScanProject project, SettingsProvider settings, ProjectService projectService) {
    final timeAgo = _formatTimeAgo(project.lastModifiedAt, settings);
    final modeIcon = project.captureMode == 'video' ? Icons.videocam : Icons.photo_camera;

    return GlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(modeIcon, color: Theme.of(context).primaryColor, size: 28),
        ),
        title: Text(project.name,
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.camera, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text('${project.captureCount} captures',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(timeAgo, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 12)),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54)),
          onSelected: (value) async {
            if (value == 'open') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CaptureSessionScreen(project: project)));
            } else if (value == 'gallery') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryScreen(project: project)));
            } else if (value == '3d') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PointCloudPreviewScreen()));
            } else if (value == 'export') {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ExportScreen(project: project)));
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text('Delete Project?', style: TextStyle(color: Colors.white)),
                  content: Text('This will permanently delete "${project.name}" and all its capture data.',
                      style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
              if (confirmed == true) await projectService.deleteProject(project.id);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'open', child: Text('Open Session')),
            const PopupMenuItem(value: 'gallery', child: Text('Gallery')),
            const PopupMenuItem(value: '3d', child: Text('3D Preview')),
            const PopupMenuItem(value: 'export', child: Text('Export (COLMAP / 3DGS)')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
          ],
        ),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => CaptureSessionScreen(project: project))),
      ),
    );
  }

  String _formatTimeAgo(DateTime date, SettingsProvider settings) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}.${date.month}.${date.year}';
  }
}
