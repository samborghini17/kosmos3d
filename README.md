<p align="center">
  <img src="assets/icon/app_icon.png" width="112" alt="KOSMOS 3D mark" />
</p>

<h1 align="center">KOSMOS 3D</h1>

<p align="center">
  <strong>Capture the real world. Keep every frame.</strong><br />
  A local-first multi-GoPro companion for photogrammetry, Gaussian splatting, and 3D scan capture.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-mobile-55FC27?style=flat-square&labelColor=0A0C0B" />
  <img alt="Android and iOS" src="https://img.shields.io/badge/Android%20%2B%20iOS-native%20integrations-55FC27?style=flat-square&labelColor=0A0C0B" />
  <img alt="Local first" src="https://img.shields.io/badge/Data-local--first-55FC27?style=flat-square&labelColor=0A0C0B" />
  <img alt="English default" src="https://img.shields.io/badge/Language-English%20%2B%20Deutsch-55FC27?style=flat-square&labelColor=0A0C0B" />
</p>

<p align="center">
  <a href="#the-capture-loop">Capture loop</a> ·
  <a href="#whats-in-the-rig">Capabilities</a> ·
  <a href="#get-running">Get running</a> ·
  <a href="#windows-receiver">Windows receiver</a> ·
  <a href="#trust-boundaries">Limits</a>
</p>

---

> **KOSMOS mode** · dark surfaces · electric green actions · quiet, dependable tooling.
>
> KOSMOS 3D is designed to make a many-camera scan feel like one deliberate capture session: connect, align, capture, import, preserve, hand off.

## The capture loop

```text
 GO PROs                         KOSMOS 3D                         YOUR PIPELINE
 ────────                        ─────────                         ─────────────
 BLE discovery ───────────────▶  Connect & check readiness
 shared profile ──────────────▶  Apply compatible settings
 shutter / interval ──────────▶  Coordinate capture
 direct camera Wi-Fi ─────────▶  Import + checksum receipt  ────▶  Windows / B2 / reconstruction
 phone motion + position ─────▶  Project sensor metadata
 iPhone LiDAR (supported) ────▶  Measured depth preview + PLY
```

KOSMOS is intentionally **local first**. Project media and sensor data remain on the device until you decide to export or upload them. The included receiver stores and verifies files; it does not pretend to run COLMAP or generate a Gaussian splat.

## What's in the rig

| Surface | Designed for | What it does now |
| --- | --- | --- |
| **Cameras** | Multi-GoPro control | BLE discovery, connection, readiness, shared capture profiles, photo/video dispatch |
| **Outdoor Scan** | A dependable default | Photo · Linear · portrait guidance · target ISO 100 · 1-second host-paced interval |
| **Transfers** | Leave no camera behind | Sequential direct-Wi-Fi import from every connected camera, per-file checksums, clear partial-failure reporting |
| **Coverage** | Better field decisions | LiDAR depth preview on supported iPhones; clearly labelled approximate orientation/GPS aid elsewhere |
| **Sensors** | Better reconstruction context | GPS, accelerometer, gyroscope, magnetometer, barometer where available, and orientation metadata |
| **Projects** | Clean hand-off | Project-scoped captures, receipts, sensor data, local export, Windows receiver, or Backblaze B2 |
| **Language** | A clear baseline | English by default; German available |

### Made for the field

<table>
  <tr>
    <td width="33%"><strong>01 · CONNECT</strong><br /><sub>Discover cameras over BLE and see their readiness before you start.</sub></td>
    <td width="33%"><strong>02 · CAPTURE</strong><br /><sub>Apply a considered profile and run a coordinated photo or video session.</sub></td>
    <td width="33%"><strong>03 · PRESERVE</strong><br /><sub>Import original media, verify it, and keep a project receipt.</sub></td>
  </tr>
</table>

## Get running

### 1. Build the app

**You need:** Flutter 3.11+, a real Android/iOS device with Bluetooth LE, and compatible GoPro cameras. Build iOS on a Mac with Xcode.

```bash
git clone https://github.com/samborghini17/kosmos3d.git
cd kosmos3d
flutter pub get
flutter run
```

### 2. Start a scan

1. Turn on the cameras and enable their wireless connections.
2. In KOSMOS 3D, open **Cameras**, scan, then connect each camera.
3. Pick **Outdoor Scan** or a scene-specific profile.
4. Apply the profile to all cameras and resolve any reported incompatibility.
5. Start the project only when every camera is ready.
6. When finished, use **Transfers → Import all cameras**.

The app may request Bluetooth, nearby-device, location, local-network, Wi-Fi, photo-library, or camera permission depending on the platform and feature.

## Transfer design

### Camera → phone

KOSMOS reads the camera Wi-Fi credentials over the supported control path, shows the password only on demand, and joins **one camera at a time** for reliable direct import. It verifies the endpoint identity before fetching files.

<details>
<summary><strong>Why not make GoPro Wi-Fi open?</strong></summary>
<br />
Camera Wi-Fi access is deliberately protected. KOSMOS makes access quick by revealing/copying the password and joining through platform Wi-Fi APIs; it does not weaken camera security or write Wi-Fi secrets into source control.
</details>

### Phone → receiver

The receiver accepts authenticated uploads, preserves project-relative paths, and validates SHA-256 checksums. It is a transfer endpoint, not a reconstruction server.

## Windows receiver

Run the local receiver on the computer that will hold your projects:

```powershell
cd server
.\start_receiver.ps1 -Storage D:\KOSMOS3D_UPLOADS -Port 8787
```

The first run creates a random token at `%LOCALAPPDATA%\KOSMOS3D\receiver-token.txt`. Enter your computer’s LAN address (for example, `http://192.168.x.x:8787`) and that token in the app. Keep the token private.

For an Android phone connected by USB during development:

```powershell
adb reverse tcp:8787 tcp:8787
```

Then use `http://127.0.0.1:8787` in the app. See [server/README.md](server/README.md) for the receiver API, storage layout, and firewall notes.

## Backblaze B2

Use a dedicated bucket and a **restricted, bucket-scoped application key**. Never put a master key in the app, a README, a screenshot, an issue, or Git history. If a credential is exposed, revoke it and create a new restricted key.

## Trust boundaries

KOSMOS prefers an honest status over a reassuring fiction.

| What KOSMOS does | What it does not claim |
| --- | --- |
| Dispatches BLE capture commands concurrently | Hardware genlock or proof of identical exposure time |
| Shows LiDAR points on supported iPhones | A certified image-overlap or reconstruction-quality score |
| Offers rule-based capture guidance | A trained “smart capture AI” |
| Imports direct camera Wi-Fi media | Universal shared-hotspot/COHN provisioning across all models |
| Queries capabilities and applies documented controls | Universal numerical ISO, shutter, or white-balance mapping across every firmware |

Always validate discovery, permissions, camera compatibility, transfer recovery, and timing on the physical rig before a paid or irreversible shoot.

## Platform notes

- **iPhone / iPad:** LiDAR capture is available only on supported Pro hardware. Native Wi-Fi join, Photos export, and ARKit scene-depth integration are included. See [ios/BUILD.md](ios/BUILD.md).
- **Android:** Native Wi-Fi binding keeps camera-local traffic on the camera network while transferring media.
- **GoPro:** Support depends on the model and firmware’s Open GoPro capabilities. KOSMOS detects what is available instead of inventing unsafe setting values.

## Verify the build

```bash
flutter analyze
flutter test
python -m unittest discover -s server -p "test_*.py"
```

## Reference material

- [Open GoPro documentation](https://gopro.github.io/OpenGoPro/)
- [Flutter](https://flutter.dev/)
- [ARKit scene depth](https://developer.apple.com/documentation/arkit/arconfiguration/framesemantics-swift.struct/scenedepth?language=objc)

## License

See [LICENSE](LICENSE), if present in this repository.
