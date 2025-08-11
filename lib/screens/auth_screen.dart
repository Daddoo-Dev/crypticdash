import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/github_service.dart';
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

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final githubService = Provider.of<GitHubService>(context, listen: false);
      githubService.setAccessToken(_tokenController.text.trim());
      
      final isConnected = await githubService.testConnection();
      
      if (isConnected) {
        setState(() {
          // _isAuthenticated = true; // This line is removed
        });
        
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

  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Title
                Icon(
                  Icons.dashboard,
                  size: 80,
                  color: AppThemes.primaryBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  'Dev Dash',
                  style: AppThemes.headlineLarge.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Developer Dashboard',
                  style: AppThemes.bodyLarge.copyWith(
                    color: AppThemes.neutralGrey,
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
                            style: AppThemes.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          Text(
                            'To use Dev Dash, you need to provide a GitHub Personal Access Token. This allows the app to access your repositories and manage project files.',
                            style: AppThemes.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

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
                            onPressed: _isLoading ? null : _authenticate,
                            style: AppThemes.primaryButtonStyle,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Connect to GitHub'),
                          ),
                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () {
                              // Open GitHub token creation page
                              // You can implement URL launcher here
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
      ),
    );
  }
}
