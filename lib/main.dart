import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_menu.dart';

void main() {
  runApp(const KosmosApp());
}

class KosmosApp extends StatelessWidget {
  const KosmosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KOSMOS 3D',
      theme: AppTheme.darkTheme,
      home: const MainMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
