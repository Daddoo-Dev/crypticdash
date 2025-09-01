import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/github_service.dart';
import '../services/user_identity_service.dart';

import '../services/project_selection_service.dart';
import '../services/revenuecat_service.dart';
import '../services/settings_service.dart';
import '../theme/app_themes.dart';
import '../screens/help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return _buildSettingsContent(context, settingsService);
      },
    );
  }

  Widget _buildSettingsContent(BuildContext context, SettingsService settingsService) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: 'Help & Support',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account & Subscription Section
            _buildSectionHeader(
              context,
              'Account & Subscription',
              Icons.account_circle,
              colorScheme.primary,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subscription Status Card
                    Consumer<StripeService>(
                      builder: (context, stripeService, child) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: stripeService.hasPremiumAccess 
                                ? AppThemes.successGreen.withValues(alpha: 0.1)
                                : AppThemes.warningOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: stripeService.hasPremiumAccess 
                                  ? AppThemes.successGreen 
                                  : AppThemes.warningOrange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                stripeService.hasPremiumAccess 
                                    ? Icons.verified 
                                    : Icons.info_outline,
                                color: stripeService.hasPremiumAccess 
                                    ? AppThemes.successGreen 
                                    : AppThemes.warningOrange,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stripeService.hasPremiumAccess 
                                          ? 'Premium Subscription' 
                                          : 'Free Trial',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: stripeService.hasPremiumAccess 
                                            ? AppThemes.successGreen 
                                            : AppThemes.warningOrange,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      stripeService.hasPremiumAccess 
                                          ? 'Unlimited repositories and features' 
                                          : '30-day free trial • 5 repositories',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (!stripeService.hasPremiumAccess)
                                ElevatedButton(
                                  onPressed: () async {
                                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                                    final success = await stripeService.purchasePremium();
                                    if (success && mounted) {
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Checkout launched! Complete your purchase to upgrade.'),
                                          backgroundColor: AppThemes.successGreen,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppThemes.successGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: const Text('Upgrade'),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // User Profile Info
                    FutureBuilder<Map<String, dynamic>>(
                      future: UserIdentityService.getAllUserData(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final userData = snapshot.data!;
                          return Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(userData['name'] ?? 'Unknown Name'),
                                subtitle: Text('@${userData['username'] ?? 'unknown'}'),
                                trailing: const Icon(Icons.info_outline),
                              ),
                              ListTile(
                                leading: const Icon(Icons.email),
                                title: const Text('Email'),
                                subtitle: Text(userData['email'] ?? 'No email provided'),
                                trailing: const Icon(Icons.info_outline),
                              ),
                            ],
                          );
                        } else {
                          return const ListTile(
                            leading: Icon(Icons.error),
                            title: Text('Unable to load user data'),
                            subtitle: Text('Please check your connection'),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // GitHub Integration Section
            _buildSectionHeader(
              context,
              'GitHub Integration',
              Icons.link,
              colorScheme.primary,
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Access Token'),
                    subtitle: const Text('Manage GitHub authentication'),
                    trailing: Consumer<GitHubService>(
                      builder: (context, githubService, child) {
                        final hasToken = githubService.accessToken != null;
                        return Chip(
                          label: Text(hasToken ? 'Connected' : 'Not Connected'),
                          backgroundColor: hasToken 
                              ? AppThemes.successGreen.withValues(alpha: 0.2)
                              : AppThemes.errorRed.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: hasToken ? AppThemes.successGreen : AppThemes.errorRed,
                          ),
                        );
                      },
                    ),
                    onTap: _showTokenManagement,
                  ),

                  const Divider(),
                  Consumer<ProjectSelectionService>(
                    builder: (context, projectSelectionService, child) {
                      return Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.cloud_sync),
                            title: const Text('Cross-Device Sync'),
                            subtitle: const Text('Sync repository selections across devices'),
                            value: projectSelectionService.isGistEnabled,
                            onChanged: (value) {
                              if (value) {
                                projectSelectionService.enableGistSync();
                              } else {
                                projectSelectionService.disableGistSync();
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Preferences Section
            _buildSectionHeader(
              context,
              'App Preferences',
              Icons.settings,
              colorScheme.secondary,
            ),
            Card(
              child: Column(
                children: [
                  // AI Integration

                  
                  // Project Management
                                     SwitchListTile(
                     secondary: const Icon(Icons.check_circle),
                     title: const Text('Show Completed To-dos'),
                     subtitle: const Text('Display completed tasks in lists'),
                     value: settingsService.showCompletedTodos,
                     onChanged: (value) {
                       settingsService.setShowCompletedTodos(value);
                       _saveSettings(settingsService);
                     },
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            
            
            const SizedBox(height: 24),
            
            // Support & About Section
            _buildSectionHeader(
              context,
              'Support & About',
              Icons.help,
              colorScheme.error,
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    subtitle: const Text('Documentation and troubleshooting'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showHelp,
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About crypticdash'),
                    subtitle: const Text('Version and license information'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showAbout,
                  ),

                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppThemes.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods (keeping existing methods)
  void _saveSettings(SettingsService settingsService) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: AppThemes.successGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showTokenManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub Access Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<GitHubService>(
              builder: (context, githubService, child) {
                final hasToken = githubService.accessToken != null;
                return Row(
                  children: [
                    Icon(
                      hasToken ? Icons.check_circle : Icons.error,
                      color: hasToken ? AppThemes.successGreen : AppThemes.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasToken ? 'Connected to GitHub' : 'Not connected',
                      style: TextStyle(
                        color: hasToken ? AppThemes.successGreen : AppThemes.errorRed,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Your GitHub access token is used to read repositories and manage to-do files.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          Consumer<GitHubService>(
            builder: (context, githubService, child) {
              return TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await githubService.clearAccessToken();
                  await UserIdentityService.clearUserIdentity();
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Token revoked. Please re-authenticate.'),
                        backgroundColor: AppThemes.warningOrange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppThemes.errorRed),
                child: const Text('Revoke Token'),
              );
            },
          ),
        ],
      ),
    );
  }



  









  void _showHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HelpScreen(),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData ? 'v${snapshot.data!.version}' : 'v1.0.0';
          return AlertDialog(
            title: const Text('About crypticdash'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('crypticdash $version'),
                const SizedBox(height: 8),
                const Text('CrypticDash is a comprehensive dashboard that helps developers manage multiple GitHub projects by automatically analyzing repositories and generating intelligent to-do lists, with seamless cross-device synchronization and AI-powered insights.'),
                const SizedBox(height: 16),
                const Text('© 2025 crypticdash Team'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }


}
