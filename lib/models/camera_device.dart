class CameraDevice {
  final String id;
  final String name;
  bool isConnected;
  int batteryLevel; // 0 to 100
  String storageRemaining; // e.g., "1h 45m" or "32GB"
  bool isRecording;
  Map<String, String> currentSettings;

  CameraDevice({
    required this.id,
    required this.name,
    this.isConnected = false,
    this.batteryLevel = 100,
    this.storageRemaining = "Unknown",
    this.isRecording = false,
    Map<String, String>? currentSettings,
  }) : currentSettings = currentSettings ?? {
    'Resolution': '4K',
    'FPS': '60',
    'Lens': 'Linear',
    'ISO Max': '400',
    'Shutter': 'Auto',
    'White Balance': '5500K',
    'Bitrate': 'High'
  };

  // Helper method to simulate a copy with changed state
  CameraDevice copyWith({
    String? id,
    String? name,
    bool? isConnected,
    int? batteryLevel,
    String? storageRemaining,
    bool? isRecording,
    Map<String, String>? currentSettings,
  }) {
    return CameraDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      isConnected: isConnected ?? this.isConnected,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      storageRemaining: storageRemaining ?? this.storageRemaining,
      isRecording: isRecording ?? this.isRecording,
      currentSettings: currentSettings ?? Map.from(this.currentSettings),
    );
  }
}
