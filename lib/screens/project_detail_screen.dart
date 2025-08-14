import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme/app_themes.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  String _filterType = 'All'; // All, Completed, Pending
  
  List<Todo> get _filteredTodos {
    final todos = widget.project.todos;
    
    // Sort: open todos first, then completed
    final sortedTodos = List<Todo>.from(todos)
      ..sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return 0; // Same completion status, maintain order
        }
        return a.isCompleted ? 1 : -1; // Open todos first
      });
    
    // Apply filter
    switch (_filterType) {
      case 'Completed':
        return sortedTodos.where((todo) => todo.isCompleted).toList();
      case 'Pending':
        return sortedTodos.where((todo) => !todo.isCompleted).toList();
      default: // 'All'
        return sortedTodos;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh functionality handled by dashboard
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.name,
                      style: AppThemes.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.project.description.isNotEmpty) ...[
                      Text(
                        widget.project.description,
                        style: AppThemes.bodyLarge.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Progress Section
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progress',
                                style: AppThemes.titleMedium.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: widget.project.progress / 100,
                                backgroundColor: colorScheme.outlineVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.project.progress == 100 
                                      ? AppThemes.successGreen 
                                      : colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${widget.project.progress.toStringAsFixed(0)}%',
                          style: AppThemes.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                          context,
                          'Total',
                          widget.project.totalTodos.toString(),
                          Icons.list,
                        ),
                        _buildStat(
                          context,
                          'Done',
                          widget.project.completedTodos.toString(),
                          Icons.check_circle,
                          color: AppThemes.successGreen,
                        ),
                        _buildStat(
                          context,
                          'Pending',
                          widget.project.pendingTodos.toString(),
                          Icons.pending,
                          color: AppThemes.warningOrange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Filter Section
            Row(
              children: [
                Text(
                  'Filter:',
                  style: AppThemes.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    'All',
                    'Pending',
                    'Completed',
                  ].map((filter) {
                    return FilterChip(
                      label: Text(filter),
                      selected: _filterType == filter,
                      onSelected: (selected) {
                        setState(() {
                          _filterType = filter;
                        });
                      },
                      selectedColor: colorScheme.primaryContainer,
                      checkmarkColor: colorScheme.onPrimaryContainer,
                    );
                  }).toList(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Todos Section
            Text(
              'Todos (${_filteredTodos.length}${_filterType != 'All' ? ' $_filterType' : ''})',
              style: AppThemes.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // Todos List
            ..._filteredTodos.map((todo) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  todo.isCompleted 
                      ? Icons.check_circle 
                      : Icons.radio_button_unchecked,
                  color: todo.isCompleted 
                      ? AppThemes.successGreen 
                      : colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  todo.title,
                  style: AppThemes.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                    decoration: todo.isCompleted 
                        ? TextDecoration.lineThrough 
                        : null,
                  ),
                ),
                subtitle: todo.notes != null && todo.notes!.isNotEmpty
                    ? Text(
                        todo.notes!,
                        style: AppThemes.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: todo.isCompleted && todo.completedAt != null
                    ? Text(
                        'Completed ${_formatDate(todo.completedAt!)}',
                        style: AppThemes.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      )
                    : null,
                onTap: () {
                  // This is just for UI demonstration
                  // In real app, this would update the project service
                },
              ),
            )),
          ],
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
          size: 24,
          color: color ?? colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppThemes.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: AppThemes.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
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
