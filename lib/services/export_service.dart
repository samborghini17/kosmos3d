import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../services/trajectory_service.dart';
import '../services/rig_geometry_service.dart';

/// Export service that produces COLMAP-compatible and Gaussian Splatting-ready
/// output files. Generates:
/// - transforms.json (NeRF / 3DGS format)
/// - cameras.txt (COLMAP sparse format)
/// - images.txt (COLMAP sparse format)
/// - points3D.txt (COLMAP sparse format)
/// - session_metadata.json (full Kosmos3D metadata)
class ExportService {

  /// Export a complete COLMAP-compatible dataset to a directory.
  /// Returns the path to the export directory.
  Future<String> exportSession({
    required String projectName,
    required String projectId,
    required List<TrajectoryPoint> trajectory,
    required List<String> connectedCameraIds,
    required RigGeometryService rigService,
    required Map<String, String> cameraSettings,
    String captureMode = 'photo',
    double focalLengthPx = 3200,
    int imageWidth = 3840,
    int imageHeight = 2160,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${appDir.path}/kosmos3d_exports/$projectId');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    // Create sparse/0 directory for COLMAP
    final sparseDir = Directory('${exportDir.path}/sparse/0');
    if (!await sparseDir.exists()) {
      await sparseDir.create(recursive: true);
    }

    // Create images directory placeholder
    final imagesDir = Directory('${exportDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    // 1. Generate transforms.json (NeRF / 3DGS)
    final transformsJson = _generateTransformsJson(
      trajectory: trajectory,
      connectedCameraIds: connectedCameraIds,
      rigService: rigService,
      focalLengthPx: focalLengthPx,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    await File('${exportDir.path}/transforms.json')
        .writeAsString(transformsJson);

    // 2. Generate COLMAP cameras.txt
    final camerasTxt = _generateCamerasTxt(
      cameraCount: connectedCameraIds.length,
      focalLengthPx: focalLengthPx,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    await File('${sparseDir.path}/cameras.txt').writeAsString(camerasTxt);

    // 3. Generate COLMAP images.txt
    final imagesTxt = _generateImagesTxt(
      trajectory: trajectory,
      connectedCameraIds: connectedCameraIds,
      rigService: rigService,
    );
    await File('${sparseDir.path}/images.txt').writeAsString(imagesTxt);

    // 4. Generate COLMAP points3D.txt (empty placeholder — SfM fills this)
    await File('${sparseDir.path}/points3D.txt').writeAsString(
      '# 3D point list with one line of data per point:\n'
      '# POINT3D_ID, X, Y, Z, R, G, B, ERROR, TRACK[] as (IMAGE_ID, POINT2D_IDX)\n'
      '# Number of points: 0, mean track length: 0\n'
    );

    // 5. Generate full session metadata JSON
    final metadataJson = _generateMetadataJson(
      projectName: projectName,
      projectId: projectId,
      trajectory: trajectory,
      connectedCameraIds: connectedCameraIds,
      rigService: rigService,
      cameraSettings: cameraSettings,
      captureMode: captureMode,
      focalLengthPx: focalLengthPx,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    await File('${exportDir.path}/session_metadata.json')
        .writeAsString(metadataJson);

    // 6. Generate trajectory CSV
    final csv = _generateTrajectoryCsv(trajectory);
    await File('${exportDir.path}/trajectory.csv').writeAsString(csv);

    // 7. Generate rig_config.json
    final rigJson = const JsonEncoder.withIndent('  ').convert({
      'format': 'kosmos3d_rig',
      'version': '2.0',
      'cameras': rigService.cameras.map((c) => c.toJson()).toList(),
      'naming_template': rigService.namingTemplate,
    });
    await File('${exportDir.path}/rig_config.json').writeAsString(rigJson);

    debugPrint('Export complete: ${exportDir.path}');
    return exportDir.path;
  }

  /// Generate transforms.json in NeRF / 3D Gaussian Splatting format.
  /// Compatible with nerfstudio, instant-ngp, and 3DGS pipelines.
  String _generateTransformsJson({
    required List<TrajectoryPoint> trajectory,
    required List<String> connectedCameraIds,
    required RigGeometryService rigService,
    required double focalLengthPx,
    required int imageWidth,
    required int imageHeight,
  }) {
    final frames = <Map<String, dynamic>>[];

    final refLat = trajectory.isNotEmpty ? trajectory.first.latitude : 0;
    final refLon = trajectory.isNotEmpty ? trajectory.first.longitude : 0;
    final refAlt = trajectory.isNotEmpty ? trajectory.first.altitude : 0;

    for (final point in trajectory) {
      final phoneHeadingRad = point.heading * pi / 180;
      final phonePosX = (point.longitude - refLon) * 111320 * cos(refLat * pi / 180);
      final phonePosY = point.altitude - refAlt;
      final phonePosZ = (point.latitude - refLat) * 110540;

      for (final camId in connectedCameraIds) {
        final rigCam = rigService.cameras.firstWhere(
          (c) => c.cameraId == camId,
          orElse: () => RigCamera(cameraId: camId, label: camId),
        );

        final cosH = cos(phoneHeadingRad);
        final sinH = sin(phoneHeadingRad);
        final worldX = phonePosX + rigCam.offsetX * cosH - rigCam.offsetZ * sinH;
        final worldY = phonePosY + rigCam.offsetY;
        final worldZ = phonePosZ + rigCam.offsetX * sinH + rigCam.offsetZ * cosH;

        final camYaw = (point.heading + rigCam.rotYaw) * pi / 180;
        final camPitch = rigCam.rotPitch * pi / 180;
        final camRoll = rigCam.rotRoll * pi / 180;

        // Full rotation matrix: Rz(yaw) * Ry(pitch) * Rx(roll) — OpenGL convention
        final cy = cos(camYaw), sy = sin(camYaw);
        final cp = cos(camPitch), sp = sin(camPitch);
        final cr = cos(camRoll), sr = sin(camRoll);

        final transform = [
          [cy*cp, cy*sp*sr - sy*cr, cy*sp*cr + sy*sr, worldX],
          [sy*cp, sy*sp*sr + cy*cr, sy*sp*cr - cy*sr, worldY],
          [-sp,   cp*sr,            cp*cr,             worldZ],
          [0.0,   0.0,              0.0,               1.0],
        ];

        final fileName = rigService.generateFileName(
          projectName: 'images',
          cameraLabel: rigCam.label,
          index: point.index,
        );

        frames.add({
          'file_path': 'images/$fileName',
          'transform_matrix': transform,
          'camera_id': camId,
          'camera_label': rigCam.label,
          'capture_index': point.index,
          'timestamp': point.timestamp.toIso8601String(),
          'gps': {
            'latitude': point.latitude,
            'longitude': point.longitude,
            'altitude': point.altitude,
          },
        });
      }
    }

    return const JsonEncoder.withIndent('  ').convert({
      'camera_angle_x': 2 * atan(imageWidth / (2 * focalLengthPx)),
      'camera_angle_y': 2 * atan(imageHeight / (2 * focalLengthPx)),
      'fl_x': focalLengthPx,
      'fl_y': focalLengthPx,
      'k1': 0.0, 'k2': 0.0, 'p1': 0.0, 'p2': 0.0,
      'cx': imageWidth / 2.0,
      'cy': imageHeight / 2.0,
      'w': imageWidth,
      'h': imageHeight,
      'aabb_scale': 16,
      'frames': frames,
    });
  }

  /// Generate COLMAP cameras.txt — one PINHOLE camera per GoPro.
  String _generateCamerasTxt({
    required int cameraCount,
    required double focalLengthPx,
    required int imageWidth,
    required int imageHeight,
  }) {
    final buf = StringBuffer();
    buf.writeln('# Camera list with one line of data per camera:');
    buf.writeln('#   CAMERA_ID, MODEL, WIDTH, HEIGHT, PARAMS[]');
    buf.writeln('# Number of cameras: $cameraCount');
    for (int i = 0; i < cameraCount; i++) {
      // PINHOLE model: fx, fy, cx, cy
      buf.writeln('${i + 1} PINHOLE $imageWidth $imageHeight '
          '$focalLengthPx $focalLengthPx '
          '${imageWidth / 2.0} ${imageHeight / 2.0}');
    }
    return buf.toString();
  }

  /// Generate COLMAP images.txt — one line per image with pose.
  String _generateImagesTxt({
    required List<TrajectoryPoint> trajectory,
    required List<String> connectedCameraIds,
    required RigGeometryService rigService,
  }) {
    final buf = StringBuffer();
    buf.writeln('# Image list with two lines of data per image:');
    buf.writeln('#   IMAGE_ID, QW, QX, QY, QZ, TX, TY, TZ, CAMERA_ID, NAME');
    buf.writeln('#   POINTS2D[] as (X, Y, POINT3D_ID)');

    final refLat = trajectory.isNotEmpty ? trajectory.first.latitude : 0;
    final refLon = trajectory.isNotEmpty ? trajectory.first.longitude : 0;
    final refAlt = trajectory.isNotEmpty ? trajectory.first.altitude : 0;

    int imageId = 1;
    for (final point in trajectory) {
      final phoneHeadingRad = point.heading * pi / 180;
      final phonePosX = (point.longitude - refLon) * 111320 * cos(refLat * pi / 180);
      final phonePosY = point.altitude - refAlt;
      final phonePosZ = (point.latitude - refLat) * 110540;

      for (int camIdx = 0; camIdx < connectedCameraIds.length; camIdx++) {
        final camId = connectedCameraIds[camIdx];
        final rigCam = rigService.cameras.firstWhere(
          (c) => c.cameraId == camId,
          orElse: () => RigCamera(cameraId: camId, label: camId),
        );

        final cosH = cos(phoneHeadingRad);
        final sinH = sin(phoneHeadingRad);
        final worldX = phonePosX + rigCam.offsetX * cosH - rigCam.offsetZ * sinH;
        final worldY = phonePosY + rigCam.offsetY;
        final worldZ = phonePosZ + rigCam.offsetX * sinH + rigCam.offsetZ * cosH;

        final camYaw = (point.heading + rigCam.rotYaw) * pi / 180;
        // Convert yaw to quaternion (simplified — yaw-only rotation)
        final qw = cos(camYaw / 2);
        final qx = 0.0;
        final qy = sin(camYaw / 2);
        final qz = 0.0;

        final fileName = rigService.generateFileName(
          projectName: 'images',
          cameraLabel: rigCam.label,
          index: point.index,
        );

        // Image line: ID QW QX QY QZ TX TY TZ CAMERA_ID NAME
        buf.writeln('$imageId ${qw.toStringAsFixed(8)} ${qx.toStringAsFixed(8)} '
            '${qy.toStringAsFixed(8)} ${qz.toStringAsFixed(8)} '
            '${worldX.toStringAsFixed(6)} ${worldY.toStringAsFixed(6)} '
            '${worldZ.toStringAsFixed(6)} ${camIdx + 1} $fileName');
        // Empty points2D line
        buf.writeln('');

        imageId++;
      }
    }
    return buf.toString();
  }

  /// Full Kosmos3D session metadata
  String _generateMetadataJson({
    required String projectName,
    required String projectId,
    required List<TrajectoryPoint> trajectory,
    required List<String> connectedCameraIds,
    required RigGeometryService rigService,
    required Map<String, String> cameraSettings,
    required String captureMode,
    required double focalLengthPx,
    required int imageWidth,
    required int imageHeight,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'kosmos3d_session',
      'version': '3.0',
      'project': {
        'name': projectName,
        'id': projectId,
        'capture_mode': captureMode,
        'exported_at': DateTime.now().toIso8601String(),
      },
      'camera_hardware': {
        'settings': cameraSettings,
        'intrinsics': {
          'model': 'PINHOLE',
          'fx': focalLengthPx,
          'fy': focalLengthPx,
          'cx': imageWidth / 2.0,
          'cy': imageHeight / 2.0,
          'width': imageWidth,
          'height': imageHeight,
        },
        'camera_count': connectedCameraIds.length,
        'camera_ids': connectedCameraIds,
      },
      'rig': {
        'cameras': rigService.cameras.map((c) => c.toJson()).toList(),
        'naming_template': rigService.namingTemplate,
      },
      'capture_count': trajectory.length,
      'total_images': trajectory.length * connectedCameraIds.length,
      'files': {
        'transforms': 'transforms.json',
        'colmap_cameras': 'sparse/0/cameras.txt',
        'colmap_images': 'sparse/0/images.txt',
        'colmap_points': 'sparse/0/points3D.txt',
        'trajectory_csv': 'trajectory.csv',
        'rig_config': 'rig_config.json',
      },
      'compatible_with': [
        'COLMAP',
        'nerfstudio',
        'instant-ngp',
        '3D Gaussian Splatting',
        'Reality Capture',
        'Metashape',
      ],
    });
  }

  /// CSV export of trajectory data
  String _generateTrajectoryCsv(List<TrajectoryPoint> trajectory) {
    final buf = StringBuffer();
    buf.writeln('index,timestamp,lat,lon,alt,heading,gps_heading,speed_ms,'
        'accuracy_m,pressure_hpa,ax,ay,az,gx,gy,gz,mx,my,mz');
    for (final p in trajectory) {
      buf.writeln(
        '${p.index},${p.timestamp.toIso8601String()},'
        '${p.latitude},${p.longitude},${p.altitude},'
        '${p.heading.toStringAsFixed(2)},${p.gpsHeading.toStringAsFixed(2)},'
        '${p.speed.toStringAsFixed(3)},${p.accuracy.toStringAsFixed(2)},'
        '${p.pressure.toStringAsFixed(2)},'
        '${p.accelX.toStringAsFixed(4)},${p.accelY.toStringAsFixed(4)},${p.accelZ.toStringAsFixed(4)},'
        '${p.gyroX.toStringAsFixed(4)},${p.gyroY.toStringAsFixed(4)},${p.gyroZ.toStringAsFixed(4)},'
        '${p.magX.toStringAsFixed(4)},${p.magY.toStringAsFixed(4)},${p.magZ.toStringAsFixed(4)}'
      );
    }
    return buf.toString();
  }

  /// Get the list of exported files in a directory for sharing/download.
  Future<List<FileExportItem>> getExportedFiles(String exportPath) async {
    final dir = Directory(exportPath);
    if (!await dir.exists()) return [];

    final items = <FileExportItem>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();
        final relativePath = entity.path.replaceFirst('${dir.path}/', '');
        items.add(FileExportItem(
          path: entity.path,
          name: relativePath,
          sizeBytes: stat.size,
        ));
      }
    }
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }
}

/// Represents a single exported file
class FileExportItem {
  final String path;
  final String name;
  final int sizeBytes;

  FileExportItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  String get sizeFormatted {
    if (sizeBytes > 1048576) return '${(sizeBytes / 1048576).toStringAsFixed(1)} MB';
    if (sizeBytes > 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '$sizeBytes B';
  }
}
