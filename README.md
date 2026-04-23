<p align="center">
  <h1 align="center">🌌 KOSMOS 3D</h1>
  <p align="center">
    <strong>Open-Source Multi-Camera Gaussian Splatting Rig Controller</strong>
  </p>
  <p align="center">
    <a href="#features">Features</a> •
    <a href="#getting-started">Getting Started</a> •
    <a href="#architecture">Architecture</a> •
    <a href="#contributing">Contributing</a>
  </p>
</p>

---

**KOSMOS 3D** is a cross-platform mobile application (Android & iOS) for controlling multi-camera rigs designed for photogrammetry and Gaussian Splatting. It turns your fleet of GoPro HERO cameras into a synchronized, professional-grade scanning system — all controlled from your phone via Bluetooth Low Energy.

## Features

### 🎥 Multi-Camera BLE Control
- Discover and connect to 8+ GoPro cameras simultaneously via BLE
- Per-camera settings control (Resolution, FPS, ISO, Shutter, White Balance, Lens, Bitrate)
- Synchronized shutter triggering across all cameras
- Real-time battery and storage monitoring
- Mode switching (Photo / Video / Timelapse)

### 📸 Intelligent Capture Sessions
- **Coverage heatmap**: Real-time 360° visualization of scan completeness
- **AI capture hints**: Directional guidance to fill coverage gaps
- **Trajectory recording**: Full IMU + GPS data recording for post-processing
- **Quality scoring**: Overlap and consistency analysis

### 📂 Project Management
- Create named scan projects with custom camera presets
- Local-first data storage with offline support
- Gallery with batch selection, deletion, and upload
- Trajectory export (JSON / CSV) compatible with COLMAP and Reality Capture

### ☁️ Cloud Storage (Backblaze B2)
- S3-compatible upload to Backblaze B2 buckets
- Secure credential storage (AES-encrypted on-device)
- Batch project upload with progress tracking
- Connection testing and validation

### 🎯 Scanning Presets
- Built-in profiles: Interior, Outdoor, Detail, Video Walk
- Custom preset creation and management
- One-tap apply to all connected cameras

### 🌐 Internationalization
- English (default) and German language support
- Extensible translation system

### 🔮 3D Trajectory Preview
- Interactive 3D visualization of scan trajectory
- Camera frustum rendering
- Touch controls: pan, zoom, rotate

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.11+)
- Android Studio or Xcode
- Physical Android/iOS device (BLE requires real hardware)

### Installation
```bash
git clone https://github.com/samborghini17/kosmos3d.git
cd kosmos3d
flutter pub get
flutter run
```

### GoPro Setup
1. Power on your GoPro HERO cameras
2. Enable **Wireless Connections** in GoPro settings
3. Open KOSMOS 3D → Settings → Device Manager
4. Tap "Scan for Devices"
5. Tap each discovered camera to connect

### Cloud Storage Setup
1. Create a [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html) account
2. Create a bucket and an Application Key (not the master key!)
3. In KOSMOS 3D → Settings → Cloud Storage, enter your credentials
4. Tap "Test Connection" to verify

## Architecture

```
lib/
├── main.dart                  # App entry point with providers
├── l10n/                      # Internationalization
│   └── app_translations.dart
├── models/                    # Data models
│   ├── camera_device.dart
│   └── scan_project.dart
├── providers/                 # State management
│   └── settings_provider.dart
├── screens/                   # UI screens
│   ├── main_menu.dart
│   ├── settings.dart
│   ├── device_manager.dart
│   ├── project_flow.dart
│   ├── capture_session.dart
│   ├── gallery_screen.dart
│   └── point_cloud_preview.dart
├── services/                  # Business logic
│   ├── gopro_service.dart     # GoPro BLE protocol
│   ├── cloud_storage_service.dart
│   ├── project_service.dart
│   ├── trajectory_service.dart
│   └── upload_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    └── glass_card.dart
```

### Design Principles
- **Offline-first**: All data is stored locally. Cloud sync is opt-in.
- **Camera-agnostic**: Hardware interactions are abstracted behind interfaces for future camera support (Sony, DJI, etc.)
- **Privacy-centric**: No telemetry, no tracking. Credentials are AES-encrypted on-device.

## Open GoPro BLE Protocol

KOSMOS 3D implements the [Open GoPro BLE API](https://gopro.github.io/OpenGoPro/) for direct camera control:

| Feature | UUID | Description |
|---------|------|-------------|
| Command | GP-0072 | Send commands (shutter, mode switch) |
| Settings | GP-0074 | Write camera settings (resolution, fps, etc.) |
| Query | GP-0076 | Query camera status (battery, storage) |

## Contributing

Contributions are welcome! This is an open-source project and we'd love your help.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Planned Features
- [ ] WiFi Direct media download from GoPros
- [ ] COLMAP server integration for reconstruction
- [ ] In-app Gaussian Splat / PLY viewer
- [ ] LiDAR fusion (iOS Pro devices)
- [ ] Plugin system for community camera drivers
- [ ] Community preset sharing platform

## License

This project is open source. See [LICENSE](LICENSE) for details.

## Acknowledgments

- [Open GoPro](https://gopro.github.io/OpenGoPro/) — Official BLE/WiFi API
- [Flutter Blue Plus](https://pub.dev/packages/flutter_blue_plus) — BLE library
- [Backblaze B2](https://www.backblaze.com/) — Cloud storage
- Built with ❤️ by the KOSMOS 3D team
