import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glass_card.dart';
import 'device_manager.dart';
import '../providers/settings_provider.dart';
import '../services/cloud_storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cloud = context.watch<CloudStorageService>();

    return Scaffold(
      appBar: AppBar(title: Text(settings.translate('settings'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ─── APP SETTINGS ───────────────────────────
            _buildSectionHeader(context, settings.translate('settings')),
            GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Text(
                  settings.currentLanguage == 'en' ? '🇬🇧' : '🇩🇪',
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(settings.translate('language'),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                subtitle: Text(settings.currentLanguage == 'en' ? 'English' : 'Deutsch',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                trailing: Switch(
                  value: settings.currentLanguage == 'de',
                  activeThumbColor: Theme.of(context).primaryColor,
                  onChanged: (_) => context.read<SettingsProvider>().toggleLanguage(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── DEVICE MANAGER ─────────────────────────
            _buildSectionHeader(context, settings.translate('device_manager')),
            _buildSettingCard(context,
              title: settings.translate('device_manager'),
              subtitle: settings.translate('manage_gopros'),
              icon: Icons.camera_alt,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DeviceManagerScreen())),
            ),
            const SizedBox(height: 24),

            // ─── SCANNING PRESETS ───────────────────────
            _buildSectionHeader(context, settings.translate('scanning_presets')),
            ...settings.allPresets.map((preset) => GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Text(preset.icon, style: const TextStyle(fontSize: 24)),
                title: Text(preset.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
                subtitle: Text(
                  '${preset.settings['Resolution']} · ${preset.settings['FPS']}fps · ${preset.settings['Lens']}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                onTap: () => _showPresetDetail(context, preset, settings),
              ),
            )),
            _buildSettingCard(context,
              title: settings.translate('create_preset'),
              subtitle: settings.translate('create_preset_desc'),
              icon: Icons.add_circle_outline,
              onTap: () => _showCreatePresetDialog(context, settings),
            ),
            const SizedBox(height: 24),

            // ─── CLOUD STORAGE ──────────────────────────
            _buildSectionHeader(context, settings.translate('cloud_storage')),
            _buildSettingCard(context,
              title: 'Backblaze B2',
              subtitle: cloud.isConfigured
                  ? settings.translate('cloud_configured')
                  : settings.translate('cloud_not_configured'),
              icon: Icons.cloud,
              onTap: () => showDialog(context: context, builder: (_) => const CloudStorageDialog()),
            ),
            const SizedBox(height: 24),

            // ─── SERVER CONNECTION ──────────────────────
            _buildSectionHeader(context, settings.translate('server_connection')),
            _buildSettingCard(context,
              title: settings.translate('server_login'),
              subtitle: settings.translate('server_login_desc'),
              icon: Icons.cloud_sync,
              onTap: () => showDialog(context: context, builder: (_) => const ServerConfigDialog()),
            ),
          ],
        ),
      ),
    );
  }

  void _showPresetDetail(BuildContext context, CameraPreset preset, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            Text(preset.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(preset.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: preset.settings.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                Text(e.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setDefaultSettings(preset.settings);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${preset.name} set as default'), backgroundColor: Theme.of(context).primaryColor),
              );
            },
            child: const Text('Set as Default'),
          ),
        ],
      ),
    );
  }

  void _showCreatePresetDialog(BuildContext context, SettingsProvider settings) {
    final nameCtrl = TextEditingController();
    String resolution = '4K', fps = '30', lens = 'Linear';
    String isoMax = '400', shutter = 'Auto', wb = '5500K', bitrate = 'High';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Create Preset', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Preset Name', labelStyle: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 12),
                _dropdownRow('Resolution', resolution, ['1080p', '2.7K', '4K', '5.3K'], (v) => setState(() => resolution = v)),
                _dropdownRow('FPS', fps, ['24', '30', '60', '120'], (v) => setState(() => fps = v)),
                _dropdownRow('Lens', lens, ['Linear', 'Wide', 'SuperView'], (v) => setState(() => lens = v)),
                _dropdownRow('ISO Max', isoMax, ['100', '200', '400', '800', '1600'], (v) => setState(() => isoMax = v)),
                _dropdownRow('Shutter', shutter, ['Auto', '1/60', '1/120', '1/240', '1/480'], (v) => setState(() => shutter = v)),
                _dropdownRow('White Balance', wb, ['Auto', '3200K', '4000K', '5500K', '6500K'], (v) => setState(() => wb = v)),
                _dropdownRow('Bitrate', bitrate, ['Standard', 'High'], (v) => setState(() => bitrate = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                settings.addCustomPreset(CameraPreset(
                  name: nameCtrl.text.trim(), icon: '⭐',
                  settings: {
                    'Resolution': resolution, 'FPS': fps, 'Lens': lens,
                    'ISO Max': isoMax, 'Shutter': shutter, 'White Balance': wb, 'Bitrate': bitrate,
                  },
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownRow(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value, dropdownColor: const Color(0xFF2E2E2E), isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (v) { if (v != null) onChanged(v); },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold,
      )),
    );
  }

  Widget _buildSettingCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: Colors.white, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}

// ─── CLOUD STORAGE DIALOG ───────────────────────────────────

class CloudStorageDialog extends StatefulWidget {
  const CloudStorageDialog({super.key});

  @override
  State<CloudStorageDialog> createState() => _CloudStorageDialogState();
}

class _CloudStorageDialogState extends State<CloudStorageDialog> {
  final _keyIdCtrl = TextEditingController();
  final _appKeyCtrl = TextEditingController();
  final _bucketCtrl = TextEditingController();
  final _endpointCtrl = TextEditingController(text: 's3.us-west-004.backblazeb2.com');
  final _regionCtrl = TextEditingController(text: 'us-west-004');
  bool _obscureKey = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadCreds();
  }

  Future<void> _loadCreds() async {
    final cloud = context.read<CloudStorageService>();
    final creds = await cloud.getDisplayCredentials();
    setState(() {
      _keyIdCtrl.text = creds['keyId'] ?? '';
      _bucketCtrl.text = creds['bucketName'] ?? '';
      _endpointCtrl.text = creds['endpoint'] ?? 's3.us-west-004.backblazeb2.com';
      _regionCtrl.text = creds['region'] ?? 'us-west-004';
    });
  }

  Future<void> _testConnection() async {
    setState(() { _isTesting = true; _testResult = null; });
    final cloud = context.read<CloudStorageService>();
    await cloud.saveCredentials(
      keyId: _keyIdCtrl.text.trim(),
      applicationKey: _appKeyCtrl.text.trim(),
      bucketName: _bucketCtrl.text.trim(),
      endpoint: _endpointCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
    );
    final ok = await cloud.testConnection();
    setState(() {
      _isTesting = false;
      _testResult = ok ? '✅ Connection successful!' : '❌ ${cloud.lastError ?? "Failed"}';
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final cloud = context.read<CloudStorageService>();
    await cloud.saveCredentials(
      keyId: _keyIdCtrl.text.trim(),
      applicationKey: _appKeyCtrl.text.trim(),
      bucketName: _bucketCtrl.text.trim(),
      endpoint: _endpointCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
    );
    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Cloud storage configured'), backgroundColor: Theme.of(context).primaryColor),
      );
    }
  }

  @override
  void dispose() {
    _keyIdCtrl.dispose(); _appKeyCtrl.dispose(); _bucketCtrl.dispose();
    _endpointCtrl.dispose(); _regionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('☁️ Backblaze B2 Cloud Storage', style: TextStyle(color: Colors.white, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your B2 Application Key credentials.\nUse a restricted key, not the master key!',
                style: TextStyle(color: Colors.orange, fontSize: 12)),
            const SizedBox(height: 16),
            _field('Key ID', _keyIdCtrl, Icons.key),
            const SizedBox(height: 10),
            _field('Application Key', _appKeyCtrl, Icons.lock, obscure: _obscureKey,
              suffix: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            const SizedBox(height: 10),
            _field('Bucket Name', _bucketCtrl, Icons.folder),
            const SizedBox(height: 10),
            _field('S3 Endpoint', _endpointCtrl, Icons.language),
            const SizedBox(height: 10),
            _field('Region', _regionCtrl, Icons.map),
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Text(_testResult!, style: TextStyle(
                color: _testResult!.startsWith('✅') ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
              )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: _isTesting ? null : _testConnection,
          child: _isTesting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Test'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: ctrl, obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor), borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}

// ─── SERVER CONFIG DIALOG (LEGACY) ──────────────────────────

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _apiCtrl = TextEditingController();
  bool _obscure = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlCtrl.text = prefs.getString('server_url') ?? '';
      _userCtrl.text = prefs.getString('server_username') ?? '';
      _passCtrl.text = prefs.getString('server_password') ?? '';
      _apiCtrl.text = prefs.getString('server_api_key') ?? '';
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _urlCtrl.text.trim());
    await prefs.setString('server_username', _userCtrl.text.trim());
    await prefs.setString('server_password', _passCtrl.text);
    await prefs.setString('server_api_key', _apiCtrl.text.trim());
    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Server configuration saved.'), backgroundColor: Theme.of(context).primaryColor),
      );
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose(); _userCtrl.dispose(); _passCtrl.dispose(); _apiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text(settings.translate('server_login'), style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(settings.translate('server_config_desc'), style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            _buildField(settings.translate('server_url'), _urlCtrl, Icons.link, hint: 'https://your-server.com/api'),
            const SizedBox(height: 12),
            _buildField(settings.translate('username'), _userCtrl, Icons.person),
            const SizedBox(height: 12),
            _buildField(settings.translate('password'), _passCtrl, Icons.lock,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 12),
            _buildField(settings.translate('api_key'), _apiCtrl, Icons.key, hint: 'Optional'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text(settings.translate('close'), style: const TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(settings.translate('save')),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon,
      {bool obscure = false, String? hint, Widget? suffix}) {
    return TextField(
      controller: controller, obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor), borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
