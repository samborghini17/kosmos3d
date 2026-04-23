import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_menu.dart';
import 'providers/settings_provider.dart';
import 'services/gopro_service.dart';
import 'services/project_service.dart';
import 'services/trajectory_service.dart';
import 'services/upload_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GoProService()),
        ChangeNotifierProvider(create: (_) => ProjectService()),
        ChangeNotifierProvider(create: (_) => TrajectoryService()),
        ChangeNotifierProvider(create: (_) => UploadService()),
      ],
      child: const KosmosApp(),
    ),
  );
}

class KosmosApp extends StatelessWidget {
  const KosmosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'KOSMOS 3D',
          theme: AppTheme.darkTheme,
          home: const MainMenuScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
