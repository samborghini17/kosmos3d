import 'dart:convert';

class ScanProject {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime lastModifiedAt;
  String captureMode; // 'photo', 'video', 'burst'
  bool smartCapture;
  int captureCount;
  Map<String, String> cameraSettings;

  ScanProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastModifiedAt,
    this.captureMode = 'photo',
    this.smartCapture = false,
    this.captureCount = 0,
    Map<String, String>? cameraSettings,
  }) : cameraSettings = cameraSettings ?? {
    'Resolution': '4K',
    'FPS': '30',
    'Lens': 'Linear',
    'ISO Max': '400',
    'Shutter': 'Auto',
    'White Balance': '5500K',
    'Bitrate': 'High',
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'lastModifiedAt': lastModifiedAt.toIso8601String(),
    'captureMode': captureMode,
    'smartCapture': smartCapture,
    'captureCount': captureCount,
    'cameraSettings': cameraSettings,
  };

  factory ScanProject.fromJson(Map<String, dynamic> json) => ScanProject(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
    captureMode: json['captureMode'] as String? ?? 'photo',
    smartCapture: json['smartCapture'] as bool? ?? false,
    captureCount: json['captureCount'] as int? ?? 0,
    cameraSettings: json['cameraSettings'] != null 
        ? Map<String, String>.from(json['cameraSettings'] as Map)
        : null,
  );

  String toJsonString() => jsonEncode(toJson());
  static ScanProject fromJsonString(String s) => ScanProject.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
