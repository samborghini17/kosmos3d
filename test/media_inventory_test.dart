import 'package:flutter_test/flutter_test.dart';
import 'package:kosmos3d/services/media_inventory.dart';

void main() {
  test(
    'burst expansion excludes deleted members and includes RAW companions',
    () {
      final files = expandMediaEntries([
        {
          'n': 'G0010001.JPG',
          'g': '1',
          't': 'b',
          'b': '1',
          'l': '3',
          'm': ['2'],
          's': '2',
          'raw': '1',
        },
      ]);
      expect(files.map((f) => f['n']), [
        'G0010001.JPG',
        'G0010001.GPR',
        'G0010003.JPG',
        'G0010003.GPR',
      ]);
      expect(files.every((f) => f['s'] == 0), true);
    },
  );
  test(
    'unrecognized groups and unsafe names fail instead of claiming complete import',
    () {
      expect(
        () => expandMediaEntries([
          {'n': 'clip.mp4', 'g': '1', 's': '2'},
        ]),
        throwsFormatException,
      );
      expect(
        () => expandMediaEntries([
          {'n': '../file.JPG'},
        ]),
        throwsFormatException,
      );
    },
  );
  test('a group whose count disagrees still lists its members', () {
    final files = expandMediaEntries([
      {'n': 'GPAA0062.JPG', 'g': '1', 't': 't', 'b': '62', 'l': '64', 's': '9'},
    ]);
    expect(files.map((f) => f['n']), [
      'GPAA0062.JPG',
      'GPAA0063.JPG',
      'GPAA0064.JPG',
    ]);
    expect(files.every((f) => f['inventoryMismatch'] == true), true);
  });
}
