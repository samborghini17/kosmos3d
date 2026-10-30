import 'package:flutter_test/flutter_test.dart';
import 'package:kosmos3d/services/gopro_service.dart';
import 'package:kosmos3d/services/gopro_protocol.dart';

class FakeGoPro {
  final values = <int, int>{125: 3, 122: 27, 171: 3};
  final writes = <int, int>{};
  bool mismatch = false;
  late final GoProProtocol protocol;
  final decoder = GoProPacketDecoder();
  FakeGoPro() {
    protocol = GoProProtocol((channel, packet) async {
      final request = decoder.add(packet);
      if (request == null) return;
      final command = request[0];
      List<int> reply = [command, 0];
      if (channel == 'query') {
        if (command == 0x13) {
          for (final id in request.skip(1)) {
            reply.addAll([id, 1, 0]);
          }
        } else if (command == 0x32) {
          final ids = request.length == 1
              ? [125, 122, 171]
              : request.sublist(1);
          for (final id in ids) {
            final options = switch (id) {
              125 => [0, 1, 2, 3],
              122 => [27, 28],
              171 => [0, 3],
              172 => [1, 2], // HERO13: listed, but no 0 (off)
              _ => <int>[],
            };
            // Real cameras repeat the ID once per supported option.
            for (final option in options) {
              reply.addAll([id, 1, option]);
            }
          }
        } else if (command == 0x12) {
          for (final id in request.skip(1)) {
            reply.addAll([id, 1, mismatch && id == 122 ? 27 : values[id]!]);
          }
        }
      } else if (channel == 'setting') {
        values[command] = request[2];
        writes[command] = request[2];
      }
      for (final part in GoProProtocol.packetize(reply)) {
        protocol.receive(channel, part);
      }
    });
  }
}

void main() {
  test(
    'photo uses supported lens enum and explicitly disables native interval',
    () async {
      final camera = FakeGoPro();
      final service = GoProService.testConnection('a', camera.protocol);
      addTearDown(service.dispose);
      await service.applySettingsToDevice('a', {
        'Photo Format': 'RAW',
        'Lens': 'Linear',
        'Interval': '1s',
      });
      expect(camera.writes, {125: 1, 171: 0, 122: 28});
      expect(camera.writes.containsKey(121), isFalse);
      expect(camera.writes.containsKey(227), isFalse);
      expect(camera.writes.containsKey(172), isFalse);
    },
  );
  test('read-back mismatch fails the settings operation', () async {
    final camera = FakeGoPro()..mismatch = true;
    final service = GoProService.testConnection('a', camera.protocol);
    addTearDown(service.dispose);
    await expectLater(
      service.applySettingsToDevice('a', {'Lens': 'Linear'}),
      throwsStateError,
    );
    expect(service.devices.single.currentSettings, isEmpty);
  });
  test('unverified Protune request fails before any writes', () async {
    final camera = FakeGoPro();
    final service = GoProService.testConnection('a', camera.protocol);
    addTearDown(service.dispose);
    await expectLater(
      service.applySettingsToDevice('a', {'White Balance': '5500K'}),
      throwsUnsupportedError,
    );
    expect(camera.writes, isEmpty);
  });
}
