import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader(context, 'Gerätemanager'),
            _buildSettingCard(
              context,
              title: 'Aufnahmegeräte verbinden',
              subtitle: 'Via Bluetooth/WiFi (GoPro & offene Abstraktionsebene)',
              icon: Icons.camera_alt,
              onTap: () {
                // Open Device Manager
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Server Verbindung'),
            _buildSettingCard(
              context,
              title: 'Server Login',
              subtitle: 'Eigene Serverdaten / Cloud Endpoint eintragen',
              icon: Icons.cloud_sync,
              onTap: () {
                // Open Server Config Dialog
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
    return Card(
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
