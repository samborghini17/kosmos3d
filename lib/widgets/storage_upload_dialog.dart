import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_text.dart';
import '../services/cloud_storage_service.dart';

/// Confirms, runs and reports a project upload to the configured storage server.
Future<void> showStorageUploadDialog(
  BuildContext context, {
  required String projectId,
  required String projectName,
  bool confirm = true,
}) async {
  final cloud = context.read<CloudStorageService>();
  if (confirm) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AppText('Upload to storage server'),
        content: AppText(
          'Upload every file of "$projectName" (originals, receipts, sensor logs, LiDAR) to your storage server? Files already uploaded are skipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AppText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const AppText('Upload'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }
  final run = cloud.uploadProject(projectId, projectName);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ChangeNotifierProvider.value(
      value: cloud,
      child: Consumer<CloudStorageService>(
        builder: (ctx, c, _) => AlertDialog(
          title: AppText(
            c.isUploading
                ? 'Uploading…'
                : c.lastError == null
                ? 'Upload complete'
                : 'Upload needs attention',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: c.progress),
              const SizedBox(height: 12),
              AppText(c.statusMessage),
              if (!c.isUploading && c.lastError != null) ...[
                const SizedBox(height: 8),
                AppText(
                  c.lastError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
          actions: [
            if (c.isUploading)
              TextButton(
                onPressed: c.cancelUpload,
                child: const AppText('Cancel'),
              )
            else
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const AppText('Done'),
              ),
          ],
        ),
      ),
    ),
  );
  await run;
}
