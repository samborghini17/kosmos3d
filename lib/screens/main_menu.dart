import 'package:flutter/material.dart';
import 'dart:ui';
import 'settings.dart';
import 'project_flow.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KOSMOS 3D'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projektübersicht',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 3, // Placeholder for actual projects
                  itemBuilder: (context, index) {
                    return _buildProjectCard(
                      context,
                      'Projekt ${index + 1}',
                      'Letzte Änderung: Gestern',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProjectFlowScreen()),
            );
        },
        icon: const Icon(Icons.add),
        label: const Text('Neues Projekt'),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Aeroglass effect
          child: Card(
            elevation: 0,
            color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.4), // Translucent card
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(
                Icons.folder_shared,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  // Handle project management actions (löschen, etc.)
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Bearbeiten'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Löschen', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ];
                },
              ),
              onTap: () {
                // Open Project Overview
              },
            ),
          ),
        ),
      ),
    );
  }
}
