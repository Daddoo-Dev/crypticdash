import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import '../widgets/help_widget.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to CrypticDash!',
                      style: AppThemes.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This help section will guide you through all the features and help you get the most out of your GitHub project management experience.',
                      style: AppThemes.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Start Guide
            Text(
              '🚀 Quick Start Guide',
              style: AppThemes.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            HelpWidget(
              title: 'Getting Started',
              content: 'Learn the basics of setting up and using CrypticDash',
              icon: Icons.rocket_launch,
              onTap: () => _showGettingStartedHelp(context),
            ),

            HelpWidget(
              title: 'Project Management',
              content: 'How to add, remove, and organize your projects',
              icon: Icons.folder_open,
              onTap: () => _showProjectManagementHelp(context),
            ),

            HelpWidget(
              title: 'TODO Management',
              content: 'Create, organize, and track your project tasks',
              icon: Icons.checklist,
              onTap: () => _showTodoManagementHelp(context),
            ),

            HelpWidget(
              title: 'AI Features',
              content: 'Use AI-powered insights to improve your projects',
              icon: Icons.psychology,
              onTap: () => _showAIFeaturesHelp(context),
            ),

            const SizedBox(height: 24),

            // Common Issues
            Text(
              '🚨 Common Issues',
              style: AppThemes.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            HelpWidget(
              title: 'Authentication Problems',
              content: 'Troubleshoot sign-in and permission issues',
              icon: Icons.lock_outline,
              onTap: () => _showAuthenticationHelp(context),
            ),

            HelpWidget(
              title: 'Sync Issues',
              content: 'Fix problems with data synchronization',
              icon: Icons.sync_problem,
              onTap: () => _showSyncHelp(context),
            ),

            HelpWidget(
              title: 'Performance Issues',
              content: 'Improve app speed and stability',
              icon: Icons.speed,
              onTap: () => _showPerformanceHelp(context),
            ),

            const SizedBox(height: 24),

            // Additional Resources
            Text(
              '📚 Additional Resources',
              style: AppThemes.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            HelpWidget(
              title: 'User Guide',
              content: 'Complete user manual with detailed instructions',
              icon: Icons.menu_book,
              onTap: () => _showUserGuideHelp(context),
            ),

            HelpWidget(
              title: 'Troubleshooting Guide',
              content: 'Comprehensive problem-solving guide',
              icon: Icons.build,
              onTap: () => _showTroubleshootingHelp(context),
            ),

            HelpWidget(
              title: 'FAQ',
              content: 'Frequently asked questions and answers',
              icon: Icons.question_answer,
              onTap: () => _showFAQHelp(context),
            ),

            const SizedBox(height: 24),

            // Contact Support
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Still Need Help?',
                      style: AppThemes.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you couldn\'t find the answer here, check the GitHub repository or create an issue for additional support.',
                      style: AppThemes.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openGitHubRepository(context),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('GitHub Repository'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colorScheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _createIssue(context),
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Report Issue'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showGettingStartedHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '🚀 Getting Started',
        children: const [
          HelpSection(
            title: 'First Time Setup',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Download and install CrypticDash on your device',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Launch the app and tap "Sign in with GitHub"',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Grant the necessary permissions when prompted',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Select which repositories you want to monitor',
              ),
              HelpStep(
                stepNumber: 5,
                description: 'Start managing your projects and TODOs!',
              ),
            ],
          ),
          HelpTip(
            tip: 'Use OAuth authentication for the most secure and convenient experience.',
          ),
        ],
      ),
    );
  }

  void _showProjectManagementHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '📁 Project Management',
        children: const [
          HelpSection(
            title: 'Adding Projects',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Tap the + button (floating action button)',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Browse your available GitHub repositories',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Select repositories you want to monitor',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Click "Add" to include them in your dashboard',
              ),
            ],
          ),
          HelpSection(
            title: 'Managing Projects',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Use the search bar to find specific projects',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Filter by connection status (All/Connected/Disconnected)',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Tap project tiles to view detailed information',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Remove projects from the project details screen',
              ),
            ],
          ),
          HelpTip(
            tip: 'Only repositories you have write access to will be available for selection.',
          ),
        ],
      ),
    );
  }

  void _showTodoManagementHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '✅ TODO Management',
        children: const [
          HelpSection(
            title: 'Creating TODOs',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Open any project from the dashboard',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Click "Add To-Do" button',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Enter a title (required)',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Add optional notes and select a category',
              ),
              HelpStep(
                stepNumber: 5,
                description: 'Click "Add To-Do" to save',
              ),
            ],
          ),
          HelpSection(
            title: 'Managing TODOs',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Tap any TODO to toggle completion status',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Use filters to view All/Pending/Completed tasks',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'TODOs are automatically grouped by category',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'All changes sync automatically with GitHub',
              ),
            ],
          ),
          HelpTip(
            tip: 'Use categories to organize your work and track progress across different areas.',
          ),
        ],
      ),
    );
  }

  void _showAIFeaturesHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '🤖 AI Features',
        children: const [
          HelpSection(
            title: 'Enabling AI',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Go to Settings in the app',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Toggle "Enable AI Insights" to ON',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'AI features are now available',
              ),
            ],
          ),
          HelpSection(
            title: 'Available AI Features',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Progress Analysis - Get detailed completion insights',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Next Steps - AI suggests logical next actions',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Task Prioritization - Intelligent task ordering',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Project Summaries - Generate stakeholder reports',
              ),
            ],
          ),
          HelpTip(
            tip: 'All AI processing happens locally on your device for maximum privacy.',
          ),
        ],
      ),
    );
  }

  void _showAuthenticationHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '🔐 Authentication Help',
        children: const [
          HelpSection(
            title: 'OAuth Issues',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Clear browser cache and cookies',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Try incognito/private browsing mode',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Check if GitHub is experiencing outages',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Verify your GitHub account is active',
              ),
            ],
          ),
          HelpSection(
            title: 'Personal Access Token Issues',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Generate a new token at github.com/settings/tokens',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Ensure token has repo and read:user scopes',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Check if token has expired',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Verify token has access to target repositories',
              ),
            ],
          ),
          HelpTip(
            tip: 'OAuth is recommended over Personal Access Tokens for better security and convenience.',
          ),
        ],
      ),
    );
  }

  void _showSyncHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '🔄 Sync Issues',
        children: const [
          HelpSection(
            title: 'TODOs Not Saving',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Check your internet connection',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Verify GitHub write permissions',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Check if repository still exists',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Try refreshing the project',
              ),
            ],
          ),
          HelpSection(
            title: 'Projects Not Loading',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Pull down to refresh the dashboard',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Check project selection in Manage Projects',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Verify repository access permissions',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Re-authenticate if needed',
              ),
            ],
          ),
          HelpTip(
            tip: 'Changes are cached locally and will sync when connection is restored.',
          ),
        ],
      ),
    );
  }

  void _showPerformanceHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '⚡ Performance Issues',
        children: const [
          HelpSection(
            title: 'Slow App Response',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Close unused project details',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Limit number of monitored repositories',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Check device storage and memory',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Restart the app if needed',
              ),
            ],
          ),
          HelpSection(
            title: 'Frequent Crashes',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Update to the latest app version',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Clear app cache if available',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Check device compatibility',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Reinstall the app as a last resort',
              ),
            ],
          ),
          HelpTip(
            tip: 'Keep the number of monitored projects reasonable for optimal performance.',
          ),
        ],
      ),
    );
  }

  void _showUserGuideHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '📖 User Guide',
        children: const [
          HelpSection(
            title: 'Complete Documentation',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Check the docs/USER_GUIDE.md file',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Covers all features in detail',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Includes step-by-step instructions',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Best practices and tips',
              ),
            ],
          ),
          HelpTip(
            tip: 'The User Guide is the most comprehensive resource for learning CrypticDash.',
          ),
        ],
      ),
    );
  }

  void _showTroubleshootingHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '🔧 Troubleshooting Guide',
        children: const [
          HelpSection(
            title: 'Problem-Solving Resource',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Check the docs/TROUBLESHOOTING.md file',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Common issues and solutions',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Platform-specific troubleshooting',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Diagnostic tools and commands',
              ),
            ],
          ),
          HelpTip(
            tip: 'The Troubleshooting Guide covers most common problems and their solutions.',
          ),
        ],
      ),
    );
  }

  void _showFAQHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '❓ FAQ',
        children: const [
          HelpSection(
            title: 'Frequently Asked Questions',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Check the docs/FAQ.md file',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Quick answers to common questions',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Authentication, usage, and troubleshooting',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Updated regularly with new questions',
              ),
            ],
          ),
          HelpTip(
            tip: 'The FAQ is perfect for quick answers to common questions.',
          ),
        ],
      ),
    );
  }

  void _openGitHubRepository(BuildContext context) {
    // In a real app, this would open the GitHub repository URL
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening GitHub repository...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _createIssue(BuildContext context) {
    // In a real app, this would open the GitHub issues page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening GitHub issues...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
