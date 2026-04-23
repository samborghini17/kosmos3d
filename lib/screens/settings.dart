import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glass_card.dart';
import 'device_manager.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.translate('settings')),
      ),
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
                title: Text(
                  settings.translate('language'),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
                subtitle: Text(
                  settings.currentLanguage == 'en' ? 'English' : 'Deutsch',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
                trailing: Switch(
                  value: settings.currentLanguage == 'de',
                  activeThumbColor: Theme.of(context).primaryColor,
                  onChanged: (bool value) {
                    context.read<SettingsProvider>().toggleLanguage();
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── DEVICE MANAGER ─────────────────────────
            _buildSectionHeader(context, settings.translate('device_manager')),
            _buildSettingCard(
              context,
              title: settings.translate('device_manager'),
              subtitle: settings.translate('manage_gopros'),
              icon: Icons.camera_alt,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeviceManagerScreen()),
                );
              },
            ),

            const SizedBox(height: 24),

            // ─── SERVER CONNECTION ──────────────────────
            _buildSectionHeader(context, settings.translate('server_connection')),
            _buildSettingCard(
              context,
              title: settings.translate('server_login'),
              subtitle: settings.translate('server_login_desc'),
              icon: Icons.cloud_sync,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const ServerConfigDialog(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
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

// ─── SERVER CONFIGURATION DIALOG ────────────────────────────

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('server_url') ?? '';
      _usernameController.text = prefs.getString('server_username') ?? '';
      _passwordController.text = prefs.getString('server_password') ?? '';
      _apiKeyController.text = prefs.getString('server_api_key') ?? '';
    });
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _urlController.text.trim());
    await prefs.setString('server_username', _usernameController.text.trim());
    await prefs.setString('server_password', _passwordController.text);
    await prefs.setString('server_api_key', _apiKeyController.text.trim());
    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Server configuration saved.'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
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
            Text(
              settings.translate('server_config_desc'),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildField(settings.translate('server_url'), _urlController, Icons.link, hint: 'https://your-server.com/api'),
            const SizedBox(height: 12),
            _buildField(settings.translate('username'), _usernameController, Icons.person),
            const SizedBox(height: 12),
            _buildField(settings.translate('password'), _passwordController, Icons.lock,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 12),
            _buildField(settings.translate('api_key'), _apiKeyController, Icons.key, hint: 'Optional'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(settings.translate('close'), style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveConfig,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(settings.translate('save')),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool obscure = false, String? hint, Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
