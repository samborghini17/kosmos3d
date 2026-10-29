import 'dart:async';
import 'package:flutter/foundation.dart';

enum CapturePhase {
  idle,
  synchronizing,
  ready,
  starting,
  capturing,
  stopping,
  fault,
}

abstract class RigCamera {
  String get id;
  Future<void> configure(
    String mode,
    Map<String, String> settings,
    void Function(String) progress,
  );
  Future<void> verifyReady();
  Future<void> start();
  Future<void> stop();
}

/// Frozen rig membership, verified readiness and one owner for all transitions.
/// Host intervals keep camera interval Off, so every dispatch can be logged.
class CaptureCoordinator extends ChangeNotifier {
  CapturePhase phase = CapturePhase.idle;
  String progress = 'Not synchronized';
  String? error;
  List<RigCamera> _rig = [];
  bool _locked = false, _active = false, _video = false;
  Duration? _interval;
  Timer? _timer;
  Future<void>? _stopFuture;
  int _generation = 0;
  Future<void> Function(DateTime)? onPhoto;
  List<Map<String, Object>> lastDispatch = [];
  bool get busy => _locked;
  bool get active => _active;
  List<String> get cameraIds => _rig.map((c) => c.id).toList(growable: false);
  void _state(CapturePhase state, String text) {
    phase = state;
    progress = text;
    notifyListeners();
  }

  Future<void> prepare(
    List<RigCamera> cameras,
    String mode,
    Map<String, String> settings,
  ) async {
    if (_locked || _active || _stopFuture != null) {
      throw StateError('Capture operation already in progress');
    }
    if (cameras.isEmpty) throw StateError('Connect at least one camera');
    if (mode != 'photo' && mode != 'video') {
      throw UnsupportedError('Capture mode $mode');
    }
    final intervalText = settings['Interval'] ?? 'Off';
    final seconds = intervalText == 'Off'
        ? null
        : double.tryParse(intervalText.replaceAll('s', ''));
    if (mode == 'photo' &&
        intervalText != 'Off' &&
        (seconds == null || seconds < 0.5 || !seconds.isFinite)) {
      throw ArgumentError('Invalid capture interval: $intervalText');
    }
    _locked = true;
    error = null;
    _rig = List.unmodifiable(cameras);
    _video = mode == 'video';
    _interval = !_video && seconds != null
        ? Duration(microseconds: (seconds * 1000000).round())
        : null;
    _state(CapturePhase.synchronizing, 'Synchronizing cameras');
    try {
      for (var i = 0; i < _rig.length; i++) {
        final label = 'Camera ${i + 1}/${_rig.length}';
        await _rig[i].configure(
          mode,
          Map.unmodifiable(settings),
          (step) => _state(CapturePhase.synchronizing, '$label: $step'),
        );
      }
      for (final camera in _rig) {
        await camera.verifyReady();
      }
      _state(
        CapturePhase.ready,
        'Ready - BLE settings verified; check manual exposure and mounting',
      );
    } catch (e) {
      error = '$e';
      _state(CapturePhase.fault, error!);
      rethrow;
    } finally {
      _locked = false;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (_locked || _stopFuture != null) return;
    if (_active) {
      await stop();
      return;
    }
    if (phase != CapturePhase.ready) {
      throw StateError('Synchronize cameras before capture');
    }
    _locked = true;
    _active = _video || _interval != null;
    final generation = ++_generation;
    _state(CapturePhase.starting, 'Checking cameras');
    try {
      await _shot(generation);
      _state(
        _active ? CapturePhase.capturing : CapturePhase.ready,
        _active ? 'Capturing - tap Stop' : 'Ready',
      );
      if (_interval != null) _schedule(generation);
    } catch (e) {
      await _recover(e);
      rethrow;
    } finally {
      _locked = false;
      notifyListeners();
    }
  }

  Future<void> _shot(int generation) async {
    await Future.wait(_rig.map((c) => c.verifyReady()));
    if (generation != _generation) return;
    final dispatchTime = DateTime.now().toUtc();
    final clock = Stopwatch()..start();
    lastDispatch = [];
    await Future.wait(
      _rig.map((c) async {
        final record = <String, Object>{
          'cameraId': c.id,
          'dispatchOffsetUs': clock.elapsedMicroseconds,
          'exposureTimeVerified': false,
        };
        lastDispatch.add(record);
        try {
          await c.start();
          record['ackOffsetUs'] = clock.elapsedMicroseconds;
        } catch (e) {
          record['error'] = '$e';
          rethrow;
        }
      }),
    );
    if (!_video) {
      await onPhoto?.call(dispatchTime);
      await Future.wait(_rig.map((c) => c.verifyReady()));
    }
  }

  void _schedule(int generation) {
    if (!_active || generation != _generation) return;
    // Fixed delay after readiness: slow processing never builds a shutter queue.
    _timer = Timer(_interval!, () async {
      if (!_active || generation != _generation || _locked) return;
      _locked = true;
      try {
        await _shot(generation);
        _schedule(generation);
      } catch (e) {
        await _recover(e);
      } finally {
        _locked = false;
        notifyListeners();
      }
    });
  }

  Future<void> _recover(Object cause) async {
    _timer?.cancel();
    _generation++;
    final failures = await _stopEveryCamera();
    _active = failures.isNotEmpty;
    error =
        '$cause${failures.isEmpty ? '' : '; stop unconfirmed: ${failures.join(', ')}'}';
    _state(CapturePhase.fault, error!);
  }

  Future<List<String>> _stopEveryCamera() async {
    final failures = <String>[];
    await Future.wait(
      _rig.map((c) async {
        try {
          await c.stop();
        } catch (e) {
          failures.add('${c.id}: $e');
        }
      }),
    );
    return failures;
  }

  Future<void> stop() => _stopFuture ??= _stop().whenComplete(() {
    _stopFuture = null;
  });

  Future<void> _stop() async {
    _active = false;
    _timer?.cancel();
    _generation++;
    while (_locked) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    _locked = true;
    _state(CapturePhase.stopping, 'Stopping all cameras');
    try {
      final failures = await _stopEveryCamera();
      if (failures.isNotEmpty) {
        _active = true;
        throw StateError('Stop unconfirmed: ${failures.join(', ')}');
      }
      _state(
        error == null ? CapturePhase.ready : CapturePhase.fault,
        error == null ? 'Stopped' : 'Stopped - synchronize again',
      );
    } catch (e) {
      error = '$e';
      _state(CapturePhase.fault, error!);
      rethrow;
    } finally {
      _locked = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
