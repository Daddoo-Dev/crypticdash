import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/github_service.dart';
import '../services/user_identity_service.dart';

import '../services/settings_service.dart';
import '../theme/app_themes.dart';

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
            icon: const Icon(Icons.save),
            onPressed: () => _saveSettings(settingsService),
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    leading: const Icon(Icons.api),
                    title: const Text('API Rate Limit'),
                    subtitle: const Text('Monitor GitHub API usage'),
                    onTap: _showApiInfo,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Project Management Section
            _buildSectionHeader(
              context,
              'Project Management',
              Icons.folder,
              colorScheme.secondary,
            ),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.refresh),
                    title: const Text('Auto-refresh Projects'),
                    subtitle: const Text('Automatically update project data'),
                    value: settingsService.autoRefreshEnabled,
                    onChanged: (value) {
                      settingsService.setAutoRefreshEnabled(value);
                    },
                  ),
                  if (settingsService.autoRefreshEnabled) ...[
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: const Text('Refresh Interval'),
                      subtitle: Text('Every ${settingsService.refreshIntervalMinutes} minutes'),
                      trailing: DropdownButton<int>(
                        value: settingsService.refreshIntervalMinutes,
                        items: [5, 15, 30, 60, 120].map((minutes) {
                          return DropdownMenuItem(
                            value: minutes,
                            child: Text('${minutes}m'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            settingsService.setRefreshIntervalMinutes(value);
                          }
                        },
                      ),
                    ),
                  ],
                  SwitchListTile(
                    secondary: const Icon(Icons.check_circle),
                    title: const Text('Show Completed To-dos'),
                    subtitle: const Text('Display completed tasks in lists'),
                    value: settingsService.showCompletedTodos,
                    onChanged: (value) {
                      settingsService.setShowCompletedTodos(value);
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.category),
                    title: const Text('Group To-dos by Section'),
                    subtitle: const Text('Organize tasks by markdown sections'),
                    value: settingsService.groupTodosBySection,
                    onChanged: (value) {
                      settingsService.setGroupTodosBySection(value);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // UI Preferences Section
            _buildSectionHeader(
              context,
              'Interface Preferences',
              Icons.dashboard,
              colorScheme.tertiary,
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.grid_view),
                    title: const Text('Dashboard Layout'),
                    subtitle: const Text('Grid size and card arrangement'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showLayoutSettings,
                  ),
                  ListTile(
                    leading: const Icon(Icons.animation),
                    title: const Text('Animations'),
                    subtitle: const Text('Enable smooth transitions'),
                    trailing: Switch(
                      value: true, // Default to true
                      onChanged: (value) {
                        // Animation settings would go here
                      },
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Get alerts for project updates'),
                    value: settingsService.enableNotifications,
                    onChanged: (value) {
                      settingsService.setEnableNotifications(value);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Data Management Section
            _buildSectionHeader(
              context,
              'Data & Storage',
              Icons.storage,
              colorScheme.error,
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
                    },
                  ),
                  if (settingsService.cacheProjectData) ...[
                    ListTile(
                      leading: const Icon(Icons.memory),
                      title: const Text('Cache Size Limit'),
                      subtitle: Text('Maximum ${settingsService.maxCacheSizeMB} MB'),
                      trailing: DropdownButton<int>(
                        value: settingsService.maxCacheSizeMB,
                        items: [50, 100, 200, 500].map((mb) {
                          return DropdownMenuItem(
                            value: mb,
                            child: Text('$mb MB'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            settingsService.setMaxCacheSizeMB(value);
                          }
                        },
                      ),
                    ),
                  ],
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
            
            // User Identity Section
            _buildSectionHeader(
              context,
              'User Profile',
              Icons.person,
              colorScheme.primary,
            ),
            Card(
              child: FutureBuilder<Map<String, dynamic>>(
                future: UserIdentityService.getAllUserData(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final userData = snapshot.data!;
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.account_circle),
                          title: Text(userData['name'] ?? 'Unknown Name'),
                          subtitle: Text('@${userData['username'] ?? 'unknown'}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _editProfile,
                        ),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(userData['email'] ?? 'No email provided'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _editEmail,
                        ),
                        ListTile(
                          leading: const Icon(Icons.key),
                          title: const Text('GitHub Account'),
                          subtitle: const Text('Manage authentication'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _manageGitHubAccount,
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
            ),
            
            const SizedBox(height: 24),
            
            // Actions Section
            _buildSectionHeader(
              context,
              'Actions',
              Icons.build,
              colorScheme.error,
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Reset All Settings'),
                    subtitle: const Text('Restore default configuration'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _resetSettings(settingsService),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    subtitle: const Text('Documentation and troubleshooting'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showHelp,
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About DevDash'),
                    subtitle: const Text('Version and license information'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showAbout,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _saveSettings(settingsService),
                icon: const Icon(Icons.save),
                label: const Text('Save All Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
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

  // Action Methods
  void _saveSettings(SettingsService settingsService) {
    // Settings are automatically saved when changed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: AppThemes.successGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showTokenManagement() {
    // Show token management dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub Access Token'),
        content: const Text('Manage your GitHub authentication token here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _manualSync(SettingsService settingsService) {
    // Trigger manual sync
    settingsService.updateLastSyncTime();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual sync completed!'),
        backgroundColor: AppThemes.successGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showApiInfo() {
    // Show API rate limit info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub API Status'),
        content: const Text('API rate limit information would be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLayoutSettings() {
    // Show layout settings
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard Layout'),
        content: const Text('Layout customization options would be here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    // Clear cache confirmation
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
    // Export data functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export started...'),
        backgroundColor: AppThemes.primaryBlue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _editProfile() {
    // Edit profile functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile editing not implemented yet'),
        backgroundColor: AppThemes.warningOrange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _editEmail() {
    // Edit email functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email editing not implemented yet'),
        backgroundColor: AppThemes.warningOrange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _manageGitHubAccount() {
    // Manage GitHub account
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GitHub account management not implemented yet'),
        backgroundColor: AppThemes.warningOrange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetSettings(SettingsService settingsService) {
    // Reset settings confirmation
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
    // Show help and support
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help and support not implemented yet'),
        backgroundColor: AppThemes.warningOrange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAbout() {
    // Show about information
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About DevDash'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DevDash v1.0.0'),
            SizedBox(height: 8),
            Text('A comprehensive dashboard for managing multiple GitHub projects with integrated to-do lists and progress tracking.'),
            SizedBox(height: 16),
            Text('© 2025 DevDash Team'),
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
}
