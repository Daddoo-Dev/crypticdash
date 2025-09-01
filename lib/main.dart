import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'services/github_service.dart';
import 'services/project_service.dart';
import 'services/theme_service.dart';
import 'services/project_selection_service.dart';
import 'services/settings_service.dart';
import 'services/revenuecat_service.dart';
import 'services/iap_service.dart';
import 'services/repo_tracking_service.dart';
import 'services/stripe_user_service.dart';
import 'services/user_verification_service.dart';
import 'services/app_flow_service.dart';
import 'services/onnx_ai_service.dart';
import 'theme/app_themes.dart';

// Global logger instance
final logger = Logger();

void main() async {
  // Disable mouse tracking to prevent crashes
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (optional - works with .env file or system env vars)
  try {
    await dotenv.load(fileName: '.env');
    logger.i('Successfully loaded .env file');
  } catch (e) {
    logger.i('No .env file found - using system environment variables');
    // Continue without .env file - environment variables will be loaded from system
  }
  
  // Stripe service will be initialized through the provider system
  logger.i('Stripe service will be initialized through providers');
  
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
        ChangeNotifierProvider<StripeService>(
          create: (context) {
            final stripeService = StripeService();
            // Initialize the service
            stripeService.initialize();
            return stripeService;
          },
        ),
        ChangeNotifierProxyProvider<StripeService, StripeUserService>(
          create: (context) {
            logger.d('Main: Creating StripeUserService...');
            final userService = StripeUserService();
            final stripeService = Provider.of<StripeService>(context, listen: false);
            
            // Connect the services
            userService.setStripeService(stripeService);
            
            logger.d('Main: StripeUserService created successfully');
            return userService;
          },
          update: (context, stripeService, previous) {
            if (previous != null) {
              previous.setStripeService(stripeService);
              return previous;
            }
            final userService = StripeUserService();
            userService.setStripeService(stripeService);
            return userService;
          },
        ),
        ChangeNotifierProxyProvider<GitHubService, UserVerificationService>(
          create: (context) {
            logger.d('Main: Creating UserVerificationService...');
            final githubService = Provider.of<GitHubService>(context, listen: false);
            final stripeService = Provider.of<StripeService>(context, listen: false);
            final verificationService = UserVerificationService(githubService, stripeService);
            logger.d('Main: UserVerificationService created successfully');
            return verificationService;
          },
          update: (context, githubService, previous) {
            if (previous != null) {
              logger.d('Main: Updating UserVerificationService...');
              return previous;
            }
            logger.d('Main: Creating new UserVerificationService in update...');
            final stripeService = Provider.of<StripeService>(context, listen: false);
            return UserVerificationService(githubService, stripeService);
          },
        ),
        ChangeNotifierProxyProvider<StripeUserService, IAPService>(
          create: (context) {
            logger.d('Main: Creating IAPService...');
            final iapService = IAPService();
            final userService = Provider.of<StripeUserService>(context, listen: false);
            logger.d('Main: Setting user service on IAPService...');
            iapService.setAuthService(userService);
            logger.d('Main: IAPService created and configured successfully');
            return iapService;
          },
          update: (context, userService, previous) {
            if (previous != null) {
              logger.d('Main: Updating IAPService with new user service...');
              previous.setAuthService(userService);
              return previous;
            }
            logger.d('Main: Creating new IAPService in update...');
            final iapService = IAPService();
            iapService.setAuthService(userService);
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
    logger.d('AppFlowWrapper: Starting to determine initial screen...');
    try {
             // First, test Stripe connection and verify user data
       if (!mounted) return;
       
       final verificationService = Provider.of<UserVerificationService>(context, listen: false);
       logger.d('AppFlowWrapper: Testing Stripe connection...');
      
             // Test the Stripe connection (ping functionality)
       final isVerified = await verificationService.verifyUserData();
      logger.d('AppFlowWrapper: User verification result: $isVerified');
      
             // Stripe services don't need connection service notification
      
      if (!isVerified) {
        logger.w('AppFlowWrapper: User verification failed, showing error screen');
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
                       'Failed to connect to Stripe',
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
      logger.d('AppFlowWrapper: Got next screen: ${nextScreen.runtimeType}');
      if (mounted) {
        setState(() {
          _currentScreen = nextScreen;
        });
        logger.i('AppFlowWrapper: Screen updated successfully');
      } else {
        logger.w('AppFlowWrapper: Widget not mounted, skipping setState');
      }
    } catch (e, stackTrace) {
      logger.e('AppFlowWrapper: Error determining initial screen: $e', error: e, stackTrace: stackTrace);
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