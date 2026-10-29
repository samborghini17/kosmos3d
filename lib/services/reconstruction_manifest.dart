import 'dart:convert';
import 'dart:math';

/// A calibrated image pose: OpenCV camera-to-world, world coordinates in meters.
/// Phone heading/GPS alone must never be passed off as calibrated extrinsics.
class CalibratedFrame {
  CalibratedFrame({
    required this.path,
    required this.cameraId,
    required this.width,
    required this.height,
    required this.fx,
    required this.fy,
    required this.cx,
    required this.cy,
    required this.cameraToWorld,
    this.k1 = 0,
    this.k2 = 0,
    this.p1 = 0,
    this.p2 = 0,
  });
  final String path;
  final int cameraId, width, height;
  final double fx, fy, cx, cy, k1, k2, p1, p2;
  final List<List<double>> cameraToWorld;
  List<double> get intrinsics => [fx, fy, cx, cy, k1, k2, p1, p2];
  void validate() {
    if (cameraId < 1 ||
        width < 1 ||
        height < 1 ||
        fx <= 0 ||
        fy <= 0 ||
        intrinsics.any((v) => !v.isFinite) ||
        path.isEmpty ||
        path.startsWith('/') ||
        path.contains('\\') ||
        path.contains(':') ||
        path.split('/').contains('..') ||
        RegExp(r'\s').hasMatch(path)) {
      throw ArgumentError('Invalid image path or calibration');
    }
    final m = cameraToWorld;
    if (m.length != 4 ||
        m.any((r) => r.length != 4 || r.any((v) => !v.isFinite))) {
      throw ArgumentError('Expected finite 4x4 camera-to-world matrix');
    }
    for (var i = 0; i < 4; i++) {
      if ((m[3][i] - (i == 3 ? 1 : 0)).abs() > 1e-6) {
        throw ArgumentError('Invalid homogeneous row');
      }
    }
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        var dot = 0.0;
        for (var k = 0; k < 3; k++) {
          dot += m[k][i] * m[k][j];
        }
        if ((dot - (i == j ? 1 : 0)).abs() > 1e-5) {
          throw ArgumentError('Rotation is not orthonormal');
        }
      }
    }
    final det =
        m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
        m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
        m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
    if ((det - 1).abs() > 1e-5) {
      throw ArgumentError('Rotation has a reflection');
    }
  }
}

class ReconstructionManifest {
  ReconstructionManifest(this.frames) {
    if (frames.isEmpty) throw ArgumentError('No calibrated frames');
    final paths = <String>{};
    final cameras = <int, String>{};
    for (final f in frames) {
      f.validate();
      if (!paths.add(f.path)) {
        throw ArgumentError('Duplicate media path: ${f.path}');
      }
      final signature = '${f.width} ${f.height} ${f.intrinsics}';
      if (cameras.containsKey(f.cameraId) && cameras[f.cameraId] != signature) {
        throw ArgumentError(
          'Use a different camera ID when calibration changes',
        );
      }
      cameras[f.cameraId] = signature;
    }
  }
  final List<CalibratedFrame> frames;
  String transformsJson() => const JsonEncoder.withIndent('  ').convert({
    'camera_model': 'OPENCV',
    'frames': frames
        .map(
          (f) => {
            'file_path': f.path, 'w': f.width, 'h': f.height,
            'fl_x': f.fx, 'fl_y': f.fy, 'cx': f.cx, 'cy': f.cy,
            'k1': f.k1, 'k2': f.k2, 'p1': f.p1, 'p2': f.p2,
            // OpenCV to OpenGL: flip camera Y/Z columns; preserve world translation.
            'transform_matrix': List.generate(
              4,
              (r) => List.generate(
                4,
                (c) => f.cameraToWorld[r][c] * (c == 1 || c == 2 ? -1 : 1),
              ),
            ),
          },
        )
        .toList(),
  });

  Map<String, String> colmapText() {
    final cameras = StringBuffer('# CAMERA_ID MODEL WIDTH HEIGHT PARAMS\n');
    final images = StringBuffer(
      '# IMAGE_ID QW QX QY QZ TX TY TZ CAMERA_ID NAME\n',
    );
    final seen = <int>{};
    for (var i = 0; i < frames.length; i++) {
      final f = frames[i];
      if (seen.add(f.cameraId)) {
        cameras.writeln(
          '${f.cameraId} OPENCV ${f.width} ${f.height} ${f.intrinsics.join(' ')}',
        );
      }
      final m = f.cameraToWorld;
      final r = List.generate(3, (i) => List.generate(3, (j) => m[j][i]));
      final t = List.generate(
        3,
        (i) => -(r[i][0] * m[0][3] + r[i][1] * m[1][3] + r[i][2] * m[2][3]),
      );
      final q = _quaternion(r);
      images.writeln(
        '${i + 1} ${q.join(' ')} ${t.join(' ')} ${f.cameraId} ${f.path}',
      );
      images
          .writeln(); // Empty POINTS2D line is required, even for pose-only models.
    }
    return {
      'cameras.txt': '$cameras',
      'images.txt': '$images',
      'points3D.txt': '# Pose-only model; no triangulated points\n',
    };
  }

  List<double> _quaternion(List<List<double>> r) {
    final trace = r[0][0] + r[1][1] + r[2][2];
    final q = List<double>.filled(4, 0);
    if (trace > 0) {
      final s = sqrt(trace + 1) * 2;
      q[0] = s / 4;
      q[1] = (r[2][1] - r[1][2]) / s;
      q[2] = (r[0][2] - r[2][0]) / s;
      q[3] = (r[1][0] - r[0][1]) / s;
    } else {
      var i = 0;
      if (r[1][1] > r[i][i]) i = 1;
      if (r[2][2] > r[i][i]) i = 2;
      final j = (i + 1) % 3, k = (i + 2) % 3;
      final s = sqrt(1 + r[i][i] - r[j][j] - r[k][k]) * 2;
      q[0] = (r[k][j] - r[j][k]) / s;
      q[i + 1] = s / 4;
      q[j + 1] = (r[j][i] + r[i][j]) / s;
      q[k + 1] = (r[k][i] + r[i][k]) / s;
    }
    final norm = sqrt(q.fold<double>(0, (s, v) => s + v * v));
    return q.map((v) => v / norm).toList();
  }
}
