import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'services/github_service.dart';
import 'services/project_service.dart';
import 'services/theme_service.dart';
import 'services/project_selection_service.dart';
import 'services/settings_service.dart';

import 'services/app_flow_service.dart';
import 'services/simple_ai_service.dart';

import 'theme/app_themes.dart';

void main() async {
  try {
    // Try to load .env file with proper path handling
    final currentDir = Directory.current.path;
    final envPath = '$currentDir/.env';
    print('Current directory: $currentDir');
    print('Looking for .env at: $envPath');
    
    // Check if file exists first
    final envFile = File(envPath);
    if (await envFile.exists()) {
      print('.env file exists at: $envPath');
      await dotenv.load(fileName: envPath);
      print('Successfully loaded .env file');
      print('GITHUB_CLIENT_ID: ${dotenv.env['GITHUB_CLIENT_ID']}');
      print('GITHUB_CLIENT_SECRET: ${dotenv.env['GITHUB_CLIENT_SECRET']}');
    } else {
      print('.env file does NOT exist at: $envPath');
      // Try alternative paths
      final altPaths = [
        '.env',
        '../.env',
        '../../.env',
        '${currentDir}/.env',
      ];
      
      for (final path in altPaths) {
        try {
          await dotenv.load(fileName: path);
          print('Successfully loaded .env from: $path');
          print('GITHUB_CLIENT_ID: ${dotenv.env['GITHUB_CLIENT_ID']}');
          print('GITHUB_CLIENT_SECRET: ${dotenv.env['GITHUB_CLIENT_SECRET']}');
          break;
        } catch (e) {
          print('Failed to load from $path: $e');
        }
      }
    }
  } catch (e) {
    print('Error loading .env file: $e');
    print('Stack trace: ${StackTrace.current}');
    // Continue without .env file
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

        ChangeNotifierProxyProvider<GitHubService, SimpleAIService>(
          create: (context) => SimpleAIService()..setModelPath('assets/ai_models/gemma-3-270m/onnx'),
          update: (context, githubService, previous) {
            if (previous != null) {
              previous.setGitHubService(githubService);
            }
            return previous ?? SimpleAIService()..setGitHubService(githubService)..setModelPath('assets/ai_models/gemma-3-270m/onnx');
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
    print('AppFlowWrapper: Starting to determine initial screen...');
    try {
      final nextScreen = await AppFlowService.getInitialScreen(context);
      print('AppFlowWrapper: Got next screen: ${nextScreen.runtimeType}');
      if (mounted) {
        setState(() {
          _currentScreen = nextScreen;
        });
        print('AppFlowWrapper: Screen updated successfully');
      } else {
        print('AppFlowWrapper: Widget not mounted, skipping setState');
      }
    } catch (e, stackTrace) {
      print('AppFlowWrapper: Error determining initial screen: $e');
      print('AppFlowWrapper: Stack trace: $stackTrace');
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


