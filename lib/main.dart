import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/github_service.dart';
import 'services/project_service.dart';
import 'services/theme_service.dart';
import 'services/project_selection_service.dart';
import 'services/settings_service.dart';
import 'services/logging_service.dart';
import 'services/revenuecat_config_service.dart';
import 'services/iap_service.dart';
import 'services/repo_tracking_service.dart';
import 'services/appwrite_auth_service.dart';
import 'services/appwrite_connection_service.dart';
import 'services/user_verification_service.dart';

import 'services/app_flow_service.dart';
import 'services/onnx_ai_service.dart';

import 'theme/app_themes.dart';

void main() async {
  // Disable mouse tracking to prevent crashes
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    LoggingService.success('Successfully loaded .env file');
  } catch (e) {
    LoggingService.warning('Failed to load .env file: $e');
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
        ChangeNotifierProvider(
          create: (context) {
            LoggingService.debug('Main: Creating AppwriteConnectionService...');
            final connectionService = AppwriteConnectionService();
            LoggingService.debug('Main: AppwriteConnectionService created successfully');
            return connectionService;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            LoggingService.debug('Main: Creating AppwriteAuthService...');
            final authService = AppwriteAuthService();
            LoggingService.debug('Main: AppwriteAuthService created successfully');
            return authService;
          },
        ),
        ChangeNotifierProxyProvider2<AppwriteConnectionService, GitHubService, UserVerificationService>(
          create: (context) {
            LoggingService.debug('Main: Creating UserVerificationService...');
            final connectionService = Provider.of<AppwriteConnectionService>(context, listen: false);
            final githubService = Provider.of<GitHubService>(context, listen: false);
            final verificationService = UserVerificationService(connectionService, githubService);
            LoggingService.debug('Main: UserVerificationService created successfully');
            return verificationService;
          },
          update: (context, connectionService, githubService, previous) {
            if (previous != null) {
              LoggingService.debug('Main: Updating UserVerificationService...');
              return previous;
            }
            LoggingService.debug('Main: Creating new UserVerificationService in update...');
            return UserVerificationService(connectionService, githubService);
          },
        ),
        ChangeNotifierProxyProvider<AppwriteAuthService, IAPService>(
          create: (context) {
            LoggingService.debug('Main: Creating IAPService...');
            final iapService = IAPService();
            final authService = Provider.of<AppwriteAuthService>(context, listen: false);
            LoggingService.debug('Main: Setting auth service on IAPService...');
            iapService.setAuthService(authService);
            LoggingService.debug('Main: IAPService created and configured successfully');
            return iapService;
          },
          update: (context, authService, previous) {
            if (previous != null) {
              LoggingService.debug('Main: Updating IAPService with new auth service...');
              previous.setAuthService(authService);
              return previous;
            }
            LoggingService.debug('Main: Creating new IAPService in update...');
            final iapService = IAPService();
            iapService.setAuthService(authService);
            return iapService;
          },
        ),
        ChangeNotifierProxyProvider2<GitHubService, IAPService, RepoTrackingService>(
          create: (context) => RepoTrackingService(
            Provider.of<GitHubService>(context, listen: false),
            Provider.of<IAPService>(context, listen: false),
          ),
          update: (context, githubService, iapService, previous) => 
            previous ?? RepoTrackingService(
              githubService,
              iapService,
            ),
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

  void _retryConnection() {
    _determineInitialScreen();
  }

  Future<void> _determineInitialScreen() async {
    LoggingService.debug('AppFlowWrapper: Starting to determine initial screen...');
    try {
      // First, test Appwrite connection and verify user data
      if (!mounted) return;
      
      final verificationService = Provider.of<UserVerificationService>(context, listen: false);
      LoggingService.debug('AppFlowWrapper: Testing Appwrite connection...');
      
      // Test the Appwrite connection (ping functionality)
      final isVerified = await verificationService.verifyUserData();
      LoggingService.debug('AppFlowWrapper: User verification result: $isVerified');
      
      // Safely notify listeners after verification is complete
      final connectionService = Provider.of<AppwriteConnectionService>(context, listen: false);
      connectionService.safeNotifyListeners();
      
      if (!isVerified) {
        LoggingService.warning('AppFlowWrapper: User verification failed, showing error screen');
        if (mounted) {
          setState(() {
            _currentScreen = Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to connect to Appwrite',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your internet connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retryConnection,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          });
        }
        return;
      }
      
      // Now proceed with normal app flow
      if (!mounted) return;
      
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