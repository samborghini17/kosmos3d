import 'app_translations.dart';
import 'ui_dictionary_v2.dart';

class UiDictionary {
  static const german = <String, String>{
    'Target ISO (manual)': 'ISO-Zielwert (manuell)',
    'Target shutter (manual)': 'Ziel-Verschlusszeit (manuell)',
    'Target white balance (manual)': 'Ziel-Weißabgleich (manuell)',
    'Mounting (manual)': 'Montage (manuell)',
    'Check exposure and mounting on every camera. The app verifies only supported BLE settings.':
        'Belichtung und Montage auf jeder Kamera prüfen. Die App kontrolliert nur unterstützte BLE-Einstellungen.',
    "1s (fast)": "1 s (schnell)",
    "2s (normal)": "2 s (normal)",
    "5s (battery)": "5 s (sparsam)",
    "Add Connected Cameras": "Verbundene Kameras hinzufügen",
    "Available variables:": "Verfügbare Variablen:",
    "Barometer (Altitude)": "Barometer (Höhe)",
    "Camera networks": "Kameranetzwerke",
    "Clipboard is empty": "Zwischenablage ist leer",
    "Cloud storage configured": "Cloud-Speicher eingerichtet",
    "Copy to clipboard": "In Zwischenablage kopieren",
    "Define rig offsets for each camera":
        "Position und Ausrichtung jeder Kamera am Rig festlegen",
    "Delete Project?": "Projekt löschen?",
    "Delete Selected?": "Auswahl löschen?",
    "Direct Wi-Fi import and network help":
        "Direkter WLAN-Import und Netzwerkhilfe",
    "Direct Wi-Fi, passwords and hotspot compatibility":
        "Direktes WLAN, Passwörter und Hotspot-Kompatibilität",
    "Export CSV": "CSV exportieren",
    "Export JSON": "JSON exportieren",
    "Export Trajectory": "Sensorpfad exportieren",
    "File Naming Template": "Dateinamenvorlage",
    "Format": "Format",
    "GPS Poll Rate": "GPS-Abfrageintervall",
    "Gallery": "Galerie",
    "Gaussian Splatting - daylight video":
        "Gaussian Splatting – Tageslichtvideo",
    "Gaussian Splatting Rig Controller": "Rig-Steuerung für Gaussian Splatting",
    "GoPro Labs: Gaussian daylight video":
        "GoPro Labs: Gaussian-Tageslichtvideo",
    "HiLight tag added": "HiLight-Markierung gesetzt",
    "IMU Sample Rate": "IMU-Abtastrate",
    "Import all camera originals": "Alle Kameraoriginale importieren",
    "Import camera originals": "Kameraoriginale importieren",
    "Invalid settings format": "Ungültiges Einstellungsformat",
    "Join cameras one at a time; optionally export to Photos / Gallery":
        "Kameras nacheinander verbinden; optional nach Fotos / Galerie exportieren",
    "KOSMOS 3D Camera Settings": "KOSMOS-3D-Kameraeinstellungen",
    "LiDAR Scanner": "LiDAR-Scanner",
    "Location Services Required": "Standortdienste erforderlich",
    "Make space\nfor a new dimension.": "Raum für\neine neue Dimension.",
    "Naming Template": "Namensvorlage",
    "Network help": "Netzwerkhilfe",
    "No captures yet": "Noch keine Aufnahmen",
    "No trajectory data available. Record some captures first.":
        "Keine Pfaddaten vorhanden. Zuerst Aufnahmen aufzeichnen.",
    "One camera over Wi-Fi. Preview stops before capture; model and firmware support varies.":
        "Eine Kamera per WLAN. Die Vorschau endet vor der Aufnahme; Unterstützung hängt von Modell und Firmware ab.",
    "One rig. Every perspective.": "Ein Rig. Jede Perspektive.",
    "Open Session": "Sitzung öffnen",
    "Processing Server": "Upload-Server",
    "Reconnect cameras and retry Stop":
        "Kameras neu verbinden und Stopp erneut versuchen",
    "Remove": "Entfernen",
    "Rig Camera Layout": "Kameraanordnung am Rig",
    "SHUTTER EVENTS": "AUSLÖSEEREIGNISSE",
    "Scan for Devices": "Geräte suchen",
    "Scan from another phone to apply settings":
        "Mit einem anderen Telefon scannen, um Einstellungen zu übernehmen",
    "Scan this QR": "Diesen QR-Code scannen",
    "Server configuration saved": "Serverkonfiguration gespeichert",
    "Settings JSON copied!": "Einstellungs-JSON kopiert!",
    "Start preview": "Vorschau starten",
    "Supported Sensors": "Erkannte Sensoren",
    "Supported settings verified on camera":
        "Unterstützte Einstellungen auf der Kamera geprüft",
    "Switched to Photo mode": "In den Fotomodus gewechselt",
    "Switched to Video mode": "In den Videomodus gewechselt",
    "Synchronize again": "Erneut abgleichen",
    "Tap QR to view fullscreen": "QR-Code für Vollbild antippen",
    "Test": "Testen",
    "Transfer": "Übertragen",
    "Vibrate on capture events": "Bei Auslöseereignissen vibrieren",
    "Viewfinder": "Sucher",
    "Your capture\nstudio.": "Dein mobiles\nAufnahmestudio.",
    "● LIVE": "● LIVE",
    "☁️ Backblaze B2 Cloud Storage": "☁️ Backblaze-B2-Cloud-Speicher",
    "☁️ Upload to Backblaze B2": "☁️ In Backblaze B2 hochladen",
    "⚠️ Format SD Card?": "⚠️ SD-Karte formatieren?",
    "✅ Settings Found!": "✅ Einstellungen gefunden!",
    "📋 Before your first scan:\n": "📋 Vor der ersten Aufnahme:\n",
    "📱 Camera Settings QR": "📱 Kameraeinstellungen als QR-Code",
    "Approximate GPS / phone attitude; not reconstructed surface coverage. Drag to rotate; pinch to zoom.":
        "Ungefähre GPS-Position und Telefonausrichtung; keine rekonstruierte Oberflächenabdeckung. Zum Drehen ziehen, mit zwei Fingern zoomen.",
    "No system Bluetooth pairing needed! Just make sure your GoPros have Wireless Connections enabled, then tap Scan → tap a camera to connect.":
        "GoPros in den Kopplungsmodus versetzen, Suchen antippen und eine Kamera verbinden. Eine Kopplungsanfrage des Telefons bestätigen.",
    "Android requires Location / GPS to be ON for Bluetooth scanning.\n\nPull down your quick settings and turn on Location.":
        "Je nach Android-Version müssen die Standortdienste für die Bluetooth-Suche aktiv sein.\n\nStandort in den Schnelleinstellungen einschalten.",
    "Enter your B2 Application Key credentials.\nUse a restricted key, not the master key!":
        "B2-Anwendungsschlüssel und ein vorhandenes Bucket angeben.\nEinen auf Uploads beschränkten Schlüssel verwenden.",
    "Requires GoPro Labs firmware. Show this QR to each camera and confirm the settings on its display. No capture is started.":
        "GoPro-Labs-Firmware erforderlich. Den QR-Code jeder Kamera zeigen und die Einstellungen auf ihrem Display prüfen. Es wird keine Aufnahme gestartet.",
    "QR acceptance and Protune values are not verified over BLE. Keep the configured Video preset active on each camera.":
        "QR-Übernahme und Protune-Werte werden nicht per BLE geprüft. Die konfigurierte Video-Voreinstellung auf jeder Kamera aktiv lassen.",
    "4K / 30 fps / 5500K / ISO 100-200 / 45-degree shutter (1/240 s) / high bitrate / stabilization off. Select Linear in the app. Use good lighting.":
        "4K / 30 fps / 5500 K / ISO 100–200 / 45°-Verschluss (1/240 s) / hohe Bitrate / Stabilisierung aus. Linear in der App auswählen. Gute Beleuchtung verwenden.",
    "WiFi AP enabled — connect your phone to GoPro WiFi to download media":
        "Kamera-WLAN aktiv – Telefon für den Download mit dem GoPro-WLAN verbinden",
    "GPS enabled — positions are logged; original photo EXIF is unchanged":
        "GPS aktiv – Positionen werden protokolliert; EXIF-Daten der Originalfotos bleiben unverändert",
    "Ready - BLE settings verified; check manual exposure and mounting":
        "Bereit – BLE-Einstellungen geprüft; Belichtung und Montage manuell kontrollieren",
    "Configure file uploads here. Reconstruction requires a separate processing service.":
        "Hier Datei-Uploads konfigurieren. Für die Rekonstruktion ist ein separater Verarbeitungsdienst erforderlich.",
    'Projects': 'Projekte',
    'Cameras': 'Kameras',
    'Transfers': 'Übertragungen',
    'Settings': 'Einstellungen',
    'Appearance': 'Darstellung',
    'Theme': 'Design',
    'System': 'System',
    'Light': 'Hell',
    'Dark': 'Dunkel',
    'Language': 'Sprache',
    'Outdoor Scan': 'Außenaufnahme',
    'Interior Scan': 'Innenaufnahme',
    'Detail Scan': 'Detailaufnahme',
    'Video Walk': 'Video-Rundgang',
    'Gaussian Video (Labs)': 'Gaussian-Video (Labs)',
    'Capture Interval': 'Aufnahmeintervall',
    'Manual capture only': 'Nur manuelle Aufnahme',
    'Off': 'Aus',
    'Photo': 'Foto',
    'Video': 'Video',
    'Resolution': 'Auflösung',
    'Lens': 'Objektiv',
    'Wide': 'Weitwinkel',
    'Linear': 'Linear',
    'Standard Photo': 'Standardfoto',
    'Camera preset': 'Kameravoreinstellung',
    'Photo Format': 'Fotoformat',
    'ISO Max': 'Maximale ISO',
    'Shutter': 'Verschlusszeit',
    'White Balance': 'Weißabgleich',
    'Bitrate': 'Bitrate',
    'High': 'Hoch',
    'Orientation': 'Ausrichtung',
    'Portrait': 'Hochformat',
    'Landscape': 'Querformat',
    'Interval': 'Intervall',
    'Target ISO': 'ISO-Zielwert',
    'Guidance': 'Hinweise',
    'Sensor Recording': 'Sensoraufzeichnung',
    'Record Barometer': 'Luftdruck aufzeichnen',
    'Record pressure sensor for elevation':
        'Luftdruck für die Höhenschätzung aufzeichnen',
    'Sensor Sample Rate': 'Sensor-Abtastrate',
    'GPS Update Rate': 'GPS-Aktualisierung',
    'Haptic Feedback': 'Haptisches Feedback',
    'Vibrate on capture and actions': 'Bei Aufnahmen und Aktionen vibrieren',
    'Point cloud / coverage viewer': 'Punktwolken- und Abdeckungsansicht',
    'Measured LiDAR where available; otherwise GPS and orientation.':
        'Gemessene LiDAR-Daten, falls verfügbar; sonst GPS und Ausrichtung.',
    'Coverage viewer disabled in Settings':
        'Abdeckungsansicht in den Einstellungen deaktiviert',
    'From rig to anywhere.': 'Vom Rig ans Ziel.',
    'Import originals over Wi-Fi. Keep them on your phone or send a complete project to your server.':
        'Originale per WLAN importieren. Auf dem Telefon behalten oder vollständige Projekte an den Server senden.',
    'Source / import destination': 'Quelle / Importziel',
    'Loose imports': 'Freie Importe',
    'Original camera media, stored on this phone.':
        'Originale Kameradateien auf diesem Telefon.',
    'Originals, project information and recorded sensor data.':
        'Originale, Projektinformationen und aufgezeichnete Sensordaten.',
    'Open project media': 'Projektmedien öffnen',
    'Import from GoPros': 'Von GoPros importieren',
    'Select cameras and files over Wi-Fi.':
        'Kameras und Dateien per WLAN auswählen.',
    'Browse camera files': 'Kameradateien anzeigen',
    'Save to phone': 'Auf dem Telefon speichern',
    'Export all originals and metadata to Downloads/KOSMOS3D.':
        'Alle Originale und Metadaten nach Downloads/KOSMOS3D exportieren.',
    'Save all files': 'Alle Dateien speichern',
    'Send to server': 'An Server senden',
    'Choose your own server destination.': 'Eigenes Serverziel auswählen.',
    'Configure destination': 'Ziel konfigurieren',
    'Test connection': 'Verbindung testen',
    'Server is reachable': 'Server ist erreichbar',
    'Connection failed': 'Verbindung fehlgeschlagen',
    'Send all': 'Alle senden',
    'Cancel transfer': 'Übertragung abbrechen',
    'Keep the app open during transfers. Interrupted KOSMOS server uploads can be retried; completed files are checked before sending again.':
        'Die App während der Übertragung geöffnet lassen. Unterbrochene KOSMOS-Uploads können wiederholt werden; bereits vollständige Dateien werden vorher geprüft.',
    'Server destination': 'Serverziel',
    'KOSMOS transfer server': 'KOSMOS-Übertragungsserver',
    'Existing upload API': 'Vorhandene Upload-API',
    'Server address': 'Serveradresse',
    'Access token': 'Zugriffstoken',
    'Cancel': 'Abbrechen',
    'Save': 'Speichern',
    'Uses the included KOSMOS server. Every file is verified with SHA-256. Retry skips files already verified on the server.':
        'Nutzt den KOSMOS-Server. Jede Datei wird mit SHA-256 geprüft. Bereits verifizierte Dateien werden beim erneuten Versuch übersprungen.',
    'Uses your existing POST /upload endpoint with a multipart file field. Username/password can be configured in Settings.':
        'Nutzt POST /upload mit einem Multipart-Dateifeld. Benutzername und Passwort lassen sich in den Einstellungen festlegen.',
    'Enter a valid HTTP(S) server address.':
        'Eine gültige HTTP(S)-Serveradresse eingeben.',
    'Import originals': 'Originale importieren',
    'Camera Wi-Fi': 'Kamera-WLAN',
    'The app reads the camera password over Bluetooth. Removing Wi-Fi security is unnecessary.':
        'Die App liest das Kamerapasswort per Bluetooth. Der WLAN-Schutz muss nicht entfernt werden.',
    'Copy password': 'Passwort kopieren',
    'Done': 'Fertig',
    'Cameras transfer one at a time. Approve each Wi-Fi connection when asked.':
        'Die Kameras werden nacheinander übertragen. WLAN-Verbindungen auf Nachfrage bestätigen.',
    'Wi-Fi settings': 'WLAN-Einstellungen',
    'Browse files': 'Dateien anzeigen',
    'Also copy to Photos / Gallery': 'Zusätzlich in Fotos / Galerie kopieren',
    'Originals always remain in the app.': 'Die Originale bleiben in der App.',
    'Select all': 'Alle auswählen',
    'Deselect all': 'Auswahl aufheben',
    'No readable media found. Connect a camera by Bluetooth and join its Wi-Fi.':
        'Keine lesbaren Medien gefunden. Kamera per Bluetooth verbinden und ihrem WLAN beitreten.',
    'Finding cameras and reading SD cards…':
        'Kameras suchen und SD-Karten lesen …',
    'Join a camera’s Wi-Fi, then browse its files. Bluetooth controls the rig; Wi-Fi transfers originals.':
        'Mit dem Kamera-WLAN verbinden und Dateien anzeigen. Bluetooth steuert das Rig; WLAN überträgt Originale.',
    'Please enter a project name.': 'Bitte einen Projektnamen eingeben.',
    'Syncing camera modes & settings...':
        'Kameramodi und Einstellungen werden abgeglichen …',
    'End Session?': 'Sitzung beenden?',
    'End Session': 'Sitzung beenden',
    'Continue': 'Fortsetzen',
    'Sync Images via Hotspot': 'Kameradateien importieren',
    'Heading coverage': 'Erfasste Richtungen',
    'GPS path and phone orientation (approximate)':
        'GPS-Pfad und Telefonausrichtung (ungefähr)',
    'Interval is a minimum delay after processing; timing may vary.':
        'Das Intervall ist eine Mindestpause nach der Verarbeitung; der Takt kann abweichen.',
    'Record a capture session to see the 3D preview':
        'Eine Aufnahmesitzung aufzeichnen, um die 3D-Vorschau zu sehen',
    'Reset View': 'Ansicht zurücksetzen',
    'Reset view': 'Ansicht zurücksetzen',
    'Move slowly to collect depth':
        'Langsam bewegen, um Tiefendaten zu sammeln',
    'Scan': 'Suchen',
    'Scan for cameras': 'Kameras suchen',
    'Connect': 'Verbinden',
    'Disconnect': 'Trennen',
    'Connected': 'Verbunden',
    'Disconnected': 'Getrennt',
    'Connecting...': 'Verbindung wird hergestellt …',
    'Connect all': 'Alle verbinden',
    'No cameras connected': 'Keine Kameras verbunden',
    'Camera Settings': 'Kameraeinstellungen',
    'Apply to All Cameras': 'Auf alle Kameras anwenden',
    'Apply': 'Anwenden',
    'Power Off': 'Ausschalten',
    'Power off': 'Ausschalten',
    'Refresh': 'Aktualisieren',
    'Live Preview': 'Live-Vorschau',
    'Live preview': 'Live-Vorschau',
    'Close': 'Schließen',
    'Delete': 'Löschen',
    'Rename': 'Umbenennen',
    'Project Gallery': 'Projektgalerie',
    'Upload Project': 'Projekt hochladen',
    'Upload': 'Hochladen',
    'Upload to server': 'An Server hochladen',
    'Upload to B2': 'In B2 hochladen',
    'No images yet': 'Noch keine Bilder',
    'Images downloaded from GoPros will appear here':
        'Von GoPros importierte Bilder erscheinen hier',
    'Import': 'Importieren',
    'Photo output': 'Fotoausgabe',
    'Automatic': 'Automatisch',
    'Camera Rig': 'Kamera-Rig',
    'Rig Geometry': 'Rig-Geometrie',
    'Cloud Storage': 'Cloud-Speicher',
    'Auto-Upload (B2 Cloud)': 'Automatischer Upload (B2)',
    'Upload to Backblaze B2 after each session':
        'Nach jeder Sitzung in Backblaze B2 hochladen',
    'Auto-Upload Captures': 'Aufnahmen automatisch hochladen',
    'Automatically upload session photos to server for 3D reconstruction':
        'Sitzungsfotos automatisch zum Server hochladen; eine Rekonstruktion muss dort separat eingerichtet sein',
    'Phone Hotspot & Tethering': 'Telefon-Hotspot und Tethering',
    'GoPro Labs QR Code': 'GoPro-Labs-QR-Code',
    'Save & Close': 'Speichern und schließen',
    'Server Configuration': 'Serverkonfiguration',
    'API Key': 'API-Schlüssel',
    'Password': 'Passwort',
    'Username': 'Benutzername',
    'Server URL': 'Server-URL',
    'QR Config': 'QR-Konfiguration',
    'Share settings': 'Einstellungen teilen',
    'Welcome to KOSMOS 3D': 'Willkommen bei KOSMOS 3D',
    'Mount your phone': 'Telefon montieren',
    'Power on GoPros': 'GoPros einschalten',
    'Scan & Connect': 'Suchen und verbinden',
    'Cloud Storage (Optional)': 'Cloud-Speicher (optional)',
    "Got it — Let's Go!": 'Verstanden – los geht’s!',
    'Set as Default': 'Als Standard festlegen',
    'Set as default': 'Als Standard festlegen',
    'Create Preset': 'Voreinstellung erstellen',
    'Preset Name': 'Name der Voreinstellung',
    'Not synchronized': 'Nicht abgeglichen',
    'Synchronizing cameras': 'Kameras werden abgeglichen',
    'Ready - all cameras verified':
        'Bereit – unterstützte Einstellungen aller Kameras geprüft',
    'Checking cameras': 'Kameras werden geprüft',
    'Capturing - tap Stop': 'Aufnahme läuft – zum Beenden Stopp antippen',
    'Ready': 'Bereit',
    'Stopping all cameras': 'Alle Kameras werden gestoppt',
    'Stopped': 'Gestoppt',
    'Import all files from {count} cameras':
        'Alle Dateien von {count} Kameras importieren',
    '{count} local files': '{count} lokale Dateien',
    '{count} selected': '{count} ausgewählt',
    'Import {count} files': '{count} Dateien importieren',
    '{name} Wi-Fi': '{name}: WLAN',
  };

  /// Dart prefixes for exception messages shown with `'$e'`.
  static const _errorPrefixes = <String, String>{
    'Bad state: ': 'Fehler: ',
    'Unsupported operation: ': 'Nicht unterstützt: ',
    'Exception: ': 'Fehler: ',
    'FormatException: ': 'Formatfehler: ',
    'HttpException: ': 'Netzwerkfehler: ',
    'Invalid argument(s): ': 'Ungültige Angabe: ',
  };

  static final List<(RegExp, List<String>, String)> _patterns = () {
    final entries = [
      ...german.entries,
      ...germanV2.entries,
    ].where((e) => e.key.contains('{')).toList();
    // Most literal text first: "Transferred {n} files" beats "{n} files".
    int literal(String key) => key.replaceAll(RegExp(r'\{\w+\}'), '').length;
    entries.sort((a, b) => literal(b.key).compareTo(literal(a.key)));
    return [
      for (final entry in entries)
        () {
          final names = RegExp(
            r'\{(\w+)\}',
          ).allMatches(entry.key).map((m) => m[1]!).toList();
          var pattern = RegExp.escape(entry.key);
          for (final name in names) {
            pattern = pattern.replaceFirst(RegExp.escape('{$name}'), '(.+?)');
          }
          return (RegExp('^$pattern\$', dotAll: true), names, entry.value);
        }(),
    ];
  }();

  static String translate(String language, String text) {
    if (language != 'de' || text.isEmpty) return text;
    final exact = german[text] ?? germanV2[text];
    if (exact != null) return exact;
    final legacy = AppTranslations.translateEnglishText(text);
    if (legacy != text) return legacy;
    for (final (regex, names, value) in _patterns) {
      final match = regex.firstMatch(text);
      if (match != null) {
        var result = value;
        for (var i = 0; i < names.length; i++) {
          result = result.replaceAll('{${names[i]}}', match[i + 1]!);
        }
        return result;
      }
    }
    for (final prefix in _errorPrefixes.entries) {
      if (text.startsWith(prefix.key)) {
        final rest = text.substring(prefix.key.length);
        final translated = translate(language, rest);
        if (translated != rest) return '${prefix.value}$translated';
      }
    }
    // Multi-line status text: translate line by line.
    if (text.contains('\n')) {
      final joined = text
          .split('\n')
          .map((line) => translate(language, line))
          .join('\n');
      if (joined != text) return joined;
    }
    return text;
  }
}
