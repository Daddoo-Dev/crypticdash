import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
              content: 'Learn what you can do now that you\'re logged in',
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
              title: 'To-Do Management',
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

            // Troubleshooting
            Text(
              '🔧 Troubleshooting',
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
        title: '🚀 Welcome to CrypticDash!',
        children: const [
          HelpSection(
            title: 'What You Can Do Now',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Add your first project using the + button on the dashboard',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Create your first to-do by opening a project and clicking "Add To-Do"',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Check your subscription status in Settings → Account & Subscription',
              ),
                             HelpStep(
                 stepNumber: 4,
                 description: 'AI features are automatically active for all users',
               ),
              HelpStep(
                stepNumber: 5,
                description: 'Set up cross-device sync in Settings → GitHub Integration',
              ),
            ],
          ),
          HelpSection(
            title: 'Quick Navigation',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Dashboard - View and manage all your projects',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Project Details - Create and manage to-dos for each project',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Settings - Configure app preferences and subscription',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Help - Access this guide and troubleshooting',
              ),
            ],
          ),
          HelpTip(
            tip: 'Your projects and to-dos automatically sync with GitHub, so your work is always backed up and accessible.',
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
        title: '✅ To-Do Management',
        children: const [
          HelpSection(
            title: 'Creating To-Dos',
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
            title: 'Managing To-Dos',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Tap any to-do to toggle completion status',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Use filters to view All/Pending/Completed tasks',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'To-dos are automatically grouped by category',
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
             title: 'AI Features',
             children: [
               HelpStep(
                 stepNumber: 1,
                 description: 'AI features are automatically active',
               ),
               HelpStep(
                 stepNumber: 2,
                 description: 'No setup required - AI analyzes your projects',
               ),
               HelpStep(
                 stepNumber: 3,
                 description: 'Available to all users (free, trial, premium)',
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
            title: 'To-Dos Not Saving',
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
        children: [
          HelpSection(
            title: 'Getting Started',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Sign in with GitHub using OAuth or Personal Access Token',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Select which repositories to monitor from your GitHub account',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Use the dashboard to view all your selected projects',
              ),
            ],
          ),
          HelpSection(
            title: 'Managing Projects',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Add more repositories using the + button on the dashboard',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Filter repositories by Personal or Organization in project selection',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Remove projects by opening project details and scrolling to the bottom',
              ),
            ],
          ),
          HelpSection(
            title: 'AI-Powered To-Do Management',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Click "Analyze & Generate To-Do" in any project to use the Yeti Assistant',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'The AI analyzes your repository and creates structured To-Do lists',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Mark To-Dos as complete by tapping them - changes sync automatically to GitHub',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'Add your own To-Dos manually using the "Add To-Do" button',
              ),
            ],
          ),
          HelpSection(
            title: 'Tips & Best Practices',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Start with smaller repositories for AI analysis - it works better on focused projects',
              ),
              HelpStep(
                stepNumber: 2,
                description: 'Use the search bar to quickly find specific projects on your dashboard',
              ),
              HelpStep(
                stepNumber: 3,
                description: 'Check your subscription status in Settings → Account & Subscription',
              ),
              HelpStep(
                stepNumber: 4,
                description: 'All To-Do changes are automatically saved to GitHub - no manual saving needed',
              ),
            ],
          ),
          HelpTip(
            tip: 'The Yeti Assistant is the core feature - it analyzes your code and creates intelligent To-Do lists based on your actual project structure.',
          ),
        ],
      ),
    );
  }



  void _showFAQHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(
        title: '❓ Frequently Asked Questions',
        children: [
          HelpSection(
            title: 'AI Analysis',
            children: [
              HelpStep(
                stepNumber: 1,
                description: 'Why did the AI analysis fail?\n\nThe AI analysis can fail if your repository is very large, has no readable files, or if there are GitHub API rate limits. Try with a smaller repository first.',
              ),
            ],
          ),
          HelpSection(
            title: 'Repository Access',
            children: [
              HelpStep(
                stepNumber: 2,
                description: 'Why can\'t I see all my GitHub repositories?\n\nOnly repositories you have write access to will appear. Private repos require proper permissions, and very large repos may not load immediately.',
              ),
            ],
          ),
          HelpSection(
            title: 'Data Sync',
            children: [
              HelpStep(
                stepNumber: 3,
                description: 'Why aren\'t my To-Do changes saving to GitHub?\n\nChanges sync automatically, but require internet connection and proper GitHub permissions. Check your connection and repository access.',
              ),
            ],
          ),
          HelpSection(
            title: 'Subscription',
            children: [
              HelpStep(
                stepNumber: 4,
                description: 'What\'s the difference between free and Premium?\n\nFree includes basic AI analysis and To-Do management. Premium adds advanced AI features, priority support, and unlimited repository analysis.',
              ),
            ],
          ),
          HelpSection(
            title: 'Security',
            children: [
              HelpStep(
                stepNumber: 5,
                description: 'Is my data safe with CrypticDash?\n\nYes, all data is stored securely on GitHub in your repositories. CrypticDash uses enterprise-grade security standards (same as major financial institutions) and only reads/writes To-Do files - your source code remains private.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openGitHubRepository(BuildContext context) async {
    try {
      final url = Uri.parse('https://github.com/shawnmcpeek/crypticdash');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open GitHub repository'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening repository: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _createIssue(BuildContext context) async {
    try {
      final url = Uri.parse('https://github.com/shawnmcpeek/crypticdash/issues');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open GitHub issues'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening issues: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
