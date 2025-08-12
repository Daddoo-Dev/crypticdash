import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/github_service.dart';
import '../services/github_oauth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_themes.dart';
import 'dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _isOAuthLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final githubService = Provider.of<GitHubService>(context, listen: false);
    await githubService.testConnection();
  }

  Future<void> _authenticateWithToken() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final githubService = Provider.of<GitHubService>(context, listen: false);
      githubService.setAccessToken(_tokenController.text.trim());
      
      final isConnected = await githubService.testConnection();
      
      if (isConnected) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid token. Please check your GitHub Personal Access Token.'),
              backgroundColor: AppThemes.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed: $e'),
            backgroundColor: AppThemes.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _authenticateWithOAuth() async {
    setState(() {
      _isOAuthLoading = true;
    });

    try {
      final accessToken = await GitHubOAuthService.authenticate();
      
      if (accessToken != null) {
        // OAuth succeeded, proceed with authentication
        final githubService = Provider.of<GitHubService>(context, listen: false);
        githubService.setAccessToken(accessToken);
        
        final isConnected = await githubService.testConnection();
        
        if (isConnected && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OAuth authentication failed: $e'),
            backgroundColor: AppThemes.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOAuthLoading = false;
        });
      }
    }
  }

  void _toggleTheme() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    themeService.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppThemes.lightBlue,
                  Colors.white,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Theme toggle button in top right
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Icon(themeService.getThemeIcon()),
                    onPressed: _toggleTheme,
                    tooltip: 'Switch Theme (${themeService.getThemeModeName()})',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                
                // Main content
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo and Title
                        Image.asset(
                          themeService.getLogoAsset(),
                          height: 80,
                          width: 80,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          themeService.getAppName(),
                          style: AppThemes.headlineLarge.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          themeService.getAppTitle(),
                          style: AppThemes.bodyLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Authentication Form
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Connect to GitHub',
                                    style: AppThemes.headlineMedium.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  Text(
                                    'Choose your preferred authentication method:',
                                    style: AppThemes.bodyMedium.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),

                                  // OAuth Button (Primary)
                                  ElevatedButton.icon(
                                    onPressed: _isOAuthLoading ? null : _authenticateWithOAuth,
                                    style: AppThemes.primaryButtonStyle,
                                    icon: _isOAuthLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.login),
                                    label: Text(_isOAuthLoading ? 'Connecting...' : 'Sign in with GitHub'),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click to open GitHub and authorize the app',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppThemes.neutralGrey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: AppThemes.neutralGrey)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'OR',
                                          style: AppThemes.bodyMedium.copyWith(
                                            color: AppThemes.neutralGrey,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: AppThemes.neutralGrey)),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),

                                  Text(
                                    'Use Personal Access Token:',
                                    style: AppThemes.titleMedium.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),

                                  TextFormField(
                                    controller: _tokenController,
                                    decoration: const InputDecoration(
                                      labelText: 'GitHub Personal Access Token',
                                      hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                                      prefixIcon: Icon(Icons.token),
                                    ),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your GitHub token';
                                      }
                                      if (!value.trim().startsWith('ghp_')) {
                                        return 'Please enter a valid GitHub Personal Access Token';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _authenticateWithToken,
                                    style: AppThemes.secondaryButtonStyle ?? AppThemes.primaryButtonStyle,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text('Connect with Token'),
                                  ),
                                  const SizedBox(height: 16),

                                  TextButton(
                                    onPressed: () async {
                                      // Open GitHub token creation page
                                      final url = Uri.parse('https://github.com/settings/tokens');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    child: const Text('How to get a GitHub token?'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Footer
                        Text(
                          'Your token is stored locally and never shared',
                          style: AppThemes.bodyMedium.copyWith(
                            color: AppThemes.neutralGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
