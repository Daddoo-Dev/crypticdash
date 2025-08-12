import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/github_service.dart';
import 'services/project_service.dart';
import 'services/theme_service.dart';
import 'services/project_selection_service.dart';
import 'theme/app_themes.dart';
import 'screens/auth_screen.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const DevDashApp());
}

class DevDashApp extends StatelessWidget {
  const DevDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => GitHubService(),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProjectSelectionService(),
        ),
        ChangeNotifierProxyProvider2<GitHubService, ProjectSelectionService, ProjectService>(
          create: (context) => ProjectService(
            Provider.of<GitHubService>(context, listen: false),
            Provider.of<ProjectSelectionService>(context, listen: false),
          ),
          update: (context, githubService, projectSelectionService, previous) => 
            previous ?? ProjectService(
              githubService,
              projectSelectionService,
            ),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: themeService.getAppName(),
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeService.themeMode,
            home: const AuthScreen(),
          );
        },
      ),
    );
  }
}
