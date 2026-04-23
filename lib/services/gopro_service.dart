import 'dart:async';
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

/// Abstract camera service interface for future extensibility
abstract class CameraServiceInterface {
  List<CameraDevice> get devices;
  bool get isScanning;
  void startScan();
  Future<void> connectToDevice(String id);
  Future<void> triggerShutter(String id);
  Future<void> stopShutter(String id);
  Future<void> applySettingsToDevice(String id, Map<String, String> settings);
}

class GoProService extends ChangeNotifier implements CameraServiceInterface {
  final List<CameraDevice> _devices = [];
  final Map<String, BluetoothDevice> _bleDevices = {};
  final Map<String, Map<String, BluetoothCharacteristic>> _charCache = {};
  bool _isScanning = false;

  // Keep-alive and polling timers per device
  final Map<String, Timer> _keepAliveTimers = {};
  final Map<String, Timer> _batteryPollTimers = {};

  @override
  List<CameraDevice> get devices => _devices;
  @override
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

  @override
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

  @override
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

        // Discover services and cache characteristics
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

        // Subscribe to notifications
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

        // Register for push status updates (battery + storage)
        await _registerStatusNotifications(id);

        // Initial battery + storage query
        await queryBatteryAndStorage(id);

        // Start keep-alive timer (every 28s, GoPro timeout is ~60s)
        _startKeepAlive(id);

        // Start battery polling timer (every 30s)
        _startBatteryPolling(id);
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
    }
  }

  /// Register for push-based status notifications
  Future<void> _registerStatusNotifications(String id) async {
    final chars = _charCache[id];
    if (chars == null || chars['queryReq'] == null) return;
    try {
      // Register for status value updates (Query ID 0x53)
      // Status 70 (0x46) = battery %, Status 54 (0x36) = SD remaining KB
      await chars['queryReq']!.write(
        [0x04, 0x53, 0x46, 0x36, 0x08],
        withoutResponse: false,
      );
    } catch (e) {
      debugPrint("Register status notifications error: $e");
    }
  }

  /// Query battery level and storage
  Future<void> queryBatteryAndStorage(String id) async {
    final chars = _charCache[id];
    if (chars == null || chars['queryReq'] == null) return;
    try {
      // Get Status Values: 70 (battery %), 54 (SD remaining KB), 8 (busy)
      await chars['queryReq']!.write(
        [0x04, 0x13, 0x46, 0x36, 0x08],
        withoutResponse: false,
      );
    } catch (e) {
      debugPrint("Battery query error: $e");
    }
  }

  /// Send BLE keep-alive to prevent disconnection
  void _startKeepAlive(String id) {
    _keepAliveTimers[id]?.cancel();
    _keepAliveTimers[id] = Timer.periodic(const Duration(seconds: 28), (_) async {
      final chars = _charCache[id];
      if (chars == null || chars['commandReq'] == null) return;
      try {
        // Keep Alive command
        await chars['commandReq']!.write([0x01, 0x5B], withoutResponse: false);
      } catch (e) {
        debugPrint("Keep-alive error for $id: $e");
      }
    });
  }

  /// Poll battery every 30s
  void _startBatteryPolling(String id) {
    _batteryPollTimers[id]?.cancel();
    _batteryPollTimers[id] = Timer.periodic(const Duration(seconds: 30), (_) {
      queryBatteryAndStorage(id);
    });
  }

  /// Parse TLV status response - FIXED: skip 3 header bytes
  void _handleQueryResponse(String deviceId, List<int> value) {
    if (value.length < 4) return;
    try {
      // Response format: [totalLen, queryId, resultCode, ...TLV entries]
      // Skip first 3 bytes: totalLen + queryId + result
      int i = 3;
      while (i < value.length - 1) {
        int statusId = value[i];
        int statusLen = value[i + 1];
        if (i + 2 + statusLen > value.length) break;

        final devIndex = _devices.indexWhere((d) => d.id == deviceId);
        if (devIndex == -1) { i += 2 + statusLen; continue; }

        if (statusId == 0x46 && statusLen >= 1) {
          // Status 70: Battery percentage (0-100)
          int battery = value[i + 2];
          if (battery >= 0 && battery <= 100) {
            _devices[devIndex] = _devices[devIndex].copyWith(batteryLevel: battery);
            debugPrint("GoPro [$deviceId] Battery: $battery%");
          }
        } else if (statusId == 0x36 && statusLen >= 4) {
          // Status 54: SD card remaining space in KB (4-byte big-endian int)
          int kb = (value[i + 2] << 24) | (value[i + 3] << 16) |
                   (value[i + 4] << 8)  | value[i + 5];
          String storage;
          if (kb > 1048576) {
            storage = '${(kb / 1048576).toStringAsFixed(1)} GB';
          } else if (kb > 1024) {
            storage = '${(kb / 1024).toStringAsFixed(0)} MB';
          } else {
            storage = '$kb KB';
          }
          _devices[devIndex] = _devices[devIndex].copyWith(storageRemaining: storage);
          debugPrint("GoPro [$deviceId] Storage: $storage");
        } else if (statusId == 0x08 && statusLen >= 1) {
          // Status 8: Is camera busy/encoding
          bool busy = value[i + 2] != 0;
          debugPrint("GoPro [$deviceId] Busy: $busy");
        }

        i += 2 + statusLen;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Query parse error: $e");
    }
  }

  /// Disconnect a device cleanly
  Future<void> disconnectDevice(String id) async {
    _keepAliveTimers[id]?.cancel();
    _keepAliveTimers.remove(id);
    _batteryPollTimers[id]?.cancel();
    _batteryPollTimers.remove(id);

    if (_isMobilePlatform) {
      try {
        await _bleDevices[id]?.disconnect();
      } catch (e) {
        debugPrint("Disconnect error: $e");
      }
    }

    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(isConnected: false, batteryLevel: 0);
    }
    _charCache.remove(id);
    notifyListeners();
  }

  // ─── MODE SWITCHING ────────────────────────────────────────

  Future<void> setPresetGroup(String id, int groupId) async {
    final chars = _charCache[id];
    if (chars == null || chars['commandReq'] == null) return;
    try {
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

  Future<void> setPhotoMode(String id) async =>
      setPresetGroup(id, GoProSettings.presetGroupPhoto);

  Future<void> setVideoMode(String id) async =>
      setPresetGroup(id, GoProSettings.presetGroupVideo);

  Future<void> setTimeLapseMode(String id) async =>
      setPresetGroup(id, GoProSettings.presetGroupTimelapse);

  Future<void> setAllCamerasMode(String mode) async {
    final groupId = mode == 'video'
        ? GoProSettings.presetGroupVideo
        : mode == 'timelapse'
            ? GoProSettings.presetGroupTimelapse
            : GoProSettings.presetGroupPhoto;

    for (final cam in _devices.where((d) => d.isConnected)) {
      await setPresetGroup(cam.id, groupId);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  // ─── SETTINGS ──────────────────────────────────────────────

  Future<void> _writeSetting(String id, int settingId, int value) async {
    final chars = _charCache[id];
    if (chars == null || chars['settingReq'] == null) return;
    try {
      await chars['settingReq']!.write(
        [0x03, settingId, 0x01, value],
        withoutResponse: false,
      );
      debugPrint("GoPro [$id] Set setting $settingId = $value");
      await Future.delayed(const Duration(milliseconds: 150));
    } catch (e) {
      debugPrint("Set setting error ($settingId): $e");
    }
  }

  @override
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

  Future<void> applySettingsToAll(Map<String, String> settings) async {
    for (final cam in _devices.where((d) => d.isConnected)) {
      await applySettingsToDevice(cam.id, settings);
    }
  }

  // ─── SHUTTER CONTROL ──────────────────────────────────────

  @override
  Future<void> triggerShutter(String id) async {
    final chars = _charCache[id];
    if (chars == null || chars['commandReq'] == null) return;
    try {
      await chars['commandReq']!.write(
        [0x03, 0x01, 0x01, 0x01],
        withoutResponse: false,
      );
    } catch (e) {
      debugPrint("Shutter trigger error: $e");
    }
  }

  @override
  Future<void> stopShutter(String id) async {
    final chars = _charCache[id];
    if (chars == null || chars['commandReq'] == null) return;
    try {
      await chars['commandReq']!.write(
        [0x03, 0x01, 0x01, 0x00],
        withoutResponse: false,
      );
    } catch (e) {
      debugPrint("Shutter stop error: $e");
    }
  }

  Future<void> triggerAllShutters() async {
    for (final cam in _devices.where((d) => d.isConnected)) {
      await triggerShutter(cam.id);
    }
  }

  // ─── SD CARD FORMAT ────────────────────────────────────────

  /// Format SD card on a connected GoPro (destructive!)
  Future<void> formatSdCard(String id) async {
    final chars = _charCache[id];
    if (chars == null || chars['commandReq'] == null) return;
    try {
      // Format SD Card command
      await chars['commandReq']!.write(
        [0x01, 0x0A],
        withoutResponse: false,
      );
      debugPrint("GoPro [$id] SD Card format triggered");
    } catch (e) {
      debugPrint("Format SD error: $e");
    }
  }

  /// Format SD cards on ALL connected cameras
  Future<void> formatAllSdCards() async {
    for (final cam in _devices.where((d) => d.isConnected)) {
      await formatSdCard(cam.id);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // ─── POWER ─────────────────────────────────────────────────

  /// Power off a connected GoPro
  Future<void> powerOff(String id) async {
    final chars = _charCache[id];
    if (chars == null || chars['commandReq'] == null) return;
    try {
      await chars['commandReq']!.write(
        [0x01, 0x05],
        withoutResponse: false,
      );
    } catch (e) {
      debugPrint("Power off error: $e");
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

  @override
  void dispose() {
    for (final timer in _keepAliveTimers.values) { timer.cancel(); }
    for (final timer in _batteryPollTimers.values) { timer.cancel(); }
    super.dispose();
  }
}
