import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosmos3d/services/gopro_protocol.dart';

void main() {
  test('fragmented packets round trip, including sequence wrap', () {
    for (final length in [2, 19, 20, 31, 255, 700]) {
      final bytes = List.generate(length, (i) => i % 256);
      final decoder = GoProPacketDecoder();
      List<int>? decoded;
      for (final packet in GoProProtocol.packetize(bytes)) {
        decoded = decoder.add(packet);
      }
      expect(decoded, bytes);
    }
  });
  test('bad continuation and malformed TLV are rejected', () {
    expect(() => GoProPacketDecoder().add([0x80, 1]), throwsFormatException);
    expect(() => decodeTlv([0x12, 0, 122, 2, 32]), throwsFormatException);
  });
  test('notification before write completes still acknowledges', () async {
    late GoProProtocol protocol;
    protocol = GoProProtocol((channel, packet) async {
      protocol.receive(channel, [2, 1, 0]);
    });
    expect(await protocol.exchange('command', [1, 1, 1]), [1, 0]);
  });
  test(
    'wrong channel and unsolicited status cannot acknowledge settings',
    () async {
      late GoProProtocol protocol;
      protocol = GoProProtocol((channel, packet) async {
        protocol.receive('query', [2, 122, 0]);
        protocol.receive('setting', [2, 121, 0]);
        protocol.receive('setting', [2, 122, 0]);
      });
      expect(await protocol.exchange('setting', [122, 1, 32]), [122, 0]);
    },
  );
  test('negative ACK is an error', () async {
    late GoProProtocol protocol;
    protocol = GoProProtocol((c, p) async {
      protocol.receive(c, [2, 122, 2]);
    });
    await expectLater(
      protocol.exchange('setting', [122, 1, 32]),
      throwsA(isA<GoProRejected>()),
    );
  });
  test(
    'timeout poisons link so late ACK cannot confirm a new command',
    () async {
      final protocol = GoProProtocol(
        (c, p) async {},
        timeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        protocol.exchange('command', [1, 1, 1]),
        throwsA(isA<TimeoutException>()),
      );
      protocol.receive('command', [2, 1, 0]);
      await expectLater(
        protocol.exchange('command', [1, 1, 0]),
        throwsStateError,
      );
    },
  );
  test('requests serialize per peripheral', () async {
    final gate = Completer<void>();
    final writes = <int>[];
    late GoProProtocol protocol;
    protocol = GoProProtocol((c, p) async {
      writes.add(p[2]);
      if (writes.length == 1) await gate.future;
      protocol.receive(c, [2, p[2], 0]);
    });
    final a = protocol.exchange('command', [1, 1, 1]);
    final b = protocol.exchange('command', [5]);
    await Future<void>.delayed(Duration.zero);
    expect(writes, [1]);
    gate.complete();
    await Future.wait([a, b]);
    expect(writes, [1, 5]);
  });
  test('preset parser selects actual camera IDs and mode fields', () {
    // NotifyPresetStatus -> group 1001 -> preset ID 42, flatmode 16.
    final presets = decodePresets([10, 9, 8, 233, 7, 18, 4, 8, 42, 16, 16]);
    expect(presets.single.group, 1001);
    expect(presets.single.id, 42);
    expect(presets.single.mode, 16);
  });
}
