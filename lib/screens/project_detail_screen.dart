import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../services/github_service.dart';
import '../services/markdown_service.dart';
import '../services/user_identity_service.dart';
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
  bool _isUpdating = false; // Track if we're updating a todo
  String _lastError = ''; // Store the last error for display
  
  List<Todo> get _filteredTodos {
    final todos = widget.project.todos;
    
    debugPrint('Project has ${todos.length} todos');
    for (final todo in todos.take(5)) {
      debugPrint('  - ${todo.title} (${todo.section})');
    }
    
    // Sort: by section priority first, then by completion status within each section
    final sortedTodos = List<Todo>.from(todos)
      ..sort((a, b) {
        // First, sort by section priority
        final sectionA = MarkdownService.getSectionPriority(a.section);
        final sectionB = MarkdownService.getSectionPriority(b.section);
        
        debugPrint('Comparing ${a.title} (${a.section}, priority: $sectionA) vs ${b.title} (${b.section}, priority: $sectionB)');
        
        if (sectionA != sectionB) {
          return sectionA.compareTo(sectionB);
        }
        
        // Within the same section, sort by completion status (open first)
        if (a.isCompleted == b.isCompleted) {
          return 0; // Same completion status, maintain order
        }
        return a.isCompleted ? 1 : -1; // Open todos first
      });
    
    debugPrint('After sorting, first 5 todos:');
    for (final todo in sortedTodos.take(5)) {
      debugPrint('  - ${todo.title} (${todo.section})');
    }
    
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
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              // Show debug info
              final authenticatedUsername = await UserIdentityService.getUsername();
              final authenticatedUserId = await UserIdentityService.getUserId();
              final userData = await UserIdentityService.getAllUserData();
              
              setState(() {
                _lastError = '''Debug Info - No Error
Authenticated User: $authenticatedUsername (ID: $authenticatedUserId)
Project: ${widget.project.owner}/${widget.project.repoName}
File: ${widget.project.repoName}-todo.md
Todos: ${widget.project.todos.length}
Repository URL: ${widget.project.repositoryUrl}
Project ID: ${widget.project.id}
All User Data: $userData''';
              });
            },
            tooltip: 'Debug Info',
          ),
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
            
            // Debug Info Section (only show if there's an error)
            if (_lastError.isNotEmpty) ...[
              Card(
                color: Colors.red.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Info - Last Error:',
                        style: AppThemes.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Project: ${widget.project.owner}/${widget.project.repoName}',
                        style: AppThemes.bodyMedium.copyWith(color: Colors.white70),
                      ),
                      Text(
                        'File Path: ${widget.project.repoName}-todo.md',
                        style: AppThemes.bodyMedium.copyWith(color: Colors.white70),
                      ),
                      Text(
                        'Error: $_lastError',
                        style: AppThemes.bodyMedium.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _lastError = '';
                                });
                              },
                              child: const Text('Clear Error', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Copy error to clipboard
                              // This would require clipboard package
                            },
                            child: const Text('Copy Error', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
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
            ..._buildGroupedTodos(),
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

  Future<void> _toggleTodoCompletion(Todo todo) async {
    if (_isUpdating) return; // Prevent multiple simultaneous updates
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      // Update local state immediately for UI responsiveness
      todo.isCompleted = !todo.isCompleted;
      
      // Trigger UI update
      setState(() {});
      
      // Update the project's progress calculation
      widget.project.lastUpdated = DateTime.now();
      
      // Call GitHub API to update the project file
      final githubService = Provider.of<GitHubService>(context, listen: false);
      
      // Generate the updated markdown content with proper completion status
      final updatedContent = MarkdownService.generateEnhancedProjectMarkdown(widget.project);
      
      // Try to get the current file SHA, but handle the case where it might not exist
      String? currentSha;
      try {
        debugPrint('Getting file SHA for: ${widget.project.owner}/${widget.project.repoName}/${widget.project.repoName}-todo.md');
        currentSha = await githubService.getFileSha(
          widget.project.owner,
          widget.project.repoName,
          '${widget.project.repoName}-todo.md',
        );
        debugPrint('File SHA result: $currentSha');
      } catch (e) {
        // File might not exist yet, that's okay for creation
        debugPrint('Could not get current file SHA: $e');
      }
      
      // Update or create the file on GitHub
      debugPrint('Calling createOrUpdateFile with:');
      debugPrint('  Owner: ${widget.project.owner}');
      debugPrint('  Repo: ${widget.project.repoName}');
      debugPrint('  Path: ${widget.project.repoName}-todo.md');
      debugPrint('  Content length: ${updatedContent.length}');
      debugPrint('  SHA: $currentSha');
      
      final success = await githubService.createOrUpdateFile(
        widget.project.owner,
        widget.project.repoName,
        '${widget.project.repoName}-todo.md',
        updatedContent,
        'Update todo completion status: ${todo.isCompleted ? 'completed' : 'pending'} ${todo.title}',
        sha: currentSha,
      );
      
      if (!success) {
        throw Exception('Failed to update file on GitHub');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              todo.isCompleted 
                  ? 'Todo marked as completed!' 
                  : 'Todo marked as pending!'
            ),
            backgroundColor: AppThemes.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      // Revert local state on error
      todo.isCompleted = !todo.isCompleted;
      setState(() {});
      
      // Store the detailed error for display
      _lastError = e.toString();
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update todo: $e'),
            backgroundColor: AppThemes.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  List<Widget> _buildGroupedTodos() {
    final groupedTodos = <Widget>[];
    final Map<String, List<Todo>> todosBySection = {};

    for (final todo in _filteredTodos) {
      final section = todo.section ?? 'General Tasks';
      if (!todosBySection.containsKey(section)) {
        todosBySection[section] = [];
      }
      todosBySection[section]!.add(todo);
    }

    // Sort sections by priority
    final sortedSections = todosBySection.keys.toList()
      ..sort((a, b) => MarkdownService.getSectionPriority(a).compareTo(MarkdownService.getSectionPriority(b)));

    for (final section in sortedSections) {
      final todos = todosBySection[section]!;
      groupedTodos.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(
                section,
                style: AppThemes.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ...todos.map((todo) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  todo.isCompleted 
                      ? Icons.check_circle 
                      : Icons.radio_button_unchecked,
                  color: todo.isCompleted 
                      ? AppThemes.successGreen 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        todo.title,
                        style: AppThemes.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          decoration: todo.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                    ),
                    if (_isUpdating)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                subtitle: todo.notes != null && todo.notes!.isNotEmpty
                    ? Text(
                        todo.notes!,
                        style: AppThemes.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: todo.isCompleted && todo.completedAt != null
                    ? Text(
                        'Completed ${_formatDate(todo.completedAt!)}',
                        style: AppThemes.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      )
                    : null,
                onTap: () {
                  _toggleTodoCompletion(todo);
                },
              ),
            )),
          ],
        ),
      );
    }

    return groupedTodos;
  }
}
