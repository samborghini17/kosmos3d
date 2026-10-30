import 'dart:async';

/// One request at a time per connection. A timeout poisons the connection:
/// Open GoPro has no transaction IDs to disambiguate a late acknowledgement.
class GoProProtocol {
  GoProProtocol(this.write, {this.timeout = const Duration(seconds: 5)});
  final Future<void> Function(String channel, List<int> packet) write;
  final Duration timeout;
  final Map<String, GoProPacketDecoder> _decoders = {};
  Future<void> _tail = Future.value();
  Completer<List<int>>? _pending;
  bool Function(List<int>)? _matches;
  String? _channel;
  Object? _closed;

  Future<List<int>> exchange(
    String channel,
    List<int> message, {
    int? responseAction,
    bool protobuf = false,
  }) {
    final result = _tail.then((_) async {
      if (_closed != null) throw StateError('Reconnect camera: $_closed');
      final pending = Completer<List<int>>();
      _pending = pending;
      _channel = channel;
      _matches = (p) =>
          p.length >= 2 &&
          p[0] == message[0] &&
          (!protobuf || p[1] == responseAction);
      final response = pending.future.timeout(timeout);
      unawaited(response.then<void>((_) {}, onError: (Object _) {}));
      try {
        for (final packet in packetize(message)) {
          await write(channel, packet).timeout(timeout);
        }
        final payload = await response;
        if (!protobuf && payload[1] != 0) {
          throw GoProRejected(message[0], payload[1]);
        }
        return payload;
      } catch (e) {
        if (e is! GoProRejected) close(e);
        rethrow;
      } finally {
        _pending = null;
        _matches = null;
        _channel = null;
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  void receive(String channel, List<int> packet) {
    try {
      final payload = (_decoders[channel] ??= GoProPacketDecoder()).add(packet);
      if (payload != null &&
          _channel == channel &&
          _matches?.call(payload) == true &&
          !(_pending?.isCompleted ?? true)) {
        _pending!.complete(payload);
      }
    } on FormatException catch (e) {
      close(e);
    }
  }

  void close(Object reason) {
    _closed = reason;
    if (!(_pending?.isCompleted ?? true)) _pending!.completeError(reason);
  }

  static List<List<int>> packetize(List<int> message) {
    if (message.isEmpty || message.length > 8191) {
      throw ArgumentError('Invalid BLE message length');
    }
    final packets = <List<int>>[];
    var offset = 0, sequence = 0;
    while (offset < message.length) {
      final header = offset == 0
          ? [0x20 | (message.length >> 8), message.length & 255]
          : [0x80 | (sequence++ & 15)];
      final end = (offset + 20 - header.length).clamp(0, message.length);
      packets.add([...header, ...message.sublist(offset, end)]);
      offset = end;
    }
    return packets;
  }
}

class GoProRejected implements Exception {
  GoProRejected(this.id, this.status);
  final int id, status;
  @override
  String toString() => 'Camera rejected command/setting $id (status $status)';
}

class GoProPacketDecoder {
  List<int>? _buffer;
  int _length = 0, _sequence = 0;
  List<int>? add(List<int> packet) {
    if (packet.isEmpty) throw const FormatException('Empty BLE packet');
    final header = packet[0];
    int offset;
    if ((header & 128) != 0) {
      if (_buffer == null || (header & 15) != (_sequence++ & 15)) {
        throw const FormatException('Out-of-order BLE continuation');
      }
      offset = 1;
    } else {
      if (_buffer != null) throw const FormatException('Truncated BLE message');
      final type = (header >> 5) & 3;
      offset = type + 1;
      if (type == 3 || packet.length < offset) {
        throw const FormatException('Invalid BLE header');
      }
      _length = switch (type) {
        0 => header & 31,
        1 => ((header & 31) << 8) | packet[1],
        _ => (packet[1] << 8) | packet[2],
      };
      _sequence = 0;
      _buffer = [];
    }
    _buffer!.addAll(packet.sublist(offset));
    if (_buffer!.length > _length) {
      throw const FormatException('BLE length overflow');
    }
    if (_buffer!.length < _length) return null;
    final complete = _buffer;
    _buffer = null;
    return complete;
  }
}

Map<int, List<int>> decodeTlv(List<int> payload) {
  final values = <int, List<int>>{};
  for (var i = 2; i < payload.length;) {
    if (i + 2 > payload.length || i + 2 + payload[i + 1] > payload.length) {
      throw const FormatException('Truncated TLV');
    }
    final length = payload[i + 1];
    values[payload[i]] = payload.sublist(i + 2, i + 2 + length);
    i += 2 + length;
  }
  return values;
}

/// Capability responses repeat the setting ID once per supported option.
Map<int, List<List<int>>> decodeTlvMulti(List<int> payload) {
  final values = <int, List<List<int>>>{};
  for (var i = 2; i < payload.length;) {
    if (i + 2 > payload.length || i + 2 + payload[i + 1] > payload.length) {
      throw const FormatException('Truncated TLV');
    }
    final length = payload[i + 1];
    (values[payload[i]] ??= []).add(payload.sublist(i + 2, i + 2 + length));
    i += 2 + length;
  }
  return values;
}

int bigEndian(List<int> bytes) => bytes.fold(0, (v, b) => (v << 8) | b);

/// Bounded protobuf wire reader; unknown fields are skipped for compatibility.
Map<int, List<Object>> decodeProto(List<int> bytes) {
  var offset = 0;
  int varint() {
    var value = 0;
    for (var shift = 0; shift < 70; shift += 7) {
      if (offset == bytes.length) {
        throw const FormatException('Truncated varint');
      }
      final byte = bytes[offset++];
      value |= (byte & 127) << shift;
      if (byte < 128) return value;
    }
    throw const FormatException('Oversize varint');
  }

  final fields = <int, List<Object>>{};
  while (offset < bytes.length) {
    final tag = varint();
    if (tag >> 3 == 0) throw const FormatException('Invalid protobuf field');
    final wire = tag & 7;
    Object value;
    if (wire == 0) {
      value = varint();
    } else {
      final length = switch (wire) {
        1 => 8,
        2 => varint(),
        5 => 4,
        _ => throw const FormatException('Unsupported protobuf wire type'),
      };
      if (length < 0 || offset + length > bytes.length) {
        throw const FormatException('Truncated protobuf field');
      }
      value = bytes.sublist(offset, offset + length);
      offset += length;
    }
    (fields[tag >> 3] ??= []).add(value);
  }
  return fields;
}

class CameraPresetId {
  const CameraPresetId(this.group, this.id, this.mode);
  final int group, id, mode;
}

List<CameraPresetId> decodePresets(List<int> proto) {
  final presets = <CameraPresetId>[];
  for (final groupBytes in decodeProto(proto)[1] ?? <Object>[]) {
    final group = decodeProto(groupBytes as List<int>);
    for (final presetBytes in group[2] ?? <Object>[]) {
      final preset = decodeProto(presetBytes as List<int>);
      if (group[1] != null && preset[1] != null && preset[2] != null) {
        presets.add(
          CameraPresetId(
            group[1]!.first as int,
            preset[1]!.first as int,
            preset[2]!.first as int,
          ),
        );
      }
    }
  }
  return presets;
}
