import '../l10n/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../services/gopro_service.dart';
import '../services/system_settings_service.dart';

class GoProMediaTransferDialog extends StatefulWidget {
  final String? projectCapturesPath;
  const GoProMediaTransferDialog({super.key, this.projectCapturesPath});
  static Future<void> show(
    BuildContext context, {
    String? projectCapturesPath,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) =>
        GoProMediaTransferDialog(projectCapturesPath: projectCapturesPath),
  );
  @override
  State<GoProMediaTransferDialog> createState() =>
      _GoProMediaTransferDialogState();
}

class _GoProMediaTransferDialogState extends State<GoProMediaTransferDialog> {
  bool _loading = false, _transferring = false, _gallery = true;
  double _progress = 0;
  String _status =
      'Join a camera’s Wi-Fi, then browse its files. Bluetooth controls the rig; Wi-Fi transfers originals.';
  List<GoProMediaItem> _items = [];
  final Set<int> _selected = {};
  Future<void> _credentials(String id) async {
    final service = context.read<GoProService>();
    try {
      final credentials = await service.readWifiCredentials(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const AppText('Camera Wi-Fi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                'SSID: ${credentials.ssid}\nPassword: ${credentials.password}',
              ),
              const SizedBox(height: 12),
              const AppText(
                'The app reads the camera password over Bluetooth. Removing Wi-Fi security is unnecessary.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: credentials.password)),
              child: const AppText('Copy password'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const AppText('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    }
  }

  Future<void> _importAll() async {
    if (_loading || _transferring) return;
    final service = context.read<GoProService>();
    setState(() {
      _transferring = true;
      _progress = 0;
    });
    try {
      final root = await getApplicationDocumentsDirectory();
      final target =
          widget.projectCapturesPath ?? '${root.path}/kosmos3d_downloads';
      final report = await service.importAllConnectedCameras(
        target,
        saveToGallery: _gallery,
        onStatus: (message) {
          if (mounted) {
            setState(() {
              _status = message;
              _progress = service.syncProgress;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _progress = report.complete ? 1 : _progress;
          _status =
              '${report.complete ? 'Import complete' : 'Import needs attention'}: ${report.imported} local files.\n'
              '${report.cameras.map((c) => '${c.cameraName}: ${c.imported}/${c.found}${c.error == null ? '' : ' — ${c.error}'}').join('\n')}\n'
              'Gallery exports needing attention: ${service.galleryFailures.length}.\n'
              'Stored in: ${report.destination}\nCamera SD cards are unchanged. App files are removed if the app is uninstalled; export or upload a copy.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  Future<void> _fetch() async {
    if (_loading || _transferring) return;
    final service = context.read<GoProService>();
    setState(() {
      _loading = true;
      _status = 'Finding cameras and reading SD cards…';
    });
    try {
      if (service.capture.active || service.capture.busy) {
        throw StateError('Stop capture before importing.');
      }
      final items = await service.fetchAllMediaItemsFromAllCameras();
      if (!mounted) return;
      setState(() {
        _items = items;
        _selected.clear();
        _selected.addAll(List.generate(items.length, (i) => i));
        _status = items.isEmpty
            ? 'No readable media found. Connect a camera by Bluetooth and join its Wi-Fi.'
            : '${items.length} files available. Select the originals to import.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _transfer() async {
    if (_transferring || _selected.isEmpty) return;
    final service = context.read<GoProService>();
    final items = _selected.map((i) => _items[i]).toList();
    setState(() {
      _transferring = true;
      _progress = 0;
    });
    try {
      final documents = await getApplicationDocumentsDirectory();
      final target =
          widget.projectCapturesPath ?? '${documents.path}/kosmos3d_downloads';
      final count = await service.transferMediaItems(
        items,
        targetCapturesDirectory: target,
        saveToNativeGallery: _gallery,
        onProgress: (current, total, fraction, status) {
          if (mounted) {
            setState(() {
              _progress = (current - 1 + fraction) / total;
              _status = status;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _progress = count == items.length ? 1 : _progress;
          _status =
              '$count of ${items.length} originals available locally. '
              '${count == items.length ? 'Import complete.' : 'Retry to fetch missing files.'}'
              '${_gallery ? ' Gallery export is attempted for supported photos and videos.' : ''}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Import stopped: $e');
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _transferring;
    final cameras = context
        .watch<GoProService>()
        .devices
        .where((c) => c.isConnected)
        .toList();
    return PopScope(
      canPop: !busy,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.83,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        'Import originals',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close import',
                      onPressed: busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: SingleChildScrollView(
                    child: AppText(
                      _status,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (_transferring)
                  TextButton(
                    onPressed: context.read<GoProService>().cancelImport,
                    child: const AppText('Cancel import'),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: busy || cameras.isEmpty ? null : _importAll,
                  icon: const Icon(Icons.download_for_offline),
                  label: AppText(
                    'Import all files from ${cameras.length} cameras',
                  ),
                ),
                const AppText(
                  'Cameras transfer one at a time. Approve each Wi-Fi connection when asked.',
                ),
                if (cameras.isNotEmpty)
                  Wrap(
                    children: cameras
                        .map(
                          (camera) => TextButton.icon(
                            onPressed: busy
                                ? null
                                : () => _credentials(camera.id),
                            icon: const Icon(Icons.key),
                            label: AppText('${camera.name} Wi-Fi'),
                          ),
                        )
                        .toList(),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () async {
                                try {
                                  await SystemSettingsService.openWifiSettings();
                                } catch (e) {
                                  if (mounted) setState(() => _status = '$e');
                                }
                              },
                        icon: const Icon(Icons.wifi),
                        label: const AppText('Wi-Fi settings'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy ? null : _fetch,
                        child: const AppText('Browse files'),
                      ),
                    ),
                  ],
                ),
                if (busy)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: LinearProgressIndicator(
                      value: _loading ? null : _progress,
                    ),
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const AppText('Also copy to Photos / Gallery'),
                  subtitle: const AppText(
                    'Originals always remain in the app.',
                  ),
                  value: _gallery,
                  onChanged: busy ? null : (v) => setState(() => _gallery = v!),
                ),
                if (_items.isNotEmpty)
                  Row(
                    children: [
                      AppText('${_selected.length} selected'),
                      const Spacer(),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                if (_selected.length == _items.length) {
                                  _selected.clear();
                                } else {
                                  _selected.addAll(
                                    List.generate(_items.length, (i) => i),
                                  );
                                }
                              }),
                        child: AppText(
                          _selected.length == _items.length
                              ? 'Deselect all'
                              : 'Select all',
                        ),
                      ),
                    ],
                  ),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(
                          child: Icon(Icons.sd_storage_outlined, size: 48),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final item = _items[i];
                            return CheckboxListTile(
                              value: _selected.contains(i),
                              onChanged: busy
                                  ? null
                                  : (v) => setState(() {
                                      if (v!) {
                                        _selected.add(i);
                                      } else {
                                        _selected.remove(i);
                                      }
                                    }),
                              title: AppText(
                                item.filename,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: AppText(
                                '${item.cameraName} · ${item.formattedSize}',
                              ),
                              secondary: Icon(
                                item.isVideo
                                    ? Icons.videocam_outlined
                                    : Icons.image_outlined,
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy || _selected.isEmpty ? null : _transfer,
                    icon: const Icon(Icons.download),
                    label: AppText('Import ${_selected.length} files'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
