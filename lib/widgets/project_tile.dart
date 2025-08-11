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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: AppThemes.titleLarge.copyWith(
                        fontWeight: FontWeight.w600,
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
                    color: AppThemes.neutralGrey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.owner,
                      style: AppThemes.bodyMedium.copyWith(
                        color: AppThemes.neutralGrey,
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
                  style: AppThemes.bodyMedium,
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
                        style: AppThemes.labelLarge,
                      ),
                      Text(
                        '${project.progress.toStringAsFixed(0)}%',
                        style: AppThemes.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: project.progress / 100,
                    backgroundColor: AppThemes.lightGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      project.progress == 100 
                          ? AppThemes.successGreen 
                          : AppThemes.primaryBlue,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stats Row
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      'Total',
                      project.totalTodos.toString(),
                      Icons.list,
                    ),
                    _buildStat(
                      'Done',
                      project.completedTodos.toString(),
                      Icons.check_circle,
                      color: AppThemes.successGreen,
                    ),
                    _buildStat(
                      'Pending',
                      project.pendingTodos.toString(),
                      Icons.pending,
                      color: AppThemes.warningOrange,
                    ),
                  ],
                ),
              ),
              
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
                  Text(
                    project.isConnected ? 'Connected' : 'Disconnected',
                    style: AppThemes.bodyMedium.copyWith(
                      color: project.isConnected 
                          ? AppThemes.successGreen 
                          : AppThemes.errorRed,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatLastUpdated(project.lastUpdated),
                    style: AppThemes.bodyMedium.copyWith(
                      color: AppThemes.neutralGrey,
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

  Widget _buildStat(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? AppThemes.primaryBlue,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppThemes.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color ?? AppThemes.primaryBlue,
          ),
        ),
        Text(
          label,
          style: AppThemes.bodyMedium.copyWith(
            color: AppThemes.neutralGrey,
            fontSize: 12,
          ),
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
