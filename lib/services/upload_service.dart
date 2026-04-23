import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// Service for uploading project data to a configured server.
/// Supports both individual file uploads and batch project uploads.
class UploadService extends ChangeNotifier {
  bool _isUploading = false;
  double _progress = 0;
  String _statusMessage = '';
  String? _lastError;

  bool get isUploading => _isUploading;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String? get lastError => _lastError;

  /// Load server config from SharedPreferences
  Future<Map<String, String>> _getServerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'url': prefs.getString('server_url') ?? '',
      'username': prefs.getString('server_username') ?? '',
      'password': prefs.getString('server_password') ?? '',
      'api_key': prefs.getString('server_api_key') ?? '',
    };
  }

  /// Check if server is configured
  Future<bool> isServerConfigured() async {
    final config = await _getServerConfig();
    return config['url']?.isNotEmpty == true;
  }

  /// Test server connection
  Future<bool> testConnection() async {
    final config = await _getServerConfig();
    if (config['url']?.isEmpty ?? true) return false;

    try {
      final response = await http.get(
        Uri.parse(config['url']!),
        headers: _buildHeaders(config),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Upload a single file to the server
  Future<bool> uploadFile(File file, {String? projectName}) async {
    final config = await _getServerConfig();
    if (config['url']?.isEmpty ?? true) {
      _lastError = 'No server configured. Go to Settings → Server Login.';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _progress = 0;
    _statusMessage = 'Uploading ${file.path.split('/').last}...';
    _lastError = null;
    notifyListeners();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${config['url']}/upload'),
      );

      request.headers.addAll(_buildHeaders(config));
      if (projectName != null) {
        request.fields['project'] = projectName;
      }

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _isUploading = false;
      _progress = 1.0;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _statusMessage = 'Upload complete!';
        notifyListeners();
        return true;
      } else {
        _lastError = 'Server returned ${response.statusCode}: ${response.body}';
        _statusMessage = 'Upload failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isUploading = false;
      _lastError = e.toString();
      _statusMessage = 'Upload failed';
      notifyListeners();
      return false;
    }
  }

  /// Upload all files from a project's captures directory
  Future<bool> uploadProject(String projectId, String projectName) async {
    final config = await _getServerConfig();
    if (config['url']?.isEmpty ?? true) {
      _lastError = 'No server configured.';
      notifyListeners();
      return false;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final capturesDir = Directory('${appDir.path}/kosmos3d_projects/$projectId/captures');

    if (!await capturesDir.exists()) {
      _lastError = 'No captures found for this project.';
      notifyListeners();
      return false;
    }

    final files = capturesDir.listSync().whereType<File>().toList();
    if (files.isEmpty) {
      _lastError = 'No files to upload.';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _progress = 0;
    _lastError = null;
    notifyListeners();

    int uploaded = 0;
    for (final file in files) {
      _statusMessage = 'Uploading ${uploaded + 1}/${files.length}: ${file.path.split('/').last}';
      _progress = uploaded / files.length;
      notifyListeners();

      final success = await _uploadSingleFile(file, config, projectName);
      if (!success) {
        _isUploading = false;
        notifyListeners();
        return false;
      }
      uploaded++;
    }

    _isUploading = false;
    _progress = 1.0;
    _statusMessage = 'All $uploaded files uploaded!';
    notifyListeners();
    return true;
  }

  Future<bool> _uploadSingleFile(File file, Map<String, String> config, String projectName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${config['url']}/upload'),
      );
      request.headers.addAll(_buildHeaders(config));
      request.fields['project'] = projectName;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      return streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300;
    } catch (e) {
      _lastError = 'Upload failed: $e';
      return false;
    }
  }

  /// Upload trajectory data
  Future<bool> uploadTrajectory(String projectId, String projectName, String trajectoryData, String format) async {
    final config = await _getServerConfig();
    if (config['url']?.isEmpty ?? true) {
      _lastError = 'No server configured.';
      notifyListeners();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('${config['url']}/trajectory'),
        headers: {
          ..._buildHeaders(config),
          'Content-Type': 'application/json',
        },
        body: trajectoryData,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Map<String, String> _buildHeaders(Map<String, String> config) {
    final headers = <String, String>{};
    if (config['api_key']?.isNotEmpty == true) {
      headers['Authorization'] = 'Bearer ${config['api_key']}';
    } else if (config['username']?.isNotEmpty == true) {
      final credentials = base64Encode(utf8.encode('${config['username']}:${config['password']}'));
      headers['Authorization'] = 'Basic $credentials';
    }
    return headers;
  }
}
