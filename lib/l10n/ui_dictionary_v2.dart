/// German strings added in v2. `{name}` placeholders match any text at runtime,
/// so messages built with interpolation translate as well.
const germanV2 = <String, String>{
  // Camera networks
  '{name} Wi-Fi joined': 'Mit WLAN von {name} verbunden',
  'Read again': 'Neu einlesen',
  'Download from every camera': 'Von allen Kameras herunterladen',
  'The phone joins each camera Wi-Fi in turn, copies all originals into the project and moves on. Passwords are read over Bluetooth, so you never type them.':
      'Das Telefon verbindet sich nacheinander mit jedem Kamera-WLAN, kopiert alle Originale ins Projekt und macht mit der nächsten weiter. Passwörter werden per Bluetooth gelesen, du tippst nichts ein.',
  'iPhone: confirm the "Join network" prompt once per camera. Turn Personal Hotspot off while importing.':
      'iPhone: Die Abfrage „Mit Netzwerk verbinden“ einmal pro Kamera bestätigen. Persönlichen Hotspot während des Imports ausschalten.',
  'Android: confirm the connection prompt once per camera. Mobile data stays available for the rest of the phone.':
      'Android: Die Verbindungsabfrage einmal pro Kamera bestätigen. Mobile Daten bleiben für den Rest des Telefons verfügbar.',
  'Why not the phone hotspot?': 'Warum nicht der Handy-Hotspot?',
  'HERO12 and HERO13 can join a phone hotspot (Camera on Home Network, COHN). Then all cameras are reachable at the same time and can download in parallel. This needs per-camera certificate setup over Bluetooth and is planned for a later version. HERO11 and older only offer their own Wi-Fi, which is what this screen uses.':
      'HERO12 und HERO13 können sich mit einem Handy-Hotspot verbinden (Camera on Home Network, COHN). Dann sind alle Kameras gleichzeitig erreichbar und laden parallel. Dafür ist pro Kamera eine Zertifikatseinrichtung per Bluetooth nötig; das ist für eine spätere Version geplant. HERO11 und älter bieten nur ihr eigenes WLAN, das dieser Bildschirm nutzt.',
  'Open Wi-Fi settings': 'WLAN-Einstellungen öffnen',
  'Join': 'Verbinden',
  'Network': 'Netzwerk',
  'Scan the QR with another phone or laptop camera to join this GoPro directly.':
      'QR-Code mit der Kamera eines anderen Telefons oder Laptops scannen, um direkt mit dieser GoPro zu verbinden.',

  'Wi-Fi passwords, one-tap join and import from every camera':
      'WLAN-Passwörter, Verbinden per Tipp und Import von jeder Kamera',
  'Wi-Fi passwords': 'WLAN-Passwörter',
  'Wi-Fi password': 'WLAN-Passwort',
  'Hotspot settings': 'Hotspot-Einstellungen',

  // Rig settings
  'All camera settings': 'Alle Kameraeinstellungen',
  'Every GoPro setting the connected cameras share, applied to all':
      'Alle Einstellungen, die die verbundenen GoPros gemeinsam haben, auf alle übertragen',
  'Camera clocks set to phone time': 'Kamerauhren auf Telefonzeit gestellt',
  'Shows only options that every connected camera supports in its current mode, so the rig stays identical. Changing a value writes it to every camera and reads it back. Switch mode (photo/video) first: options depend on it.':
      'Zeigt nur Optionen, die jede verbundene Kamera im aktuellen Modus unterstützt, damit das Rig identisch bleibt. Eine Änderung wird auf jede Kamera geschrieben und zurückgelesen. Zuerst den Modus (Foto/Video) wählen: Die Optionen hängen davon ab.',
  'Sync camera clocks': 'Kamerauhren abgleichen',
  'ISO / shutter / white balance (Labs QR)':
      'ISO / Verschluss / Weißabgleich (Labs-QR)',
  'ISO, shutter and white balance are not part of the official Bluetooth API. On cameras with GoPro Labs firmware, show them the Labs QR; otherwise set them once on each camera.':
      'ISO, Verschlusszeit und Weißabgleich sind nicht Teil der offiziellen Bluetooth-Schnittstelle. Kameras mit GoPro-Labs-Firmware den Labs-QR zeigen, sonst einmal an jeder Kamera einstellen.',
  'Value {v}': 'Wert {v}',
  'Cameras differ': 'Kameras abweichend',
  'Choose': 'Wählen',
  'Same exposure on every camera': 'Gleiche Belichtung auf jeder Kamera',
  'GoPro Labs firmware only. Hold the QR in front of each camera until it beeps. Sets ISO, white balance and the camera clock to this phone.':
      'Nur mit GoPro-Labs-Firmware. QR vor jede Kamera halten, bis sie piept. Setzt ISO, Weißabgleich und die Kamerauhr auf dieses Telefon.',
  'White balance': 'Weißabgleich',
  'Stock firmware ignores this code. Then set ISO and white balance once in each camera’s Protune menu.':
      'Die Standard-Firmware ignoriert diesen Code. Dann ISO und Weißabgleich einmal im Protune-Menü jeder Kamera einstellen.',

  // Open GoPro setting names
  'Video resolution': 'Videoauflösung',
  'Frames per second': 'Bilder pro Sekunde',
  'Video timelapse rate': 'Video-Zeitrafferintervall',
  'Photo timelapse rate': 'Foto-Zeitrafferintervall',
  'Nightlapse rate': 'Nachtraffer-Intervall',
  'Webcam digital lenses': 'Webcam-Objektiv',
  'Auto power down': 'Automatisch ausschalten',
  'Video aspect ratio': 'Video-Seitenverhältnis',
  'Time lapse digital lenses': 'Zeitraffer-Objektiv',
  'Media format': 'Medienformat',
  'Hypersmooth': 'HyperSmooth',
  'Video horizon leveling': 'Horizontausgleich Video',
  'Photo horizon leveling': 'Horizontausgleich Foto',
  'Multi shot duration': 'Dauer Serienaufnahme',
  'Max lens': 'Max Lens',
  'Hindsight': 'HindSight',
  'Photo single interval': 'Foto-Einzelintervall',
  'Photo interval duration': 'Dauer Fotointervall',
  'Video performance mode': 'Video-Leistungsmodus',
  'Control mode': 'Steuerungsmodus',
  'Easy mode speed': 'Geschwindigkeit (Einfach-Modus)',
  'Enable night photo': 'Nachtfoto aktivieren',
  'Wireless band': 'Funkband',
  'Star trails length': 'Länge der Sternspuren',
  'System video mode': 'System-Videomodus',
  'Video bit rate': 'Video-Bitrate',
  'Bit depth': 'Farbtiefe',
  'Profiles': 'Profile',
  'Video easy mode': 'Video Einfach-Modus',
  'Lapse mode': 'Zeitraffermodus',
  'Max lens mod': 'Max Lens Mod',
  'Max lens mod enable': 'Max Lens Mod aktivieren',
  'Easy night photo': 'Einfaches Nachtfoto',
  'Multi shot aspect ratio': 'Seitenverhältnis Serienaufnahme',
  'Framing': 'Bildausschnitt',
  'Camera mode': 'Kameramodus',
  'Beep volume': 'Signalton-Lautstärke',
  'Setup screen saver': 'Bildschirmschoner',
  'Setup language': 'Kamerasprache',
  'Video framing': 'Bildausschnitt Video',
  'Multi shot framing': 'Bildausschnitt Serienaufnahme',
  'Auto power on USB': 'Per USB einschalten',
  'Photo mode': 'Fotomodus',

  // Open GoPro option names
  '{n} seconds': '{n} Sekunden',
  '{n} second': '{n} Sekunde',
  '{n} minutes': '{n} Minuten',
  '{n} minute': '{n} Minute',
  '{n} hours': '{n} Stunden',
  '{n} hour': '{n} Stunde',
  'All off': 'Alle aus',
  'All on': 'Alle an',
  'Auto boost': 'Auto-Boost',
  'Auto detect': 'Automatisch erkennen',
  'Back only': 'Nur hinten',
  'Basic quality': 'Einfache Qualität',
  'Extended battery': 'Längere Akkulaufzeit',
  'Front off only': 'Nur vorne aus',
  'Highest quality': 'Höchste Qualität',
  'High': 'Hoch',
  'Low': 'Niedrig',
  'Medium': 'Mittel',
  'Long': 'Lang',
  'Short': 'Kurz',
  'Longest battery': 'Längste Akkulaufzeit',
  'Light painting': 'Lichtmalerei',
  'Max light painting': 'Max Lichtmalerei',
  'Locked': 'Fixiert',
  'Never': 'Nie',
  'No limit': 'Unbegrenzt',
  'None': 'Keine',
  'Night lapse photo': 'Nachtraffer Foto',
  'Night lapse video': 'Nachtraffer Video',
  'Time lapse photo': 'Zeitraffer Foto',
  'Time lapse video': 'Zeitraffer Video',
  'Single lens': 'Ein Objektiv',
  'Standard lens': 'Standardobjektiv',
  'Standard quality': 'Standardqualität',
  'Standard video': 'Standardvideo',
  'Star trails': 'Sternspuren',
  'Max star trails': 'Max Sternspuren',
  'Vehicle lights': 'Fahrzeuglichter',
  'Max vehicle lights': 'Max Fahrzeuglichter',
  'Tripod stationary video': 'Stativ-Video',
  'Maximum video performance': 'Maximale Videoleistung',
  'Ultra wide': 'Ultraweit',
  'Vertical': 'Hochformat',
  'Wide': 'Weit',
  'Narrow': 'Schmal',
  'German': 'Deutsch',
  'English us': 'Englisch (US)',
  'English uk': 'Englisch (UK)',
  'English aus': 'Englisch (AUS)',
  'English ind': 'Englisch (IND)',
  'French': 'Französisch',
  'Italian': 'Italienisch',
  'Spanish': 'Spanisch',
  'Spanish na': 'Spanisch (Nordamerika)',
  'Chinese': 'Chinesisch',
  'Japanese': 'Japanisch',
  'Korean': 'Koreanisch',
  'Portuguese': 'Portugiesisch',
  'Russian': 'Russisch',
  'Swedish': 'Schwedisch',
  'Easy': 'Einfach',

  // Onboarding
  "Attach your phone to the rig's phone mount for accurate sensor tracking (gyroscope, GPS, compass).":
      'Telefon an der Rig-Halterung befestigen, damit Gyroskop, GPS und Kompass die Bewegung korrekt erfassen.',
  "Turn on all GoPro cameras and make sure Wireless Connections are enabled in each camera's settings.":
      'Alle GoPros einschalten und in den Kameraeinstellungen „Drahtlose Verbindungen“ aktivieren.',
  'Go to Device Manager → tap "Scan" → tap each camera to connect. No system Bluetooth pairing needed — the app handles everything!':
      'Geräteverwaltung → „Suchen“ → jede Kamera antippen. Keine Bluetooth-Kopplung im System nötig, die App erledigt das.',
  'Storage server (optional)': 'Speicherserver (optional)',
  'Settings → Storage server: connect your own S3-compatible bucket (Backblaze, AWS, Wasabi, R2, MinIO) or the KOSMOS Windows receiver.':
      'Einstellungen → Speicherserver: eigenen S3-kompatiblen Bucket (Backblaze, AWS, Wasabi, R2, MinIO) oder den KOSMOS-Windows-Empfänger verbinden.',
  'Unknown': 'Unbekannt',
  'Linear': 'Linear',
  'Bitrate': 'Bitrate',
  'Mode': 'Modus',
  'Labs Recipe': 'Labs-Rezept',
  'Bright daylight: ISO 100 on every camera, fixed white balance, portrait mounting. If moving, use a fast photo shutter; in shade add light or raise ISO. Check actual images for blur and clipping.':
      'Helles Tageslicht: ISO 100 auf jeder Kamera, fester Weißabgleich, Hochformat-Montage. In Bewegung eine kurze Verschlusszeit nutzen; im Schatten Licht ergänzen oder ISO erhöhen. Bilder auf Unschärfe und Überbelichtung prüfen.',
  'Use consistent added light and fixed white balance. Pause before each photo; ISO 100 is unsuitable if it produces motion blur or underexposure.':
      'Gleichmäßiges Zusatzlicht und festen Weißabgleich nutzen. Vor jedem Foto kurz anhalten; ISO 100 ist ungeeignet, wenn Bewegungsunschärfe oder Unterbelichtung entsteht.',
  'Move slowly with high overlap. Stay beyond the camera minimum focus distance. Use RAW only if supported with the chosen lens and allow longer processing.':
      'Langsam und mit viel Überlappung bewegen. Mindestabstand der Kamera einhalten. RAW nur nutzen, wenn das Objektiv es unterstützt, und längere Verarbeitung einplanen.',
  'Use a fast shutter in good light and disable stabilization on each camera for consistent calibration. 30 fps reduces heat and redundant frames; 60 fps needs more light and storage.':
      'Bei gutem Licht kurze Verschlusszeit wählen und die Stabilisierung jeder Kamera ausschalten, damit die Kalibrierung konsistent bleibt. 30 fps erzeugt weniger Wärme und doppelte Bilder; 60 fps braucht mehr Licht und Speicher.',
  'Requires GoPro Labs firmware. Inspect the QR recipe on every camera before capture.':
      'Benötigt GoPro-Labs-Firmware. QR-Rezept vor der Aufnahme auf jeder Kamera prüfen.',

  // Capture session
  'Sensor recording failed: {e}': 'Sensoraufzeichnung fehlgeschlagen: {e}',
  'Stop capture before transferring media':
      'Aufnahme beenden, bevor Medien übertragen werden',
  '{n} frames captured.\nProject will be saved.':
      '{n} Bilder aufgenommen.\nDas Projekt wird gespeichert.',
  'Show 3D Scanner HUD': '3D-Scanner-Anzeige einblenden',
  'Live Camera Viewfinder': 'Live-Sucher der Kamera',
  'Sync captures via Hotspot': 'Aufnahmen über Hotspot abgleichen',
  'Cams': 'Kams',
  'Res': 'Aufl.',
  'Heading': 'Richtung',
  'Score': 'Wertung',
  'Heading sweep complete; inspect overlap and surface coverage separately.':
      'Rundumschwenk vollständig; Überlappung und Flächenabdeckung separat prüfen.',
  'Most headings sampled; object coverage is not measured.':
      'Die meisten Richtungen erfasst; die Objektabdeckung wird nicht gemessen.',
  '⚠️ Large gap ({deg}°) between last captures. Move slower.':
      '⚠️ Große Lücke ({deg}°) zwischen den letzten Aufnahmen. Langsamer bewegen.',
  '↔️ Too similar to previous. Rotate more before next capture.':
      '↔️ Zu ähnlich zur vorherigen Aufnahme. Vor der nächsten Aufnahme weiter drehen.',
  '🏃 Moving too fast ({speed} m/s). Slow down for sharp images.':
      '🏃 Zu schnell ({speed} m/s). Für scharfe Bilder langsamer gehen.',
  'Headings sampled. Add different heights and inspect overlap.':
      'Richtungen erfasst. Weitere Höhen ergänzen und Überlappung prüfen.',
  '🧭 Gap {dir} ({deg}°). Turn that way and capture.':
      '🧭 Lücke {dir} ({deg}°). In diese Richtung drehen und aufnehmen.',

  // Device manager
  'Live viewfinder': 'Live-Sucher',
  'Connect All to Hotspot': 'Alle mit Hotspot verbinden',
  'Open Device Hotspot Settings': 'Hotspot-Einstellungen öffnen',
  '📋 Before your first scan:\n1. Mount your phone on the rig\n2. Power on all GoPro cameras\n3. Enable Wireless Connections on each GoPro\n4. Tap "Scan for Devices" above\n5. Tap each camera to connect':
      '📋 Vor dem ersten Scan:\n1. Telefon am Rig befestigen\n2. Alle GoPros einschalten\n3. „Drahtlose Verbindungen“ auf jeder GoPro aktivieren\n4. Oben „Geräte suchen“ antippen\n5. Jede Kamera zum Verbinden antippen',
  'Connected (BLE)': 'Verbunden (BLE)',
  'Tap to connect': 'Zum Verbinden antippen',
  'Video': 'Video',
  'Format': 'Formatieren',
  'WiFi AP': 'WLAN-AP',
  'GPS On': 'GPS an',
  'Locate': 'Orten',
  'Stop': 'Stopp',
  'Auto': 'Auto',

  // Export
  'WiFi Auto-Download': 'Automatischer WLAN-Download',
  "To download media:\n\n1. Connect your phone to the GoPro's WiFi network in Settings.\n2. The app will automatically connect and pull all media via HTTP.\n\nWould you like to start the download process?":
      'Medien herunterladen:\n\n1. Telefon in den Einstellungen mit dem WLAN der GoPro verbinden.\n2. Die App verbindet sich und lädt alle Medien per HTTP.\n\nDownload jetzt starten?',
  'Starting WiFi transfer from GoPros...':
      'WLAN-Übertragung von den GoPros startet …',
  'Start Download': 'Download starten',
  'Export & Download': 'Export und Download',
  'Share all files': 'Alle Dateien teilen',
  'Generating export files...': 'Exportdateien werden erstellt …',
  'Export failed': 'Export fehlgeschlagen',
  'Retry': 'Erneut versuchen',
  'Export Complete': 'Export abgeschlossen',
  'Project: {name}': 'Projekt: {name}',
  '{n} files generated': '{n} Dateien erstellt',
  'Auto-Download Media': 'Medien automatisch herunterladen',
  "Connect to your GoPro's WiFi network to wirelessly download the captured photos and videos directly to your phone.":
      'Mit dem WLAN der GoPro verbinden, um Fotos und Videos drahtlos direkt aufs Telefon zu laden.',
  'Start WiFi Download': 'WLAN-Download starten',
  'Exported Data': 'Exportierte Daten',
  'Share failed: {e}': 'Teilen fehlgeschlagen: {e}',

  // Gallery
  'Delete {n} file(s)?': '{n} Datei(en) löschen?',
  'Export trajectory': 'Sensorpfad exportieren',
  '{n} files': '{n} Dateien',
  'Upload {n} files from "{name}" to your configured server?':
      '{n} Dateien aus „{name}“ auf den eingerichteten Server hochladen?',
  '{n} trajectory points recorded.': '{n} Pfadpunkte aufgezeichnet.',
  'Trajectory exported to trajectory.{ext}':
      'Sensorpfad als trajectory.{ext} exportiert',
  'Upload to storage server': 'Auf Speicherserver hochladen',

  // Main menu
  'QR configuration': 'QR-Konfiguration',
  'RIG OFFLINE': 'RIG OFFLINE',
  '{n} CAMERAS CONNECTED': '{n} KAMERAS VERBUNDEN',
  'Manage cameras': 'Kameras verwalten',
  'Trajectory preview': 'Pfadvorschau',
  '{n} shutter events · {ago}': '{n} Auslösungen · {ago}',
  'This will permanently delete "{name}" and all its capture data.':
      '„{name}“ und alle Aufnahmedaten werden endgültig gelöscht.',
  'Just now': 'Gerade eben',
  '{n}m ago': 'vor {n} Min.',
  '{n}h ago': 'vor {n} Std.',
  '{n}d ago': 'vor {n} T.',
  'Points': 'Punkte',
  'Distance': 'Strecke',
  'Duration': 'Dauer',

  // Project flow
  'e.g. Living Room Scan': 'z. B. Wohnzimmer-Scan',
  '{n} camera connected': '{n} Kamera verbunden',
  '{n} cameras connected': '{n} Kameras verbunden',
  '{preset} selected; camera confirmation pending':
      '{preset} gewählt; Bestätigung der Kameras ausstehend',
  'Photo Mode': 'Fotomodus',
  'Photo Output': 'Fotoausgabe',
  'Target Shutter': 'Ziel-Verschlusszeit',
  'Target White Balance': 'Ziel-Weißabgleich',
  'Project': 'Projekt',
  'Photo ({format})': 'Foto ({format})',
  '{n} connected': '{n} verbunden',
  'Project not started: {e}': 'Projekt nicht gestartet: {e}',
  '{guidance}\nMount: {orientation}. Target ISO: {iso} (set on every camera). ISO, shutter, white balance and physical mounting are not BLE-verified. Linear is a digital crop and still needs calibration.':
      '{guidance}\nMontage: {orientation}. ISO-Zielwert: {iso} (auf jeder Kamera einstellen). ISO, Verschlusszeit, Weißabgleich und Montage werden nicht per BLE geprüft. Linear ist ein digitaler Ausschnitt und braucht trotzdem eine Kalibrierung.',

  // QR config
  'Paste Config': 'Konfiguration einfügen',
  'Import settings from clipboard':
      'Einstellungen aus der Zwischenablage übernehmen',
  'Settings not applied: {e}': 'Einstellungen nicht übernommen: {e}',
  'Applied to {n} cameras': 'Auf {n} Kameras übernommen',
  'Scan with any QR reader app\nor share screenshot to another device':
      'Mit einer beliebigen QR-App scannen\noder Screenshot an ein anderes Gerät senden',

  // Rig setup
  'Auto-add connected cameras': 'Verbundene Kameras automatisch hinzufügen',
  'Added {n} cameras to rig': '{n} Kameras zum Rig hinzugefügt',
  'No cameras in rig layout': 'Keine Kameras im Rig-Layout',
  'Connect cameras and tap + to add them':
      'Kameras verbinden und mit + hinzufügen',
  'Add {n} connected cameras': '{n} verbundene Kameras hinzufügen',
  'Variables: {project} {camera} {index} {date} {time}':
      'Variablen: {project} {camera} {index} {date} {time}',
  'Position (meters from phone mount)': 'Position (Meter ab Telefonhalterung)',
  'X (left/right)': 'X (links/rechts)',
  'Y (up/down)': 'Y (oben/unten)',
  'Z (forward)': 'Z (vorne)',
  'Z (fwd/back)': 'Z (vorne/hinten)',
  'Rotation (degrees relative to phone)': 'Drehung (Grad relativ zum Telefon)',
  'Yaw': 'Gieren',
  'Pitch': 'Nicken',
  'Roll': 'Rollen',
  'Label': 'Bezeichnung',
  'Offset: ({x}, {y}, {z})m': 'Versatz: ({x}, {y}, {z}) m',

  // Settings
  'English': 'English',
  'Deutsch': 'Deutsch',
  'Live Camera Monitor': 'Live-Kameramonitor',
  'Multi-view live stream of all connected cameras':
      'Live-Bild aller verbundenen Kameras',
  'Sensor & Capture': 'Sensoren und Aufnahme',
  'Manual trigger only': 'Nur manuelles Auslösen',
  'Continuous timelapse': 'Fortlaufender Zeitraffer',
  'Every {n}s': 'Alle {n} s',
  'Rig Layout & File Naming': 'Rig-Layout und Dateinamen',
  'Camera Positions ({n})': 'Kamerapositionen ({n})',
  'Capturing ({n} frames)': 'Aufnahme läuft ({n} Bilder)',
  'Available — auto-captures with photos':
      'Verfügbar – nimmt automatisch mit jedem Foto auf',
  'Network & Tethering': 'Netzwerk und Tethering',
  'Storage server': 'Speicherserver',
  'Auto-upload to storage server': 'Automatisch auf Speicherserver hochladen',
  'Upload the project after each session':
      'Projekt nach jeder Sitzung hochladen',
  'Gaussian Splat Processing': 'Gaussian-Splat-Verarbeitung',
  'KOSMOS receiver (your computer)': 'KOSMOS-Empfänger (dein Computer)',
  'Version 2.0.0 · Sam Wiemann · kreativ.institute':
      'Version 2.0.0 · Sam Wiemann · kreativ.institute',
  'Configure remote COLMAP / 3DGS server':
      'Externen COLMAP-/3DGS-Server einrichten',
  'Configure Server': 'Server einrichten',
  'About': 'Über',
  'KIO Kreativ Institut': 'KIO Kreativ Institut',
  'Accelerometer • Gyroscope • Magnetometer\nBarometer • GPS • Compass':
      'Beschleunigung • Gyroskop • Magnetometer\nBarometer • GPS • Kompass',
  '{name} set as default': '{name} als Standard festgelegt',
  'Template': 'Vorlage',
  '{project} — Project name\n{camera} — Camera label\n{index} — Capture number (0001)\n{date} — Date (2026-04-30)\n{time} — Time (143025)':
      '{project} – Projektname\n{camera} – Kamerabezeichnung\n{index} – Aufnahmenummer (0001)\n{date} – Datum (2026-04-30)\n{time} – Uhrzeit (143025)',
  'Preview: {name}': 'Vorschau: {name}',
  "Define each camera's position relative to the phone mount (center of rig).\nX = left/right, Y = up/down, Z = forward/back (meters).\nRotation: yaw, pitch, roll (degrees).":
      'Position jeder Kamera relativ zur Telefonhalterung (Rig-Mitte) festlegen.\nX = links/rechts, Y = oben/unten, Z = vorne/hinten (Meter).\nDrehung: Gieren, Nicken, Rollen (Grad).',
  'MinIO / own server': 'MinIO / eigener Server',
  'Connected. Bucket is reachable and the key is valid.':
      'Verbunden. Bucket erreichbar, Schlüssel gültig.',
  'Storage server saved': 'Speicherserver gespeichert',
  'Storage server (S3-compatible)': 'Speicherserver (S3-kompatibel)',
  'Works with any S3-compatible storage. Use a key limited to one bucket with read, list and write access.':
      'Funktioniert mit jedem S3-kompatiblen Speicher. Einen Schlüssel verwenden, der auf einen Bucket mit Lese-, Listen- und Schreibrechten beschränkt ist.',
  'Quick fill': 'Schnellauswahl',
  'Endpoint URL': 'Endpunkt-URL',
  'Region (optional)': 'Region (optional)',
  'Bucket': 'Bucket',
  'Access key ID': 'Zugriffsschlüssel-ID',
  'Secret key (saved, leave empty to keep)':
      'Geheimer Schlüssel (gespeichert, leer lassen zum Beibehalten)',
  'Secret key': 'Geheimer Schlüssel',
  'Folder in bucket': 'Ordner im Bucket',
  'Projects upload to bucket/folder/<project>_<id>/ with the same structure as on the phone. Files already on the server are skipped.':
      'Projekte landen in bucket/ordner/<projekt>_<id>/ mit derselben Struktur wie auf dem Telefon. Bereits vorhandene Dateien werden übersprungen.',
  '✓ Connected successfully!': '✓ Verbindung erfolgreich!',
  '✗ Connection failed: {e}': '✗ Verbindung fehlgeschlagen: {e}',
  'API Key (Optional)': 'API-Schlüssel (optional)',

  // Transfer hub
  'Copying originals…': 'Originale werden kopiert …',
  'Saved {a}/{b} files': '{a}/{b} Dateien gespeichert',
  '{n} files saved in Files > On My iPhone > KOSMOS 3D > Exports':
      '{n} Dateien gespeichert unter Dateien > Auf meinem iPhone > KOSMOS 3D > Exports',
  '{n} originals saved in Downloads/KOSMOS3D':
      '{n} Originale in Downloads/KOSMOS3D gespeichert',
  '{n} saved; export stopped: {e}': '{n} gespeichert; Export abgebrochen: {e}',
  'Refresh files': 'Dateien aktualisieren',
  'Export originals and metadata to Files > KOSMOS 3D > Exports. Copy to iCloud or another location to keep them after uninstalling.':
      'Originale und Metadaten nach Dateien > KOSMOS 3D > Exports exportieren. In iCloud oder an einen anderen Ort kopieren, damit sie eine Deinstallation überstehen.',
  'Imports': 'Importe',

  // Audio guide
  'Slow down. Moving too fast.': 'Langsamer. Zu schnell unterwegs.',
  'Turn {dir} to fill coverage gap.':
      'Nach {dir} drehen, um die Lücke zu füllen.',
  'Rotate more before next capture.':
      'Vor der nächsten Aufnahme weiter drehen.',
  'Large gap detected. Move slower.': 'Große Lücke erkannt. Langsamer bewegen.',
  'Good coverage at {n} percent.': 'Gute Abdeckung: {n} Prozent.',
  'Excellent quality. Score {n} out of 100.':
      'Sehr gute Qualität. Wertung {n} von 100.',
  '{name} battery low at {n} percent.': '{name}: Akku bei {n} Prozent.',
  '{name} storage almost full.': '{name}: Speicher fast voll.',

  // Capture coordinator
  'Capture operation already in progress': 'Eine Aufnahme läuft bereits',
  'Connect at least one camera': 'Mindestens eine Kamera verbinden',
  'Capture mode {mode}': 'Aufnahmemodus {mode}',
  'Invalid capture interval: {v}': 'Ungültiges Aufnahmeintervall: {v}',
  'Camera {a}/{b}': 'Kamera {a}/{b}',
  'Synchronize cameras before capture': 'Kameras vor der Aufnahme abgleichen',
  'Stop unconfirmed: {e}': 'Stopp nicht bestätigt: {e}',
  'Stopped - synchronize again': 'Gestoppt – erneut abgleichen',

  // Storage service
  'Enter endpoint, bucket, access key ID and secret key.':
      'Endpunkt, Bucket, Zugriffsschlüssel-ID und geheimen Schlüssel eingeben.',
  'Cannot reach {host}: {e}': '{host} nicht erreichbar: {e}',
  'Bucket not found. Check the bucket name.':
      'Bucket nicht gefunden. Bucket-Namen prüfen.',
  'Access key ID is unknown on this server.':
      'Zugriffsschlüssel-ID ist auf diesem Server unbekannt.',
  'Secret key or region is wrong.': 'Geheimer Schlüssel oder Region falsch.',
  'Key has no permission for this bucket.':
      'Der Schlüssel hat keine Rechte für diesen Bucket.',
  'Region does not match the endpoint.': 'Region passt nicht zum Endpunkt.',
  'Server answered {e}': 'Server antwortete {e}',
  'No files to upload.': 'Keine Dateien zum Hochladen.',
  'No files to upload': 'Keine Dateien zum Hochladen',
  'Empty project': 'Leeres Projekt',
  'Configure a storage server in Settings first.':
      'Zuerst in den Einstellungen einen Speicherserver einrichten.',
  'Connecting to {host}…': 'Verbinde mit {host} …',
  'Upload cancelled': 'Upload abgebrochen',
  'Retry {n}/2: {file}': 'Wiederholung {n}/2: {file}',
  '{a} uploaded, {b} already on server → {path}':
      '{a} hochgeladen, {b} bereits auf dem Server → {path}',
  'Upload stopped after {n} files: {e}':
      'Upload nach {n} Dateien abgebrochen: {e}',
  '{file} is larger than 5 GB; split it first.':
      '{file} ist größer als 5 GB; zuerst teilen.',
  'Upload to storage server?': 'Auf Speicherserver hochladen?',
  'Upload every file of "{name}" (originals, receipts, sensor logs, LiDAR) to your storage server? Files already uploaded are skipped.':
      'Alle Dateien von „{name}“ (Originale, Prüfprotokolle, Sensordaten, LiDAR) auf den Speicherserver laden? Bereits hochgeladene Dateien werden übersprungen.',
  'Upload': 'Hochladen',
  'Uploading…': 'Wird hochgeladen …',
  'Upload complete': 'Upload abgeschlossen',
  'Upload needs attention': 'Upload braucht Aufmerksamkeit',

  // GoPro service
  'Standard': 'Standard',
  'Super Photo': 'SuperFoto',
  'Unknown model': 'Unbekanntes Modell',
  'Finish importing before capture': 'Import vor der Aufnahme abschließen',
  'Camera {id} is disconnected; reconnect it':
      'Kamera {id} ist getrennt; neu verbinden',
  'Camera {id} did not report busy/encoding status':
      'Kamera {id} meldet keinen Beschäftigt-/Kodierstatus',
  'Camera {id} is still processing after 30 seconds':
      'Kamera {id} verarbeitet nach 30 Sekunden noch',
  'Stop preview before capturing.': 'Vorschau vor der Aufnahme beenden.',
  'Camera {id} changed mode; synchronize again':
      'Kamera {id} hat den Modus gewechselt; erneut abgleichen',
  'Camera {id} changed setting {s}; synchronize again':
      'Kamera {id} hat Einstellung {s} geändert; erneut abgleichen',
  'Stopping and selecting {mode} preset':
      'Stoppe und wähle Voreinstellung {mode}',
  'Applying and reading back settings':
      'Einstellungen werden gesetzt und zurückgelesen',
  'Verified': 'Geprüft',
  '{key} cannot be verified with the published Open GoPro API. Set it on every camera (or via GoPro Labs QR) and select Camera preset.':
      '{key} lässt sich über die veröffentlichte Open-GoPro-Schnittstelle nicht prüfen. Auf jeder Kamera (oder per GoPro-Labs-QR) einstellen und „Kameravorgabe“ wählen.',
  'Device does not expose Open GoPro BLE':
      'Gerät bietet keine Open-GoPro-BLE-Schnittstelle',
  'Camera {id} disconnected': 'Kamera {id} getrennt',
  'Camera {id} denied external control':
      'Kamera {id} verweigert die externe Steuerung',
  'Preset group did not settle on {id}':
      'Voreinstellungsgruppe auf {id} nicht übernommen',
  'Camera {id} has no available preset for mode {mode}; enable Pro controls on camera':
      'Kamera {id} hat keine Voreinstellung für Modus {mode}; auf der Kamera Pro-Steuerung aktivieren',
  'Camera {id} did not enter the requested preset':
      'Kamera {id} hat die gewünschte Voreinstellung nicht übernommen',
  'Unsupported single photo format: {f}': 'Nicht unterstütztes Fotoformat: {f}',
  'Capture is busy': 'Aufnahme läuft',
  'Frame rate': 'Bildrate',
  'Video lens': 'Videoobjektiv',
  'Photo lens': 'Fotoobjektiv',
  'Photo interval': 'Fotointervall',
  'Interval duration': 'Intervalldauer',
  'Photo timer': 'Selbstauslöser',
  'Night photo': 'Nachtfoto',
  'Video duration': 'Videodauer',
  'Scheduled capture': 'Geplante Aufnahme',
  'Applying {label}; awaiting confirmation':
      '{label} wird gesetzt; warte auf Bestätigung',
  'Camera {id} does not support setting {s} in this preset':
      'Kamera {id} unterstützt Einstellung {s} in dieser Voreinstellung nicht',
  'Camera {id} did not confirm setting {s}':
      'Kamera {id} hat Einstellung {s} nicht bestätigt',
  'Stop capture first': 'Zuerst die Aufnahme beenden',
  "Reconnect this GoPro to read its Wi-Fi credentials":
      'GoPro neu verbinden, um die WLAN-Zugangsdaten zu lesen',
  'Invalid camera Wi-Fi credentials': 'Ungültige WLAN-Zugangsdaten der Kamera',
  'Camera Wi-Fi did not become ready': 'Kamera-WLAN wurde nicht bereit',
  'Wi-Fi joined, but the selected camera identity could not be verified':
      'WLAN verbunden, aber die Kamera konnte nicht eindeutig zugeordnet werden',
  'Stop capture and other transfers first':
      'Zuerst Aufnahme und andere Übertragungen beenden',
  'Connect GoPros over Bluetooth first':
      'Zuerst GoPros per Bluetooth verbinden',
  'Import cancelled': 'Import abgebrochen',
  '{a}/{b}: joining {name}. Approve the phone Wi-Fi prompt.':
      '{a}/{b}: verbinde mit {name}. WLAN-Abfrage des Telefons bestätigen.',
  '{n} files need retry': '{n} Dateien müssen erneut geladen werden',
  'Scanning network for connected GoPros...':
      'Netzwerk wird nach GoPros durchsucht …',
  'Stop capture and transfers before opening preview.':
      'Vor der Vorschau Aufnahme und Übertragungen beenden.',
  'Close the current preview before choosing another camera.':
      'Aktuelle Vorschau schließen, bevor eine andere Kamera gewählt wird.',
  'Camera disconnected': 'Kamera getrennt',
  'Join this camera’s Wi-Fi, then discover its address.':
      'Mit dem WLAN dieser Kamera verbinden und dann ihre Adresse suchen.',
  'Preview returned HTTP {n}': 'Vorschau antwortete mit HTTP {n}',
  'Wait for the preview connection to finish.':
      'Warten, bis die Vorschauverbindung steht.',
  'Preview Stop was not confirmed. Reconnect camera Wi-Fi and retry.':
      'Vorschau-Stopp nicht bestätigt. Kamera-WLAN neu verbinden und wiederholen.',
  'Invalid camera media path': 'Ungültiger Medienpfad der Kamera',
  'Incomplete media download': 'Mediendownload unvollständig',
  'Downloaded {a} of {b} files': '{a} von {b} Dateien heruntergeladen',
  'Camera identity changed on Wi-Fi. Join {name} again.':
      'Kamera im WLAN hat gewechselt. Erneut mit {name} verbinden.',
  'Could not read the SD card on {name}':
      'SD-Karte von {name} konnte nicht gelesen werden',
  'Stop capture before importing files.':
      'Vor dem Import die Aufnahme beenden.',
  'Downloading {file} from {name}...': 'Lade {file} von {name} …',
  'Invalid media filename': 'Ungültiger Mediendateiname',
  'Already downloaded: {file}': 'Bereits geladen: {file}',
  'Camera {id} cannot use {lens} in the selected mode':
      'Kamera {id} kann {lens} im gewählten Modus nicht nutzen',
  'Stop the active rig first': 'Zuerst das aktive Rig stoppen',
  'Select Single Photo or Video before applying settings':
      'Vor dem Übernehmen Einzelfoto oder Video wählen',
  'Camera {id} did not confirm video recording':
      'Kamera {id} hat die Videoaufnahme nicht bestätigt',
  'Use the capture screen to control the active rig':
      'Das aktive Rig über den Aufnahmebildschirm steuern',
  'Unavailable': 'Nicht verfügbar',
  'No LiDAR hardware': 'Kein LiDAR-Sensor',
  'Unsupported grouped media: {f}. Import this group with an SD-card reader.':
      'Nicht unterstützte Mediengruppe: {f}. Diese Gruppe per SD-Kartenleser importieren.',
  'Incomplete media group inventory: {f}': 'Unvollständige Mediengruppe: {f}',
  'A project is already being created': 'Ein Projekt wird bereits angelegt',
  'Project name is required': 'Projektname erforderlich',
  'No calibrated frames': 'Keine kalibrierten Bilder',
  'The phone did not confirm the export.':
      'Das Telefon hat den Export nicht bestätigt.',
  'Calibrated camera poses and matched media are required. Export trajectory JSON as sensor priors.':
      'Kalibrierte Kameraposen und zugeordnete Medien erforderlich. Pfad-JSON als Sensor-Vorwissen exportieren.',

  // Transfer server
  'Enter a valid HTTP(S) server address without query parameters.':
      'Gültige HTTP(S)-Serveradresse ohne Parameter eingeben.',
  'Server returned HTTP {n}': 'Server antwortete mit HTTP {n}',
  'This address is not a KOSMOS transfer server.':
      'Diese Adresse ist kein KOSMOS-Übertragungsserver.',
  'Project folder not found': 'Projektordner nicht gefunden',
  'Preparing files…': 'Dateien werden vorbereitet …',
  'Checking {file}': 'Prüfe {file}',
  'Server authentication failed (HTTP {n})':
      'Anmeldung am Server fehlgeschlagen (HTTP {n})',
  'Sending {a}/{b} · {file}': 'Sende {a}/{b} · {file}',
  'HTTP {n} while sending {file}': 'HTTP {n} beim Senden von {file}',
  'Server checksum receipt did not match the local file':
      'Prüfsumme des Servers passt nicht zur lokalen Datei',
  'Connection interrupted. Retrying {file}…':
      'Verbindung unterbrochen. {file} wird erneut gesendet …',
  'File was not acknowledged': 'Datei wurde nicht bestätigt',
  'Transferred {n} files': '{n} Dateien übertragen',
  'Transfer cancelled. Retry to continue.':
      'Übertragung abgebrochen. Zum Fortsetzen erneut starten.',
  'Cancelled': 'Abgebrochen',
  'Transfer needs attention': 'Übertragung braucht Aufmerksamkeit',

  // Live monitor
  'Choose a camera to frame your shot.':
      'Kamera wählen, um den Bildausschnitt zu prüfen.',
  'Preview stopped.': 'Vorschau beendet.',
  'Stop was not confirmed. Reconnect Wi-Fi and retry Stop.':
      'Stopp nicht bestätigt. WLAN neu verbinden und Stopp wiederholen.',
  'Live video decoding is currently available on Android.':
      'Live-Video wird derzeit nur unter Android dekodiert.',
  'Opening video receiver…': 'Videoempfang wird geöffnet …',
  'Connecting to camera…': 'Verbinde mit Kamera …',
  'Waiting for video frames… Check camera Wi-Fi.':
      'Warte auf Videobilder … Kamera-WLAN prüfen.',
  'Preview unavailable: {e}': 'Vorschau nicht verfügbar: {e}',
  'Waiting for video frames…': 'Warte auf Videobilder …',
  'Close preview': 'Vorschau schließen',
  '● LIVE': '● LIVE',
  'Connect a GoPro in Cameras to use the viewfinder.':
      'Unter „Kameras“ eine GoPro verbinden, um den Sucher zu nutzen.',

  // Media transfer
  'SSID: {ssid}\nPassword: {password}': 'SSID: {ssid}\nPasswort: {password}',
  'Stop capture before importing.': 'Vor dem Import die Aufnahme beenden.',
  '{n} files available. Select the originals to import.':
      '{n} Dateien verfügbar. Originale zum Import auswählen.',
  'Import stopped: {e}': 'Import abgebrochen: {e}',
  'Close import': 'Import schließen',
  'Cancel import': 'Import abbrechen',
  'Import complete.': 'Import abgeschlossen.',
  'Import complete': 'Import abgeschlossen',
  'Import needs attention': 'Import braucht Aufmerksamkeit',
  '{n} local files.': '{n} lokale Dateien.',
  'Gallery exports needing attention: {n}.':
      'Galerie-Exporte mit Problemen: {n}.',
  'Stored in: {path}': 'Gespeichert in: {path}',
  'Camera SD cards are unchanged. App files are removed if the app is uninstalled; export or upload a copy.':
      'SD-Karten der Kameras bleiben unverändert. App-Dateien werden bei der Deinstallation gelöscht; eine Kopie exportieren oder hochladen.',

  'Import complete: {n} local files.':
      'Import abgeschlossen: {n} lokale Dateien.',
  'Import needs attention: {n} local files.':
      'Import braucht Aufmerksamkeit: {n} lokale Dateien.',
  '{a} of {b} originals available locally. {rest}':
      '{a} von {b} Originalen lokal verfügbar. {rest}',
  'Format the SD card on the camera; no verified format command is implemented':
      'SD-Karte an der Kamera formatieren; ein geprüfter Formatierbefehl ist nicht umgesetzt',
  'Automatic hotspot provisioning requires the model-specific COHN/network protobuf flow. Join the camera Wi-Fi for media transfer. No credentials were sent.':
      'Automatische Hotspot-Einrichtung braucht den modellspezifischen COHN-Ablauf. Für die Übertragung das Kamera-WLAN nutzen. Es wurden keine Zugangsdaten gesendet.',
  'Reconnecting': 'Verbindung wird neu aufgebaut',
  'Reconnect camera: {e}': 'Kamera neu verbinden: {e}',
  'Service disposed': 'Dienst beendet',
  'Backblaze B2 (EU Central)': 'Backblaze B2 (EU Mitte)',
  'Amazon S3 (Frankfurt)': 'Amazon S3 (Frankfurt)',
  'Version {v} · {license}': 'Version {v} · {license}',

  // Coverage view
  '360° HEADINGS COVERED': '360° RICHTUNGEN ERFASST',
  'Measured LiDAR · {n} displayed points · {tracking}\nColour = height. Unseen surfaces and photo overlap are not measured.':
      'Gemessenes LiDAR · {n} angezeigte Punkte · {tracking}\nFarbe = Höhe. Nicht gesehene Flächen und Fotoüberlappung werden nicht gemessen.',
  '3D SLAM': '3D-Ansicht',
  '2D Radar': '2D-Radar',
  'Density': 'Dichte',
  'Height': 'Höhe',
  'Top View': 'Draufsicht',
  'Front View': 'Vorderansicht',
  'Reset 3D View': '3D-Ansicht zurücksetzen',
  'SLOW DOWN (< 1.0 m/s)': 'LANGSAMER (< 1,0 m/s)',
  'Heading: {h}°  Pitch: {p}°': 'Richtung: {h}°  Neigung: {p}°',
  '{n} Poses • {c}% Cov': '{n} Posen • {c} % Abdeckung',
};
