
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_project.dart';

/// Service for managing scan projects on the local filesystem.
/// Each project is a directory containing a project.json metadata file
/// and a captures/ subdirectory for stored images.
class ProjectService extends ChangeNotifier {
  List<ScanProject> _projects = [];
  bool _isLoading = true;

  List<ScanProject> get projects => List.unmodifiable(_projects);
  bool get isLoading => _isLoading;

  ProjectService() {
    loadProjects();
  }

  Future<Directory> get _projectsRoot async {
    final appDir = await getApplicationDocumentsDirectory();
    final root = Directory('${appDir.path}/kosmos3d_projects');
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      final root = await _projectsRoot;
      final dirs = root.listSync().whereType<Directory>().toList();
      final loaded = <ScanProject>[];

      for (final dir in dirs) {
        final metaFile = File('${dir.path}/project.json');
        if (await metaFile.exists()) {
          try {
            final content = await metaFile.readAsString();
            loaded.add(ScanProject.fromJsonString(content));
          } catch (e) {
            debugPrint('Error loading project from ${dir.path}: $e');
          }
        }
      }

      // Sort by last modified descending
      loaded.sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
      _projects = loaded;
    } catch (e) {
      debugPrint('Error loading projects: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ScanProject> createProject(String name, {
    String captureMode = 'photo',
    bool smartCapture = false,
    Map<String, String>? cameraSettings,
  }) async {
    final root = await _projectsRoot;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    final project = ScanProject(
      id: id,
      name: name,
      createdAt: now,
      lastModifiedAt: now,
      captureMode: captureMode,
      smartCapture: smartCapture,
      cameraSettings: cameraSettings,
    );

    // Create project directory and captures subdirectory
    final projectDir = Directory('${root.path}/$id');
    await projectDir.create(recursive: true);
    final capturesDir = Directory('${projectDir.path}/captures');
    await capturesDir.create();

    // Write metadata
    final metaFile = File('${projectDir.path}/project.json');
    await metaFile.writeAsString(project.toJsonString());

    _projects.insert(0, project);
    notifyListeners();
    return project;
  }

  Future<void> updateProject(ScanProject project) async {
    final root = await _projectsRoot;
    project.lastModifiedAt = DateTime.now();
    final metaFile = File('${root.path}/${project.id}/project.json');
    await metaFile.writeAsString(project.toJsonString());

    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
    }
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    final root = await _projectsRoot;
    final projectDir = Directory('${root.path}/$id');
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }
    _projects.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<String> getProjectCapturesPath(String id) async {
    final root = await _projectsRoot;
    return '${root.path}/$id/captures';
  }

  Future<int> getCaptureCount(String id) async {
    final capturesPath = await getProjectCapturesPath(id);
    final capturesDir = Directory(capturesPath);
    if (!await capturesDir.exists()) return 0;
    return capturesDir.listSync().whereType<File>().length;
  }
}
