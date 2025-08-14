import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/github_service.dart';
import 'services/project_service.dart';
import 'services/theme_service.dart';
import 'services/project_selection_service.dart';
import 'services/settings_service.dart';
import 'services/app_flow_service.dart';
import 'theme/app_themes.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const CrypticDashApp());
}

class CrypticDashApp extends StatelessWidget {
  const CrypticDashApp({super.key});

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
        ChangeNotifierProvider(
          create: (context) => SettingsService(),
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
            home: const AppFlowWrapper(),
          );
        },
      ),
    );
  }
}

class AppFlowWrapper extends StatefulWidget {
  const AppFlowWrapper({super.key});

  @override
  State<AppFlowWrapper> createState() => _AppFlowWrapperState();
}

class _AppFlowWrapperState extends State<AppFlowWrapper> {
  Widget _currentScreen = const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );

  @override
  void initState() {
    super.initState();
    _determineInitialScreen();
  }

  Future<void> _determineInitialScreen() async {
    final nextScreen = await AppFlowService.getInitialScreen(context);
    if (mounted) {
      setState(() {
        _currentScreen = nextScreen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _currentScreen;
  }
}
