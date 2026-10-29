# KOSMOS 3D

**A local-first multi-GoPro capture and transfer companion for photogrammetry, Gaussian splatting, and 3D scan workflows.**

KOSMOS 3D coordinates compatible GoPro cameras over Bluetooth Low Energy (BLE), imports camera media over each camera's direct Wi-Fi network, records useful phone sensor data, and keeps a project together for upload or external reconstruction.

It is a capture and data-management tool. It does **not** claim to reconstruct a COLMAP project or Gaussian splat on the phone or on the included Windows receiver.

## What works today

- Discover and connect compatible GoPro cameras with BLE.
- Configure a shared capture profile, check readiness, and dispatch photo/video capture to the connected cameras.
- Use the default **Outdoor Scan** profile: Photo, Linear, portrait orientation guidance, target ISO 100, and a 1-second host-paced interval.
- Import all available media from each connected camera, one camera at a time, over its direct Wi-Fi network. Camera SD cards are never altered.
- Display a camera Wi-Fi password on demand and copy it; the app does not remove camera security or store the password in source control.
- Keep checksum receipts for imported files, detect same-size corruption, preserve files when gallery export fails, and report partial imports clearly.
- Record GPS, accelerometer, gyroscope, magnetometer, barometer (when available), and orientation metadata alongside a scan project.
- On LiDAR-capable iPhones, capture ARKit scene-depth samples and export a PLY preview. On devices without LiDAR, show an explicitly approximate orientation/GPS coverage aid.
- Upload a project to the included authenticated Windows receiver, or configure Backblaze B2 with a bucket-scoped application key stored in device secure storage.
- English is the default interface language; German is available.

## Important limits

- BLE commands are sent concurrently, but this is **not hardware genlock**. Do not treat a dispatch time as proof that all shutters exposed at the same instant. Validate timing with your own rig and use a hardware sync solution where exposure precision matters.
- The coverage view is a measured depth preview on supported LiDAR iPhones and an approximate aid otherwise. It is not a certified reconstruction-quality or GoPro image-overlap analysis.
- “Capture guidance” is rule-based movement/orientation feedback. It is not a trained smart-capture AI.
- Direct camera Wi-Fi transfer is the dependable current approach. Shared-phone-hotspot/COHN provisioning has model-specific security and certificate requirements and is not presented as implemented.
- Capability support varies by camera model and firmware. The app discovers capabilities and avoids sending undocumented ISO, shutter, or white-balance values as if they were universally valid.
- Build and test iOS on a Mac with Xcode; Windows cannot produce a signed iOS IPA.

## Quick start

### Requirements

- Flutter SDK 3.11 or later
- Android device with Bluetooth LE for Android testing
- GoPro camera with Open GoPro-compatible BLE and Wi-Fi control
- A Mac with Xcode for iOS builds

```bash
git clone https://github.com/samborghini17/kosmos3d.git
cd kosmos3d
flutter pub get
flutter run
```

### Camera workflow

1. Turn on the cameras and enable their wireless connections.
2. Open **Cameras** in KOSMOS 3D, scan, and connect each camera.
3. Select **Outdoor Scan** or create a preset appropriate to the scene.
4. Apply the profile to every connected camera and resolve any reported incompatibility.
5. Start a project. Use interval capture only after confirming every camera is ready.
6. Open **Transfers** when capture is complete and choose **Import all cameras**. KOSMOS connects to each camera’s direct Wi-Fi in turn, verifies its identity, and imports its media.

The operating system may request Bluetooth, nearby-device, location, local-network, Wi-Fi, photo-library, or camera permission depending on the feature and platform.

## Windows project receiver

The receiver is a small authenticated file server. It stores uploaded project files and validates checksums; it does not run reconstruction.

```powershell
cd server
.\start_receiver.ps1 -Storage D:\KOSMOS3D_UPLOADS -Port 8787
```

On first start it creates a random local token in `%LOCALAPPDATA%\KOSMOS3D\receiver-token.txt`. Configure the phone with the computer’s LAN address, for example `http://192.168.x.x:8787`, and that token. Keep the token out of Git and out of screenshots.

For USB-connected Android development, use:

```powershell
adb reverse tcp:8787 tcp:8787
```

Then configure the app with `http://127.0.0.1:8787`. See [server/README.md](server/README.md) for the receiver API and firewall notes.

## Backblaze B2

Create a dedicated bucket and use a restricted application key with only the required bucket/file permissions. Do not use a master key in a mobile app, README, issue, screenshot, or commit. If a credential was shared accidentally, revoke it in Backblaze and create a new restricted key.

## iOS

The iOS target includes the permissions and native integrations needed for direct Wi-Fi joining, Photos export, and ARKit scene-depth capture on supported Pro devices. Build instructions and acceptance checks are in [ios/BUILD.md](ios/BUILD.md).

## Architecture

```text
lib/
  screens/       Capture, camera manager, projects, transfer hub, settings
  services/      GoPro BLE/Wi-Fi, capture coordination, import, upload, sensors
  models/        Cameras, projects, capture points, import reports
  l10n/          English-default UI dictionary and German translations
server/          Authenticated Windows receiver and tests
ios/             Wi-Fi, gallery, and LiDAR platform integration
android/         Wi-Fi binding, media/gallery, and preview integration
```

## Verification

```bash
flutter analyze
flutter test
python -m unittest discover -s server -p "test_*.py"
```

Hardware validation is still essential: test discovery, permission prompts, every intended GoPro/firmware profile, media transfer, Wi-Fi recovery, and capture timing on the physical rig before a production shoot.

## References

- [Open GoPro documentation](https://gopro.github.io/OpenGoPro/)
- [Flutter](https://flutter.dev/)
- [ARKit scene depth](https://developer.apple.com/documentation/arkit/arconfiguration/framesemantics-swift.struct/scenedepth?language=objc)

## License

See [LICENSE](LICENSE), if present in this repository.
