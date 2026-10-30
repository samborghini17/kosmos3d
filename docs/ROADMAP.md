# KOSMOS 3D: v2 review and roadmap

Review of `main` at `3332414` (28 Oct 2026), tested on a Xiaomi 25078PC3EE (Android 16) with two GoPro HERO13 Black on 30 Oct 2026. Priorities: **P0** blocks real use or store release, **P1** makes the app clearly better, **P2** makes it outstanding.

## 1. Fixed in v2 (this branch)

| Area | Problem found | Fix |
| --- | --- | --- |
| Camera settings | Capability replies list one entry per supported value; the decoder kept only the last one. On real cameras almost every setting write failed with "does not support setting". | `decodeTlvMulti`; test now models the real reply format. Verified on HERO13. |
| Video sync | Video preparation wrote `0` to *Video duration* and *HindSight*. Valid values are `100` (no limit) and `4` (off). | Correct values, and only written when the camera offers them. |
| HERO13 frame rate | HERO13 reports frame rate as setting **234**, the app only wrote **3**. Video presets would fail. | Writes whichever of 3/234 the camera supports. |
| Media import | One photo group whose count disagreed with the camera's listing ("Incomplete media group inventory: GPAA0062.JPG") blocked the whole camera. Reproduced on HERO13. | Members are listed and verified one by one; mismatches are flagged, not fatal. |
| Bluetooth scan | First scan after opening Cameras found nothing (scan started before the adapter was ready, results subscribed after start). | Waits for adapter, subscribes first, scans 10 s. |
| Upload | Backblaze-only native API; only top-level files in `captures/` were uploaded (sensor logs, LiDAR, receipts and subfolders were skipped); uploads ran silently with no progress or result. Earlier failure was a bucket field of `-`. | Generic S3 (SigV4) client for any provider, whole project folder, resumable by size check, progress dialog, readable errors. Live-tested against the `kosmos3d` bucket. |
| German | 399 visible strings stayed English, including every status and error message. | 600+ entries, templates for messages with live values, error-prefix handling, line-by-line status translation, catalog setting names. Tests guard it. |
| Coverage viewer | The 966-line interactive viewer was never shown anywhere. Non-LiDAR phones got a static drawing. | Wired into the capture screen. Misleading "LOOP CLOSED • 3DGS READY" label replaced. |
| Dead buttons | "Connect all to hotspot" always threw. "Format SD Card" always threw. | Replaced with *All camera settings* and *Wi-Fi password*. |
| Device Manager | Camera-networks banner text squashed to one word per line; hard-coded white text broke light mode. | Two-row layout using theme colours. |
| Assets | `assets/logo.png` was an empty file. | Real PNG. Five logo options in `docs/brand/`. |
| Repo | `.dart_tool/` and `build_log.txt` were tracked. | Untracked and ignored. |
| Versioning | App said v1.0.0 with build number lower than the installed one. | 2.0.0+3. |

New in v2: **All camera settings** (every Open GoPro setting the rig shares, apply-to-all with read-back, highlights cameras that differ), **Camera networks** (all Wi-Fi passwords over BLE, Wi-Fi QR, one-tap join, import all), camera clocks set to phone time on connect, ISO/white-balance/clock Labs QR, CI that builds an Android APK and an unsigned iOS IPA.

## 2. What "Smart Capture AI" actually is

The project toggle (now labelled *Capture guidance*) runs a few rules on the phone's compass and GPS: largest heading gap, angle to the previous shot, walking speed. It shows a hint and nothing else. There is no AI and no image analysis. Options:

- **Keep and rename** to *Coverage hints* (done in the text), or
- **Replace** with real image-based checks (blur, exposure, overlap) as described in P1 below. That would earn the name.

## 3. Remove or merge

- **`SplashScreen`** is never shown. Delete it, or show it during the first permission check.
- **`export_screen.dart` "WiFi Auto-Download"** duplicates the import dialog and tells users to join Wi-Fi manually. Remove that card; link to Camera networks.
- **Two upload settings sections** (Storage server and KOSMOS receiver, each with its own auto-upload switch). Merge into one *Upload destination* list with a single auto-upload choice.
- **`app_translations.dart` + `ui_dictionary.dart` + `ui_dictionary_v2.dart`**: three translation mechanisms. Move to Flutter `gen_l10n` ARB files before adding a third language.
- **`capture_session.dart` "Sync captures via Hotspot"** button calls the per-camera Wi-Fi import. Rename to *Import from cameras*.
- **Legacy compatibility methods** in `gopro_service.dart` (`toggleRecording`, `setFlatMode`, `connectAllToHotspot`, `connectToHotspot`) are unused or always throw.
- **Hard-coded dark colours** (`Color(0xFF1E1E1E)`, `Colors.white70`) in gallery, export and dialogs break light mode.
- **`instructions.md`** is an agent prompt, not project documentation. Move it out of the repo root.

## 4. Roadmap

### P0: needed before store release

1. **Phone-hotspot download from all cameras at once (HERO12/13 COHN).** Over BLE: scan networks (`0x02/0x02`), connect camera to the phone hotspot (`0x02/0x05`), create and fetch the COHN certificate (`0xF1/0x67`, `0x6E`), read IP/username/password (`0x6F`). Then HTTPS to every camera in parallel, pinned to its certificate. HERO11 and older keep the sequential camera-Wi-Fi route. This is the biggest usability win for multi-camera rigs.
2. **Background uploads and imports.** Android foreground service / WorkManager, iOS background `URLSession`. Persistent job list that survives the app being closed; multipart upload for files above 5 GB.
3. **Release signing and store metadata.** Android upload keystore, Play App Signing, iOS distribution certificate, privacy manifest (`PrivacyInfo.xcprivacy`), data-safety form, app-store screenshots, final bundle ID (e.g. `institute.kreativ.kosmos3d`).
4. **Permissions flow.** One onboarding screen that explains and requests Bluetooth, location, local network, photos. Today permissions pop up mid-task.
5. **Physical acceptance matrix.** HERO9–13 single and mixed, low battery, full card, disconnect at each step, 500-shot sessions, app in background. Record results in the repo.
6. **Known cameras.** Remember connected cameras (serial, name, position on rig). Reconnect them automatically. Show bonded cameras even when the scan misses them.
7. **Project-scoped import.** Record the SD card file list when a project starts. "Import" then means "this project's files" by default, not the whole card.

### P1: makes it clearly better

8. **Rig presets per camera model.** Save the full settings table from *All camera settings* as a named rig profile and apply it in one tap. Export/import as QR or file for a second phone.
9. **Exposure check after the first shot.** Download one thumbnail per camera (`/gopro/media/screennail`), compare brightness, white balance and sharpness across cameras, warn before the scan continues.
10. **Live blur and overlap hints.** On-device feature matching between consecutive thumbnails (ORB via `opencv_dart`) gives real overlap percentages instead of heading guesses.
11. **Shutter skew measurement.** Point all cameras at the phone showing a millisecond clock, capture, read the clock in each image (OCR), store the per-camera offset with the project.
12. **GPMF extraction.** HERO cameras write their own IMU, GPS and exposure time into every file. Parse it on import and merge it with the phone log for exact per-frame timing.
13. **Labs firmware detection.** Detect Labs firmware over BLE (firmware string) and only offer the QR route when present; otherwise guide through the Protune menu.
14. **Battery and storage dashboard** for the whole rig with warnings before a project starts (lowest battery, least space, estimated shots left).
15. **Stable camera order.** Assign each camera a rig position once (front-left, top, ...). Use it in file names, in exports and in the COLMAP rig config.
16. **Export packages** for RealityCapture, Metashape, COLMAP (`rig_config.json` with fixed relative poses), Nerfstudio and Postshot, created from imported files plus sensor priors.
17. **Upload to the receiver while capturing** (when the phone has a second network), so nothing waits for the end.

### P2: makes it outstanding

18. **Lixel-style live coverage.** Model after XGRIDS Lixel's view: a live map of where the rig has been, coloured by how many cameras saw each area and from how many angles; areas seen from only one angle in amber; red where nothing was captured.
    - LiDAR iPhones: ARKit scene reconstruction mesh, each triangle coloured by viewing-angle count from the projected camera frustums (using the rig geometry).
    - Android with ARCore Depth: the same from depth images.
    - Other phones: VIO pose path from ARCore/ARKit instead of GPS (centimetres instead of metres) with frustum footprints on the ground plane.
    - Loop-closure hint when the path returns near its start; floor-level slices for multi-storey buildings.
19. **ARKit/ARCore pose recording** for every shot (6-DoF, timestamped), exported as initial poses. Cuts alignment time and fixes scale.
20. **Phone camera as an extra rig camera** (wide + ultra-wide), triggered with the GoPros.
21. **Generic Bluetooth drivers.** Insta360, DJI Osmo Action, Sony remote protocol, and a generic BLE shutter/trigger (HID). The coordinator already supports any `RigCamera`.
22. **Processing hand-off.** Optional job submission to a self-hosted reconstruction server (COLMAP + gsplat / Postshot CLI) with status and preview download.
23. **Field mode.** Large controls, haptic shot confirmation, audio cues per camera, screen-off capture, Apple Watch / Wear OS remote.
24. **Team mode.** Two phones on one rig (control + monitor), shared project via the receiver.
25. **More languages** once ARB files are in place (French, Spanish, Dutch are the next largest scanning markets in Europe).

## 5. Defaults review

| Setting | Before | Now | Reason |
| --- | --- | --- | --- |
| Language | English | English | as requested |
| Preset | Outdoor Scan | Outdoor Scan | Photo, Standard (no SuperPhoto/HDR processing), Linear, portrait, target ISO 100 |
| Interval | 1 s | 1 s | measured after the slowest camera finishes, never queues |
| Coverage viewer | on, hidden on non-LiDAR phones | on, interactive everywhere | |
| GPS log rate | 2 s | 1 s | phones deliver ~1 Hz fixes; 2 s dropped half |
| IMU rate | 20 Hz | 20 Hz | enough for per-shot attitude; raise to 100 Hz only for video |
| Camera clock | untouched | set to phone time on connect | aligned file timestamps across the rig |
| Control mode | untouched | shown as "Cameras differ" | Pro mode is required for the full settings list; one of the test cameras was in Easy mode |

## 6. License

For an open-source app that will also be sold or distributed through the App Store and Play Store:

- **Apache-2.0** (recommended): permissive like MIT, adds an explicit patent grant and requires changes to be marked. Store-compatible. Does not grant use of the name or logo, so add a short trademark notice to keep "KOSMOS 3D" and the mark yours.
- **MIT** (current): simplest, but anyone can publish a renamed copy with your logo unless you separately protect the name.
- **GPL-3.0 / AGPL-3.0**: forces derivatives to stay open, but conflicts with App Store terms (the VLC case), so not recommended if you publish on iOS.
- **Source-available (e.g. PolyForm Noncommercial)**: if you want to forbid commercial clones entirely. Then it is no longer "open source" in the OSI sense.

Copyright line: `Copyright (c) 2026 Sam Wiemann, Kreativ Institut OWL`.
