import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/camera_device.dart';

/// Open GoPro BLE Protocol UUIDs
class GoProUuids {
  static final service = Guid('0000fea6-0000-1000-8000-00805f9b34fb');
  static final commandReq = Guid('b5f90072-aa8d-11e3-9046-0002a5d5c51b');
  static final commandResp = Guid('b5f90073-aa8d-11e3-9046-0002a5d5c51b');
  static final settingReq = Guid('b5f90074-aa8d-11e3-9046-0002a5d5c51b');
  static final settingResp = Guid('b5f90075-aa8d-11e3-9046-0002a5d5c51b');
  static final queryReq = Guid('b5f90076-aa8d-11e3-9046-0002a5d5c51b');
  static final queryResp = Guid('b5f90077-aa8d-11e3-9046-0002a5d5c51b');
}

/// Open GoPro Setting IDs and their value mappings
class GoProSettings {
  // Setting ID 2: Resolution
  static const int resolutionId = 2;
  static const Map<String, int> resolution = {
    '1080p': 9, '2.7K': 4, '4K': 1, '5.3K': 100,
  };

  // Setting ID 3: FPS
  static const int fpsId = 3;
  static const Map<String, int> fps = {
    '24': 10, '30': 8, '60': 5, '120': 0,
  };

  // Setting ID 121: Digital Lens / FOV
  static const int lensId = 121;
  static const Map<String, int> lens = {
    'Wide': 0, 'Linear': 4, 'SuperView': 3,
  };

  // Setting ID 13: Max ISO (Video)
  static const int isoMaxId = 13;
  static const Map<String, int> isoMax = {
    '100': 24, '200': 25, '400': 26, '800': 27, '1600': 28,
  };

  // Setting ID 19: Auto Shutter
  static const int shutterId = 19;
  static const Map<String, int> shutter = {
    'Auto': 0, '1/60': 5, '1/120': 6, '1/240': 8, '1/480': 10,
  };

  // Setting ID 11: White Balance
  static const int whiteBalanceId = 11;
  static const Map<String, int> whiteBalance = {
    'Auto': 0, '3200K': 2, '4000K': 5, '5500K': 6, '6500K': 7,
  };

  // Setting ID 192: Bitrate
  static const int bitrateId = 192;
  static const Map<String, int> bitrate = {
    'Standard': 0, 'High': 1,
  };

  // Preset Group IDs for mode switching
  static const int presetGroupVideo = 1000;
  static const int presetGroupPhoto = 1001;
  static const int presetGroupTimelapse = 1002;
}

class GoProService extends ChangeNotifier {
  final List<CameraDevice> _devices = [];
  final Map<String, BluetoothDevice> _bleDevices = {};
  // Cache discovered characteristics per device
  final Map<String, Map<String, BluetoothCharacteristic>> _charCache = {};
  bool _isScanning = false;

  List<CameraDevice> get devices => _devices;
  bool get isScanning => _isScanning;

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.bluetoothScan.request().isGranted &&
          await Permission.bluetoothConnect.request().isGranted &&
          await Permission.location.request().isGranted) {
        return true;
      }
      return false;
    } else if (Platform.isIOS) {
      return true;
    }
    return false;
  }

  // ─── SCANNING ──────────────────────────────────────────────

  void startScan() async {
    if (_isScanning) return;

    _isScanning = true;
    _devices.clear();
    _bleDevices.clear();
    _charCache.clear();
    notifyListeners();

    if (_isMobilePlatform) {
      bool hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        _isScanning = false;
        notifyListeners();
        return;
      }

      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

        FlutterBluePlus.scanResults.listen((results) {
          for (var r in results) {
            final deviceName = r.device.platformName.isNotEmpty
                ? r.device.platformName
                : r.advertisementData.advName;
            if (deviceName.isNotEmpty) {
              final existing = _devices.any((d) => d.id == r.device.remoteId.str);
              if (!existing) {
                _bleDevices[r.device.remoteId.str] = r.device;
                _devices.add(CameraDevice(
                  id: r.device.remoteId.str,
                  name: deviceName,
                  isConnected: false,
                  batteryLevel: 0,
                  storageRemaining: 'Unknown',
                  isRecording: false,
                ));
              }
            }
          }
          notifyListeners();
        });

        await Future.delayed(const Duration(seconds: 5));
        await FlutterBluePlus.stopScan();
      } catch (e) {
        debugPrint("BLE Scan Error: $e");
      }
    } else {
      await Future.delayed(const Duration(seconds: 1));
    }

    _isScanning = false;
    notifyListeners();
  }

  // ─── CONNECTION ────────────────────────────────────────────

  Future<void> connectToDevice(String id) async {
    if (!_isMobilePlatform) {
      final index = _devices.indexWhere((d) => d.id == id);
      if (index != -1) {
        _devices[index] = _devices[index].copyWith(isConnected: true);
        notifyListeners();
      }
      return;
    }

    try {
      final device = _bleDevices[id];
      if (device != null) {
        await device.connect(license: License.free);

        final index = _devices.indexWhere((d) => d.id == id);
        if (index != -1) {
          _devices[index] = _devices[index].copyWith(isConnected: true);
          notifyListeners();
        }

        // Discover services and cache all Open GoPro characteristics
        List<BluetoothService> services = await device.discoverServices();
        final chars = <String, BluetoothCharacteristic>{};

        for (var service in services) {
          if (service.serviceUuid == GoProUuids.service) {
            for (var c in service.characteristics) {
              if (c.characteristicUuid == GoProUuids.commandReq) chars['commandReq'] = c;
              if (c.characteristicUuid == GoProUuids.commandResp) chars['commandResp'] = c;
              if (c.characteristicUuid == GoProUuids.settingReq) chars['settingReq'] = c;
              if (c.characteristicUuid == GoProUuids.settingResp) chars['settingResp'] = c;
              if (c.characteristicUuid == GoProUuids.queryReq) chars['queryReq'] = c;
              if (c.characteristicUuid == GoProUuids.queryResp) chars['queryResp'] = c;
            }
          }
        }

        _charCache[id] = chars;

        // Subscribe to command & query notifications
        if (chars['commandResp'] != null) {
          await chars['commandResp']!.setNotifyValue(true);
          chars['commandResp']!.onValueReceived.listen((value) {
            debugPrint("GoPro [$id] CMD Response: $value");
          });
        }
        if (chars['queryResp'] != null) {
          await chars['queryResp']!.setNotifyValue(true);
          chars['queryResp']!.onValueReceived.listen((value) {
            _handleQueryResponse(id, value);
          });
        }
        if (chars['settingResp'] != null) {
          await chars['settingResp']!.setNotifyValue(true);
          chars['settingResp']!.onValueReceived.listen((value) {
            debugPrint("GoPro [$id] Setting Response: $value");
          });
        }

        // Query battery level
        if (chars['queryReq'] != null) {
          // Get Status Value for Status ID 70 (0x46) = battery percentage
          await chars['queryReq']!.write([0x02, 0x13, 0x46], withoutResponse: false);
        }
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
    }
  }

  void _handleQueryResponse(String deviceId, List<int> value) {
    if (value.length < 4) return;
    // Parse TLV status responses
    try {
      int i = 2; // Skip header bytes
      while (i < value.length - 1) {
        int statusId = value[i];
        int statusLen = value[i + 1];
        if (i + 2 + statusLen > value.length) break;

        if (statusId == 0x46 && statusLen >= 1) {
          // Battery percentage
          int battery = value[i + 2];
          final devIndex = _devices.indexWhere((d) => d.id == deviceId);
          if (devIndex != -1) {
            _devices[devIndex] = _devices[devIndex].copyWith(batteryLevel: battery);
            notifyListeners();
          }
        }

        i += 2 + statusLen;
      }
    } catch (e) {
      debugPrint("Query parse error: $e");
    }
  }

  // ─── MODE SWITCHING ────────────────────────────────────────

  /// Switch a connected GoPro to Photo or Video preset group.
  Future<void> setPresetGroup(String id, int groupId) async {
    final chars = _charCache[id];
    if (chars == null || chars['commandReq'] == null) return;

    try {
      // Load Preset Group command (TLV):
      // [totalLen, commandId=0x3E, valueLen, groupId_high, groupId_low]
      final highByte = (groupId >> 8) & 0xFF;
      final lowByte = groupId & 0xFF;
      await chars['commandReq']!.write(
        [0x04, 0x3E, 0x02, highByte, lowByte],
        withoutResponse: false,
      );
      debugPrint("GoPro [$id] Set Preset Group: $groupId");
    } catch (e) {
      debugPrint("Set Preset Group error: $e");
    }
  }

  /// Switch camera to Photo mode
  Future<void> setPhotoMode(String id) async {
    await setPresetGroup(id, GoProSettings.presetGroupPhoto);
  }

  /// Switch camera to Video mode
  Future<void> setVideoMode(String id) async {
    await setPresetGroup(id, GoProSettings.presetGroupVideo);
  }

  /// Switch all connected cameras to a mode
  Future<void> setAllCamerasMode(String mode) async {
    final groupId = mode == 'video'
        ? GoProSettings.presetGroupVideo
        : GoProSettings.presetGroupPhoto;

    for (final cam in _devices.where((d) => d.isConnected)) {
      await setPresetGroup(cam.id, groupId);
      // Small delay between commands to avoid BLE congestion
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  // ─── SETTINGS ──────────────────────────────────────────────

  /// Write a single setting to a connected GoPro via the Settings characteristic.
  Future<void> _writeSetting(String id, int settingId, int value) async {
    final chars = _charCache[id];
    if (chars == null || chars['settingReq'] == null) return;

    try {
      // Set Setting TLV: [totalLen, settingId, valueLen, value]
      await chars['settingReq']!.write(
        [0x03, settingId, 0x01, value],
        withoutResponse: false,
      );
      debugPrint("GoPro [$id] Set setting $settingId = $value");
      // Small delay to let camera process
      await Future.delayed(const Duration(milliseconds: 150));
    } catch (e) {
      debugPrint("Set setting error ($settingId): $e");
    }
  }

  /// Apply a full set of camera settings to a connected GoPro.
  Future<void> applySettingsToDevice(String id, Map<String, String> settings) async {
    for (final entry in settings.entries) {
      final key = entry.key;
      final val = entry.value;
      int? settingId;
      int? settingValue;

      switch (key) {
        case 'Resolution':
          settingId = GoProSettings.resolutionId;
          settingValue = GoProSettings.resolution[val];
        case 'FPS':
          settingId = GoProSettings.fpsId;
          settingValue = GoProSettings.fps[val];
        case 'Lens':
          settingId = GoProSettings.lensId;
          settingValue = GoProSettings.lens[val];
        case 'ISO Max':
          settingId = GoProSettings.isoMaxId;
          settingValue = GoProSettings.isoMax[val];
        case 'Shutter':
          settingId = GoProSettings.shutterId;
          settingValue = GoProSettings.shutter[val];
        case 'White Balance':
          settingId = GoProSettings.whiteBalanceId;
          settingValue = GoProSettings.whiteBalance[val];
        case 'Bitrate':
          settingId = GoProSettings.bitrateId;
          settingValue = GoProSettings.bitrate[val];
      }

      if (settingId != null && settingValue != null) {
        await _writeSetting(id, settingId, settingValue);
      }
    }
  }

  /// Apply settings to ALL connected cameras
  Future<void> applySettingsToAll(Map<String, String> settings) async {
    for (final cam in _devices.where((d) => d.isConnected)) {
      await applySettingsToDevice(cam.id, settings);
    }
  }

  // ─── SHUTTER CONTROL ──────────────────────────────────────

  Future<void> triggerShutter(String id) async {
    final chars = _charCache[id];
    if (chars == null || chars['commandReq'] == null) return;

    try {
      // Shutter ON: [length=3, cmdId=1, subCmd=1, value=1]
      await chars['commandReq']!.write(
        [0x03, 0x01, 0x01, 0x01],
        withoutResponse: false,
      );
    } catch (e) {
      debugPrint("Shutter trigger error: $e");
    }
  }

  Future<void> stopShutter(String id) async {
    final chars = _charCache[id];
    if (chars == null || chars['commandReq'] == null) return;

    try {
      // Shutter OFF: [length=3, cmdId=1, subCmd=1, value=0]
      await chars['commandReq']!.write(
        [0x03, 0x01, 0x01, 0x00],
        withoutResponse: false,
      );
    } catch (e) {
      debugPrint("Shutter stop error: $e");
    }
  }

  /// Trigger shutter on ALL connected cameras
  Future<void> triggerAllShutters() async {
    for (final cam in _devices.where((d) => d.isConnected)) {
      await triggerShutter(cam.id);
    }
  }

  // ─── LEGACY COMPAT ────────────────────────────────────────

  void toggleRecording(String id, bool start) async {
    if (start) {
      await triggerShutter(id);
    } else {
      await stopShutter(id);
    }
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(isRecording: start);
      notifyListeners();
    }
  }

  void toggleAllRecording(bool start) {
    for (int i = 0; i < _devices.length; i++) {
      toggleRecording(_devices[i].id, start);
    }
  }

  void updateCameraSettings(String id, Map<String, String> newSettings) {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final updatedSettings = Map<String, String>.from(_devices[index].currentSettings)
        ..addAll(newSettings);
      _devices[index] = _devices[index].copyWith(currentSettings: updatedSettings);
      notifyListeners();
    }
  }
}
