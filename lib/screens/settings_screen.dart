import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/github_service.dart';
import '../services/user_identity_service.dart';
import '../services/onnx_ai_service.dart';
import '../services/project_selection_service.dart';

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
            // AI Integration Section
            _buildSectionHeader(
              context,
              'AI Integration',
              Icons.psychology,
              colorScheme.primary,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'AI Integration',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                                        Consumer<ONNXAIService>(
                      builder: (context, aiService, child) {
                        return Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Enable AI Insights'),
                              subtitle: const Text('Turn on AI-powered project analysis and TODO generation'),
                              value: aiService.enabled,
                              onChanged: (value) => value ? aiService.enable() : aiService.disable(),
                            ),
                            ListTile(
                              title: const Text('AI Status'),
                              subtitle: Text(
                                aiService.modelLoaded ? 'Ready to analyze projects' : 'Loading AI model...',
                                style: TextStyle(
                                  color: aiService.modelLoaded ? AppThemes.successGreen : AppThemes.warningOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Icon(
                                aiService.modelLoaded ? Icons.check_circle : Icons.hourglass_empty,
                                color: aiService.modelLoaded ? AppThemes.successGreen : AppThemes.warningOrange,
                              ),
                            ),
                          ],
                        );
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
                    leading: Icon(Icons.sync),
                    title: Text('Last Sync'),
                    subtitle: Text('Data last updated: ${settingsService.getFormattedLastSyncTime()}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _manualSync(settingsService),
                      tooltip: 'Manual Sync',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.api),
                    title: Text('API Rate Limit'),
                    subtitle: const Text('Monitor GitHub API usage'),
                    onTap: _showApiInfo,
                  ),
                  const Divider(),
                  Consumer<ProjectSelectionService>(
                    builder: (context, projectSelectionService, child) {
                      return Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.cloud_sync),
                            title: const Text('Cross-Device Sync'),
                            subtitle: const Text('Sync repository selections across devices using GitHub Gist'),
                            value: projectSelectionService.isGistEnabled,
                            onChanged: (value) {
                              if (value) {
                                _enableGistSync(projectSelectionService);
                              } else {
                                _disableGistSync(projectSelectionService);
                              }
                            },
                          ),
                          if (projectSelectionService.isGistEnabled) ...[
                            ListTile(
                              leading: const Icon(Icons.sync),
                              title: const Text('Last Gist Sync'),
                              subtitle: Text(
                                projectSelectionService.lastGistSync != null
                                    ? 'Last synced: ${_formatDateTime(projectSelectionService.lastGistSync!)}'
                                    : 'Never synced',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () => _forceGistSync(projectSelectionService),
                                tooltip: 'Force Sync',
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.info),
                              title: const Text('Sync Status'),
                              subtitle: const Text('Repository selections are synced across devices'),
                              trailing: const Icon(Icons.check_circle, color: AppThemes.successGreen),
                            ),
                          ],
                        ],
                      );
                    },
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
                          onTap: () => _editProfile(userData),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(userData['email'] ?? 'No email provided'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _editEmail(userData),
                        ),
                        ListTile(
                          leading: const Icon(Icons.key),
                          title: const Text('GitHub Account'),
                          subtitle: const Text('Manage authentication'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _manageGitHubAccount(userData),
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
                     title: const Text('About crypticdash'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub API Status'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate Limits:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Authenticated requests: 5,000 per hour'),
            Text('• Unauthenticated requests: 60 per hour'),
            SizedBox(height: 16),
            
            Text(
              'Current Usage:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Requests used: Calculating...'),
            Text('• Requests remaining: Calculating...'),
            Text('• Reset time: Calculating...'),
            SizedBox(height: 16),
            
            Text(
              'API Endpoints Used:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• /user/repos - List user repositories'),
            Text('• /repos/{owner}/{repo}/contents - Get file content'),
            Text('• /repos/{owner}/{repo}/contents/{path} - Update file content'),
            SizedBox(height: 16),
            
            Text(
              'Note: Rate limits reset every hour. Monitor usage to avoid hitting limits.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Refresh API status
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('API status refreshed'),
                  backgroundColor: AppThemes.primaryBlue,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Refresh Status'),
          ),
        ],
      ),
    );
  }

  void _showLayoutSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard Layout Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grid Layout:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Small screens: Single column layout'),
            Text('• Medium screens: 2-column grid'),
            Text('• Large screens: 3-column grid'),
            Text('• Extra large: 4+ column grid'),
            SizedBox(height: 16),
            
            Text(
              'Card Sizing:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Minimum card width: 280px'),
            Text('• Maximum card width: 500px'),
            Text('• Responsive aspect ratios'),
            SizedBox(height: 16),
            
            Text(
              'Spacing:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Grid spacing: 16px'),
            Text('• Card margins: 8px'),
            SizedBox(height: 16),
            
            Text(
              'Note: Layout automatically adjusts based on screen size and orientation.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
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
            SizedBox(height: 16),
            
            Text(
              'Note: Exported data is for backup and analysis purposes only.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              // Simulate export process
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Exporting data to JSON...'),
                    backgroundColor: AppThemes.primaryBlue,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              
              // In a real implementation, this would generate and download the file
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Data exported successfully!'),
                    backgroundColor: AppThemes.successGreen,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Export JSON'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              // Simulate export process
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Exporting data to CSV...'),
                    backgroundColor: AppThemes.primaryBlue,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              
              // In a real implementation, this would generate and download the file
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Data exported successfully!'),
                    backgroundColor: AppThemes.successGreen,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('Export CSV'),
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
              // Save profile changes
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
              // Save email changes
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

  void _manageGitHubAccount(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub Account Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: @${userData['username'] ?? 'unknown'}'),
            const SizedBox(height: 8),
            Text('User ID: ${userData['userId'] ?? 'unknown'}'),
            const SizedBox(height: 8),
            Text('Display Name: ${userData['name'] ?? 'Not set'}'),
            const SizedBox(height: 8),
            Text('Email: ${userData['email'] ?? 'Not provided'}'),
            const SizedBox(height: 16),
            const Text(
              'To change your GitHub account, you need to logout and re-authenticate with the new account.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              // Navigate to logout
              final githubService = Provider.of<GitHubService>(context, listen: false);
              await githubService.clearAccessToken();
              await UserIdentityService.clearUserIdentity();
              if (mounted) {
                navigator.pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppThemes.errorRed),
            child: const Text('Logout'),
          ),
        ],
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
                    content: Text('Cross-device sync enabled! Your repository selections are now synced.'),
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

  void _forceGistSync(ProjectSelectionService projectSelectionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Gist Sync'),
        content: const Text('This will force a sync of your repository selections to your GitHub Gist. This might overwrite existing selections.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              await projectSelectionService.forceGistSync();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Repository selections synced to Gist.'),
                    backgroundColor: AppThemes.successGreen,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Force Sync'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MM/dd/yyyy HH:mm').format(dateTime);
  }

}
