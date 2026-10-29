import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosmos3d/services/reconstruction_manifest.dart';

CalibratedFrame frame({
  String path = 'images/a.jpg',
  List<List<double>>? pose,
}) => CalibratedFrame(
  path: path,
  cameraId: 1,
  width: 4000,
  height: 3000,
  fx: 2000,
  fy: 2000,
  cx: 2000,
  cy: 1500,
  cameraToWorld:
      pose ??
      [
        [1, 0, 0, 2],
        [0, 1, 0, 3],
        [0, 0, 1, 4],
        [0, 0, 0, 1],
      ],
);
void main() {
  test('Nerfstudio flips camera Y/Z and preserves translation', () {
    final manifest = ReconstructionManifest([frame()]);
    final output = jsonDecode(manifest.transformsJson());
    expect(output['frames'][0]['transform_matrix'], [
      [1, 0, 0, 2],
      [0, -1, 0, 3],
      [0, 0, -1, 4],
      [0, 0, 0, 1],
    ]);
  });
  test('COLMAP inverts camera pose and emits two lines per image', () {
    final output = ReconstructionManifest([frame()]).colmapText();
    expect(
      output['images.txt'],
      contains('1 1.0 0.0 0.0 0.0 -2.0 -3.0 -4.0 1 images/a.jpg\n\n'),
    );
    expect(output['cameras.txt'], contains('1 OPENCV 4000 3000'));
  });
  test('rejects fabricated invalid rotation, paths, and duplicates', () {
    expect(
      () => ReconstructionManifest([frame(path: '../bad.jpg')]),
      throwsArgumentError,
    );
    expect(
      () => ReconstructionManifest([frame(), frame()]),
      throwsArgumentError,
    );
    expect(
      () => ReconstructionManifest([
        frame(
          pose: [
            [2, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1],
          ],
        ),
      ]),
      throwsArgumentError,
    );
  });
}
