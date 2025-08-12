import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme/app_themes.dart';

class ProjectTile extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const ProjectTile({
    super.key,
    required this.project,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Project Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: AppThemes.titleLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Repository Info
              Row(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.owner,
                      style: AppThemes.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Description
              if (project.description.isNotEmpty) ...[
                Text(
                  project.description,
                  style: AppThemes.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: AppThemes.labelLarge.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${project.progress.toStringAsFixed(0)}%',
                        style: AppThemes.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: project.progress / 100,
                    backgroundColor: colorScheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      project.progress == 100 
                          ? AppThemes.successGreen 
                          : colorScheme.primary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: _buildStat(
                      context,
                      'Total',
                      project.totalTodos.toString(),
                      Icons.list,
                    ),
                  ),
                  Flexible(
                    child: _buildStat(
                      context,
                      'Done',
                      project.completedTodos.toString(),
                      Icons.check_circle,
                      color: AppThemes.successGreen,
                    ),
                  ),
                  Flexible(
                    child: _buildStat(
                      context,
                      'Pending',
                      project.pendingTodos.toString(),
                      Icons.pending,
                      color: AppThemes.warningOrange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Connection Status
              Row(
                children: [
                  Icon(
                    project.isConnected 
                        ? Icons.link 
                        : Icons.link_off,
                    size: 16,
                    color: project.isConnected 
                        ? AppThemes.successGreen 
                        : AppThemes.errorRed,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.isConnected ? 'Connected' : 'Disconnected',
                      style: AppThemes.bodyMedium.copyWith(
                        color: project.isConnected 
                            ? AppThemes.successGreen 
                            : AppThemes.errorRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _formatLastUpdated(project.lastUpdated),
                    style: AppThemes.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppThemes.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color ?? colorScheme.primary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: AppThemes.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
