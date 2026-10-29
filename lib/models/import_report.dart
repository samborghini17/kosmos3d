class CameraImportResult {
  final String cameraId, cameraName;
  final int found, imported;
  final String? error;
  const CameraImportResult(
    this.cameraId,
    this.cameraName, {
    this.found = 0,
    this.imported = 0,
    this.error,
  });
  bool get complete => error == null && found == imported;
}

class ImportReport {
  final List<CameraImportResult> cameras;
  final String destination;
  const ImportReport(this.cameras, this.destination);
  int get imported => cameras.fold(0, (n, c) => n + c.imported);
  bool get complete => cameras.isNotEmpty && cameras.every((c) => c.complete);
}
