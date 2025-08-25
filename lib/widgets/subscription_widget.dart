import 'package:flutter/material.dart';
import '../services/iap_service.dart';
import '../services/repo_tracking_service.dart';
import '../theme/app_themes.dart';

/// Widget for displaying subscription information and management
class SubscriptionWidget extends StatelessWidget {
  final IAPService iapService;
  final RepoTrackingService repoTrackingService;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onRestorePressed;

  const SubscriptionWidget({
    super.key,
    required this.iapService,
    required this.repoTrackingService,
    this.onUpgradePressed,
    this.onRestorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([iapService, repoTrackingService]),
      builder: (context, child) {
        final subscriptionInfo = iapService.getSubscriptionInfo();
        final repoLimitInfo = repoTrackingService.getRepoLimitInfo();

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      _getSubscriptionIcon(subscriptionInfo.status),
                      size: 32,
                      color: _getSubscriptionColor(subscriptionInfo.status, colorScheme),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getSubscriptionTitle(subscriptionInfo.status),
                            style: AppThemes.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _getSubscriptionSubtitle(subscriptionInfo, repoLimitInfo),
                            style: AppThemes.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Repository Limits
                _buildRepositoryLimits(repoLimitInfo, colorScheme),

                const SizedBox(height: 20),

                // Trial Information
                if (subscriptionInfo.isInTrial) ...[
                  _buildTrialInfo(subscriptionInfo, colorScheme),
                  const SizedBox(height: 20),
                ],

                // Upgrade Options
                if (subscriptionInfo.status != SubscriptionStatus.premium) ...[
                  _buildUpgradeOptions(context, subscriptionInfo, colorScheme),
                  const SizedBox(height: 20),
                ],

                // Action Buttons
                _buildActionButtons(context, subscriptionInfo, colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build repository limits section
  Widget _buildRepositoryLimits(RepoLimitInfo limitInfo, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_open,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Repository Limits',
                style: AppThemes.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            limitInfo.limitDescription,
            style: AppThemes.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            limitInfo.upgradeMessage,
            style: AppThemes.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Build trial information section
  Widget _buildTrialInfo(SubscriptionInfo subscriptionInfo, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primaryContainer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Free Trial',
                style: AppThemes.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You have ${subscriptionInfo.trialDaysRemaining} days left in your trial.',
            style: AppThemes.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy full access to AI features on up to 3 repositories!',
            style: AppThemes.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build upgrade options section
  Widget _buildUpgradeOptions(
    BuildContext context,
    SubscriptionInfo subscriptionInfo,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondaryContainer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Upgrade to Premium',
                style: AppThemes.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Get unlimited repositories with the same powerful AI features!',
            style: AppThemes.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Only ${subscriptionInfo.price}',
                style: AppThemes.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'per year',
                style: AppThemes.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(
    BuildContext context,
    SubscriptionInfo subscriptionInfo,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        if (subscriptionInfo.status != SubscriptionStatus.premium) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onUpgradePressed,
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade to Premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRestorePressed,
            icon: const Icon(Icons.restore),
            label: const Text('Restore Purchases'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// Get subscription icon based on status
  IconData _getSubscriptionIcon(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.premium:
        return Icons.workspace_premium;
      case SubscriptionStatus.free:
        return Icons.person;
      case SubscriptionStatus.expired:
        return Icons.access_time;
    }
  }

  /// Get subscription color based on status
  Color _getSubscriptionColor(SubscriptionStatus status, ColorScheme colorScheme) {
    switch (status) {
      case SubscriptionStatus.premium:
        return colorScheme.primary;
      case SubscriptionStatus.free:
        return colorScheme.secondary;
      case SubscriptionStatus.expired:
        return colorScheme.error;
    }
  }

  /// Get subscription title based on status
  String _getSubscriptionTitle(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.premium:
        return 'Premium Subscription';
      case SubscriptionStatus.free:
        return 'Free Account';
      case SubscriptionStatus.expired:
        return 'Subscription Expired';
    }
  }

  /// Get subscription subtitle
  String _getSubscriptionSubtitle(
    SubscriptionInfo subscriptionInfo,
    RepoLimitInfo repoLimitInfo,
  ) {
    if (subscriptionInfo.status == SubscriptionStatus.premium) {
      return 'Unlimited repositories with full AI features';
    }
    
    if (subscriptionInfo.isInTrial) {
      return 'Trial period - ${subscriptionInfo.trialDaysRemaining} days remaining';
    }
    
    return 'Limited to ${repoLimitInfo.maxAllowed} repository';
  }
}
