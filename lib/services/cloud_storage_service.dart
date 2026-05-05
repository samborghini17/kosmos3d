import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Backblaze B2 S3-compatible cloud storage service.
/// Credentials are stored encrypted via flutter_secure_storage.
class CloudStorageService extends ChangeNotifier {
  static const _keyId = 'b2_key_id';
  static const _keySecret = 'b2_app_key';
  static const _keyBucket = 'b2_bucket_name';
  static const _keyEndpoint = 'b2_endpoint';
  static const _keyRegion = 'b2_region';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isUploading = false;
  double _progress = 0;
  String _statusMessage = '';
  String? _lastError;
  bool _isConfigured = false;

  // B2 Native API auth cache
  String? _authToken;
  String? _apiUrl;
  String? _uploadUrl;
  String? _uploadAuthToken;
  String? _bucketId;

  bool get isUploading => _isUploading;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String? get lastError => _lastError;
  bool get isConfigured => _isConfigured;

  CloudStorageService() {
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    final keyId = await _secureStorage.read(key: _keyId);
    final appKey = await _secureStorage.read(key: _keySecret);
    final bucket = await _secureStorage.read(key: _keyBucket);
    _isConfigured = keyId != null && keyId.isNotEmpty &&
                    appKey != null && appKey.isNotEmpty &&
                    bucket != null && bucket.isNotEmpty;
    notifyListeners();
  }

  Future<void> saveCredentials({
    required String keyId,
    required String applicationKey,
    required String bucketName,
    String endpoint = 's3.eu-central-003.backblazeb2.com',
    String region = 'eu-central-003',
  }) async {
    await _secureStorage.write(key: _keyId, value: keyId);
    if (applicationKey.isNotEmpty) {
      await _secureStorage.write(key: _keySecret, value: applicationKey);
    }
    await _secureStorage.write(key: _keyBucket, value: bucketName);
    await _secureStorage.write(key: _keyEndpoint, value: endpoint);
    await _secureStorage.write(key: _keyRegion, value: region);
    _authToken = null; // Clear cached auth
    _isConfigured = true;
    notifyListeners();
  }

  /// Load saved credentials for display (key ID and bucket only, not the secret)
  Future<Map<String, String>> getDisplayCredentials() async {
    return {
      'keyId': await _secureStorage.read(key: _keyId) ?? '',
      'bucketName': await _secureStorage.read(key: _keyBucket) ?? '',
      'endpoint': await _secureStorage.read(key: _keyEndpoint) ?? 's3.eu-central-003.backblazeb2.com',
      'region': await _secureStorage.read(key: _keyRegion) ?? 'eu-central-003',
    };
  }

  /// Clear all stored credentials
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _keyId);
    await _secureStorage.delete(key: _keySecret);
    await _secureStorage.delete(key: _keyBucket);
    await _secureStorage.delete(key: _keyEndpoint);
    await _secureStorage.delete(key: _keyRegion);
    _authToken = null;
    _apiUrl = null;
    _isConfigured = false;
    notifyListeners();
  }

  // ─── B2 NATIVE API ─────────────────────────────────────────

  /// Authorize with B2 Native API
  Future<bool> _authorizeAccount() async {
    try {
      final keyId = await _secureStorage.read(key: _keyId) ?? '';
      final appKey = await _secureStorage.read(key: _keySecret) ?? '';
      final credentials = base64Encode(utf8.encode('$keyId:$appKey'));

      final response = await http.get(
        Uri.parse('https://api.backblazeb2.com/b2api/v2/b2_authorize_account'),
        headers: {'Authorization': 'Basic $credentials'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['authorizationToken'];
        _apiUrl = data['apiUrl'];
        return true;
      }
      _lastError = 'Auth failed: ${response.statusCode} ${response.body}';
      return false;
    } catch (e) {
      _lastError = 'Auth error: $e';
      return false;
    }
  }

  /// Get bucket ID by name
  Future<String?> _getBucketId() async {
    if (_bucketId != null) return _bucketId;
    if (_authToken == null) {
      if (!await _authorizeAccount()) return null;
    }

    try {
      final keyId = await _secureStorage.read(key: _keyId) ?? '';
      final bucketName = await _secureStorage.read(key: _keyBucket) ?? '';
      final response = await http.post(
        Uri.parse('$_apiUrl/b2api/v2/b2_list_buckets'),
        headers: {'Authorization': _authToken!},
        body: jsonEncode({'accountId': keyId, 'bucketName': bucketName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final buckets = data['buckets'] as List;
        if (buckets.isNotEmpty) {
          _bucketId = buckets[0]['bucketId'];
          return _bucketId;
        }
      }
    } catch (e) {
      _lastError = 'Bucket lookup error: $e';
    }
    return null;
  }

  /// Get upload URL for the bucket
  Future<bool> _getUploadUrl() async {
    final bucketId = await _getBucketId();
    if (bucketId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/b2api/v2/b2_get_upload_url'),
        headers: {'Authorization': _authToken!},
        body: jsonEncode({'bucketId': bucketId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _uploadUrl = data['uploadUrl'];
        _uploadAuthToken = data['authorizationToken'];
        return true;
      }
    } catch (e) {
      _lastError = 'Upload URL error: $e';
    }
    return false;
  }

  /// Test the connection with stored credentials
  Future<bool> testConnection() async {
    _lastError = null;
    try {
      final authorized = await _authorizeAccount();
      if (!authorized) return false;
      final bucketId = await _getBucketId();
      if (bucketId == null) {
        _lastError = 'Bucket not found. Check your bucket name.';
        return false;
      }
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  /// Upload a single file to B2
  Future<bool> uploadFile(File file, {String? prefix}) async {
    if (!await _getUploadUrl()) {
      notifyListeners();
      return false;
    }

    final fileName = file.path.split(Platform.pathSeparator).last;
    final objectKey = prefix != null ? '$prefix/$fileName' : fileName;

    try {
      final bytes = await file.readAsBytes();
      final sha1Hash = sha1.convert(bytes).toString();

      // Determine content type
      String contentType = 'application/octet-stream';
      final ext = fileName.split('.').last.toLowerCase();
      if (['jpg', 'jpeg'].contains(ext)) contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      if (ext == 'mp4') contentType = 'video/mp4';
      if (ext == 'json') contentType = 'application/json';
      if (ext == 'csv') contentType = 'text/csv';

      final response = await http.post(
        Uri.parse(_uploadUrl!),
        headers: {
          'Authorization': _uploadAuthToken!,
          'X-Bz-File-Name': Uri.encodeComponent(objectKey),
          'Content-Type': contentType,
          'Content-Length': bytes.length.toString(),
          'X-Bz-Content-Sha1': sha1Hash,
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _lastError = 'Upload failed: ${response.statusCode}';
        // Refresh upload URL on 401/503
        if (response.statusCode == 401 || response.statusCode == 503) {
          _uploadUrl = null;
          _uploadAuthToken = null;
        }
        return false;
      }
    } catch (e) {
      _lastError = 'Upload error: $e';
      return false;
    }
  }

  /// Upload all files from a project directory to B2
  Future<bool> uploadProject(String projectId, String projectName) async {
    _isUploading = true;
    _progress = 0;
    _lastError = null;
    _statusMessage = 'Authenticating with Backblaze B2...';
    notifyListeners();

    final authorized = await _authorizeAccount();
    if (!authorized) {
      _isUploading = false;
      _statusMessage = 'Authentication failed';
      notifyListeners();
      return false;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final capturesDir = Directory('${appDir.path}/kosmos3d_projects/$projectId/captures');

    if (!await capturesDir.exists()) {
      _isUploading = false;
      _lastError = 'No captures directory found.';
      _statusMessage = 'No files to upload';
      notifyListeners();
      return false;
    }

    final files = capturesDir.listSync().whereType<File>().toList();
    if (files.isEmpty) {
      _isUploading = false;
      _lastError = 'No files to upload.';
      _statusMessage = 'Empty project';
      notifyListeners();
      return false;
    }

    // Also upload trajectory if it exists
    final trajectoryJson = File('${appDir.path}/kosmos3d_projects/$projectId/trajectory.json');
    final trajectoryCsv = File('${appDir.path}/kosmos3d_projects/$projectId/trajectory.csv');
    final allFiles = [...files];
    if (await trajectoryJson.exists()) allFiles.add(trajectoryJson);
    if (await trajectoryCsv.exists()) allFiles.add(trajectoryCsv);

    int uploaded = 0;
    int retries = 0;
    const maxRetries = 3;

    for (final file in allFiles) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      _statusMessage = 'Uploading ${uploaded + 1}/${allFiles.length}: $fileName';
      _progress = uploaded / allFiles.length;
      notifyListeners();

      bool success = await uploadFile(file, prefix: 'kosmos3d/$projectName');
      while (!success && retries < maxRetries) {
        retries++;
        await Future.delayed(Duration(seconds: retries * 2)); // Exponential backoff
        _statusMessage = 'Retrying ($retries/$maxRetries): $fileName';
        notifyListeners();
        success = await uploadFile(file, prefix: 'kosmos3d/$projectName');
      }

      if (!success) {
        _isUploading = false;
        _statusMessage = 'Upload failed at: $fileName';
        notifyListeners();
        return false;
      }
      uploaded++;
      retries = 0;
    }

    _isUploading = false;
    _progress = 1.0;
    _statusMessage = 'All $uploaded files uploaded to B2!';
    notifyListeners();
    return true;
  }
}
