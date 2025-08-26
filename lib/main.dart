import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'services/github_service.dart';
import 'services/project_service.dart';
import 'services/theme_service.dart';
import 'services/project_selection_service.dart';
import 'services/settings_service.dart';
import 'services/logging_service.dart';
import 'services/revenuecat_config_service.dart';

import 'services/app_flow_service.dart';
import 'services/onnx_ai_service.dart';

import 'theme/app_themes.dart';

void main() async {
  // Disable mouse tracking to prevent crashes
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Try to load .env file with proper path handling
    final currentDir = Directory.current.path;
    final envPath = '$currentDir/.env';
    LoggingService.debug('Current directory: $currentDir');
    LoggingService.debug('Looking for .env at: $envPath');
    
    // Check if file exists first
    final envFile = File(envPath);
    if (await envFile.exists()) {
      LoggingService.info('.env file exists at: $envPath');
      await dotenv.load(fileName: envPath);
      LoggingService.success('Successfully loaded .env file');
      LoggingService.debug('GITHUB_CLIENT_ID: ${dotenv.env['GITHUB_CLIENT_ID']}');
      LoggingService.debug('GITHUB_CLIENT_SECRET: ${dotenv.env['GITHUB_CLIENT_SECRET']}');
    } else {
      LoggingService.warning('.env file does NOT exist at: $envPath');
      // Try alternative paths
      final altPaths = [
        '.env',
        '../.env',
        '../../.env',
        '$currentDir/.env',
      ];
      
      for (final path in altPaths) {
        try {
          await dotenv.load(fileName: path);
          LoggingService.success('Successfully loaded .env from: $path');
          LoggingService.debug('GITHUB_CLIENT_ID: ${dotenv.env['GITHUB_CLIENT_ID']}');
          LoggingService.debug('GITHUB_CLIENT_SECRET: ${dotenv.env['GITHUB_CLIENT_SECRET']}');
          break;
        } catch (e) {
          LoggingService.warning('Failed to load from $path: $e');
        }
      }
    }
  } catch (e) {
    LoggingService.error('Error loading .env file: $e', e, StackTrace.current);
    // Continue without .env file
  }
  
  // Initialize RevenueCat for supported platforms
  try {
    await RevenueCatConfigService.initialize();
  } catch (e) {
    LoggingService.warning('RevenueCat initialization failed: $e');
    // Continue without RevenueCat
  }
  
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
          create: (context) => ProjectSelectionService(),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsService(),
        ),

        ChangeNotifierProxyProvider<GitHubService, ONNXAIService>(
          create: (context) => ONNXAIService(),
          update: (context, githubService, previous) {
            if (previous != null) {
              return previous;
            }
            return ONNXAIService();
          },
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
            // Disable mouse tracking to prevent crashes
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  // Disable mouse tracking
                  accessibleNavigation: false,
                ),
                child: child!,
              );
            },
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
    LoggingService.debug('AppFlowWrapper: Starting to determine initial screen...');
    try {
      final nextScreen = await AppFlowService.getInitialScreen(context);
      LoggingService.debug('AppFlowWrapper: Got next screen: ${nextScreen.runtimeType}');
      if (mounted) {
        setState(() {
          _currentScreen = nextScreen;
        });
        LoggingService.success('AppFlowWrapper: Screen updated successfully');
      } else {
        LoggingService.warning('AppFlowWrapper: Widget not mounted, skipping setState');
      }
    } catch (e, stackTrace) {
      LoggingService.error('AppFlowWrapper: Error determining initial screen: $e', e, stackTrace);
      // Fallback to auth screen on error
      if (mounted) {
        setState(() {
          _currentScreen = const Scaffold(
            body: Center(
              child: Text('Error loading app. Please restart.'),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _currentScreen;
  }
}


