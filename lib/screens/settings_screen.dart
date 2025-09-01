import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _editProfile(userData),
                              ),
                              ListTile(
                                leading: const Icon(Icons.email),
                                title: const Text('Email'),
                                subtitle: Text(userData['email'] ?? 'No email provided'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _editEmail(userData),
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
                                     ListTile(
                     leading: const Icon(Icons.sync),
                     title: const Text('Last Sync'),
                     subtitle: Text('Data last updated: ${settingsService.getFormattedLastSyncTime()}'),
                     trailing: IconButton(
                       icon: const Icon(Icons.refresh),
                       onPressed: () => _manualSync(settingsService),
                       tooltip: 'Manual Sync',
                     ),
                   ),
                   ListTile(
                     leading: const Icon(Icons.schedule),
                     title: const Text('Current Time'),
                     subtitle: Text(DateFormat.yMMMd().add_jm().format(DateTime.now())),
                     trailing: const Icon(Icons.info_outline),
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
                                _enableGistSync(projectSelectionService);
                              } else {
                                _disableGistSync(projectSelectionService);
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
                     secondary: const Icon(Icons.refresh),
                     title: const Text('Auto-refresh Projects'),
                     subtitle: const Text('Automatically update project data'),
                     value: settingsService.autoRefreshEnabled,
                     onChanged: (value) {
                       settingsService.setAutoRefreshEnabled(value);
                       _saveSettings(settingsService);
                     },
                   ),
                  
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
                  
                                     SwitchListTile(
                     secondary: const Icon(Icons.notifications),
                     title: const Text('Enable Notifications'),
                     subtitle: const Text('Get alerts for project updates'),
                     value: settingsService.enableNotifications,
                     onChanged: (value) {
                       settingsService.setEnableNotifications(value);
                       _saveSettings(settingsService);
                     },
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Data & Storage Section
            _buildSectionHeader(
              context,
              'Data & Storage',
              Icons.storage,
              colorScheme.tertiary,
            ),
            Card(
              child: Column(
                children: [
                                     SwitchListTile(
                     secondary: const Icon(Icons.storage),
                     title: const Text('Cache Project Data'),
                     subtitle: const Text('Store data locally for offline access'),
                     value: settingsService.cacheProjectData,
                     onChanged: (value) {
                       settingsService.setCacheProjectData(value);
                       _saveSettings(settingsService);
                     },
                   ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep),
                    title: const Text('Clear Cache'),
                    subtitle: const Text('Remove all cached data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _clearCache,
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Export Data'),
                    subtitle: const Text('Download project data as JSON/CSV'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _exportData,
                  ),
                ],
              ),
            ),
            
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
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Reset All Settings'),
                    subtitle: const Text('Restore default configuration'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _resetSettings(settingsService),
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
        title: const Text('GitHub Access Token Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
                      hasToken ? 'Token is valid and connected' : 'No valid token found',
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
              'Token Actions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• View token permissions and scope'),
            const Text('• Test token validity'),
            const Text('• Revoke current token'),
            const Text('• Generate new token'),
            const SizedBox(height: 16),
            const Text(
              'Note: For security reasons, tokens are stored locally and encrypted.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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

  void _manualSync(SettingsService settingsService) {
    settingsService.updateLastSyncTime();
    _saveSettings(settingsService);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual sync completed!'),
        backgroundColor: AppThemes.successGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove all cached data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully!'),
                  backgroundColor: AppThemes.successGreen,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppThemes.errorRed),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Project Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Format:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• JSON: Complete project data with metadata'),
            Text('• CSV: Simplified table format for spreadsheets'),
            SizedBox(height: 16),
            Text(
              'Data Included:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Project information and descriptions'),
            Text('• To-do lists with completion status'),
            Text('• Progress tracking data'),
            Text('• Repository connection status'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data exported successfully!'),
                  backgroundColor: AppThemes.successGreen,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Export JSON'),
          ),
        ],
      ),
    );
  }

  void _editProfile(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your display name',
              ),
              controller: TextEditingController(text: userData['name'] ?? ''),
              onChanged: (value) {
                userData['name'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your username',
              ),
              controller: TextEditingController(text: userData['username'] ?? ''),
              onChanged: (value) {
                userData['username'] = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await UserIdentityService.storeUserIdentity(
                username: userData['username'] ?? '',
                userId: userData['userId'] ?? 0,
                name: userData['name'],
                email: userData['email'],
              );
              if (mounted) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: AppThemes.successGreen,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editEmail(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email address',
              ),
              controller: TextEditingController(text: userData['email'] ?? ''),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                userData['email'] = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await UserIdentityService.storeUserIdentity(
                username: userData['username'] ?? '',
                userId: userData['userId'] ?? 0,
                name: userData['name'],
                email: userData['email'],
              );
              if (mounted) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Email updated successfully!'),
                    backgroundColor: AppThemes.successGreen,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _resetSettings(SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text('This will restore all settings to their default values. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              settingsService.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults!'),
                  backgroundColor: AppThemes.warningOrange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppThemes.errorRed),
            child: const Text('Reset'),
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
      builder: (context) => AlertDialog(
        title: const Text('About crypticdash'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('crypticdash v1.0.0'),
            SizedBox(height: 8),
            Text('A comprehensive dashboard for managing multiple GitHub projects with integrated to-do lists and progress tracking.'),
            SizedBox(height: 16),
            Text('© 2025 crypticdash Team'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _enableGistSync(ProjectSelectionService projectSelectionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Cross-Device Sync'),
        content: const Text('This will enable cross-device sync using GitHub Gist. Your repository selections will be stored in your GitHub Gist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              await projectSelectionService.enableGistSync();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Cross-device sync enabled!'),
                    backgroundColor: AppThemes.successGreen,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Enable Sync'),
          ),
        ],
      ),
    );
  }

  void _disableGistSync(ProjectSelectionService projectSelectionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Cross-Device Sync'),
        content: const Text('This will disable cross-device sync. Your repository selections will no longer be synced across devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              await projectSelectionService.disableGistSync();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Cross-device sync disabled.'),
                    backgroundColor: AppThemes.warningOrange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Disable Sync'),
          ),
        ],
      ),
    );
  }
}
