import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../services/github_service.dart';
import '../services/markdown_service.dart';
import '../services/project_selection_service.dart';
import '../services/project_service.dart';
import '../theme/app_themes.dart';

import '../widgets/simple_ai_widget.dart';

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
  bool _isUpdating = false; // Track if we're updating a to-do
  
  List<Todo> get _filteredTodos {
    final todos = widget.project.todos;
    
    debugPrint('Project has ${todos.length} to-dos');
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
        return a.isCompleted ? 1 : -1; // Open to-dos first
      });
    
    debugPrint('After sorting, first 5 to-dos:');
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
            
            // Simple AI Section
            SimpleAIWidget(project: widget.project),
            
            const SizedBox(height: 24),
            
            // Filter Section and Add To-Do Button Row
            Row(
              children: [
                Expanded(
                  child: Row(
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
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddTodoDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add To-Do'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // To-dos Section
            Text(
              'To-dos (${_filteredTodos.length}${_filterType != 'All' ? ' $_filterType' : ''})',
              style: AppThemes.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // To-dos List
            ..._buildGroupedTodos(),
            
            const SizedBox(height: 32),
            
            // Remove Project Button (at the bottom)
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteProjectDialog(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove Project from App'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppThemes.errorRed,
                  side: BorderSide(color: AppThemes.errorRed),
                ),
              ),
            ),
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
        debugPrint('Getting file SHA for: ${widget.project.owner}/${widget.project.repoName}/${widget.project.repoName}-TODO.md');
        currentSha = await githubService.getFileSha(
          widget.project.owner,
          widget.project.repoName,
          '${widget.project.repoName}-TODO.md',
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
                debugPrint('  Path: ${widget.project.repoName}-TODO.md');
      debugPrint('  Content length: ${updatedContent.length}');
      debugPrint('  SHA: $currentSha');
      
      final success = await githubService.createOrUpdateFile(
        widget.project.owner,
        widget.project.repoName,
                  '${widget.project.repoName}-TODO.md',
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
                  ? 'To-do marked as completed!' 
                  : 'To-do marked as pending!'
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
      // _lastError = e.toString(); // Removed
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update to-do: $e'),
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

  void _showDeleteProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Project'),
        content: Text(
          'Are you sure you want to remove "${widget.project.name}" from the app?\n\n'
          'This will:\n'
          '• Remove the project from your dashboard\n'
          '• Keep the repository on GitHub\n'
          '• Remove any local data from this app\n\n'
          'You can always add it back later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteProject();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemes.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove Project'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject() async {
    try {
      // Get the ProjectSelectionService to remove the project
      final projectSelectionService = Provider.of<ProjectSelectionService>(context, listen: false);
      
      // Convert string ID to int for the service
      final projectId = int.tryParse(widget.project.id);
      if (projectId == null) {
        throw Exception('Invalid project ID format');
      }
      
      // Remove the project from selections
      await projectSelectionService.toggleProjectSelection(projectId);
      
      if (mounted) {
        // Also notify the ProjectService to refresh its list
        final projectService = Provider.of<ProjectService>(context, listen: false);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${widget.project.name}" removed successfully'),
            backgroundColor: AppThemes.successGreen,
          ),
        );
        
        // Navigate back to dashboard
        Navigator.of(context).pop();
        
        // Refresh projects after navigation to avoid BuildContext issues
        projectService.refreshProjects();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove project: $e'),
            backgroundColor: AppThemes.errorRed,
          ),
        );
      }
    }
  }
  
  void _showAddTodoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedSection;
    
    // Get available sections from existing todos
    final availableSections = widget.project.todos
        .map((todo) => todo.section)
        .where((section) => section != null)
        .map((section) => section!)
        .toSet()
        .toList();
    
    // Add common sections if they don't exist
    final commonSections = [
      'Current Progress',
      'Next Steps', 
      'Roadmap',
      'General Tasks',
      'Bug Fixes',
      'Features',
      'Documentation',
      'Testing',
      'Deployment',
    ];
    
    for (final section in commonSections) {
      if (!availableSections.contains(section)) {
        availableSections.add(section);
      }
    }
    
    // Sort sections by priority
    availableSections.sort((a, b) => 
        MarkdownService.getSectionPriority(a).compareTo(MarkdownService.getSectionPriority(b)));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New To-Do'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'To-Do Title *',
                hintText: 'Enter the to-do title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSection,
              decoration: const InputDecoration(
                labelText: 'Category (Optional)',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select a category or leave blank'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('No Category'),
                ),
                ...availableSections.map((section) => DropdownMenuItem<String>(
                  value: section,
                  child: Text(section),
                )),
              ],
              onChanged: (value) {
                selectedSection = value;
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
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a to-do title'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop();
              await _addTodo(
                titleController.text.trim(),
                notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                selectedSection,
              );
            },
            child: const Text('Add To-Do'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addTodo(String title, String? notes, String? section) async {
    try {
      // Create new todo with a unique ID
      final newTodo = Todo(
        id: '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}',
        title: title,
        notes: notes,
        section: section ?? 'General Tasks',
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      
      // Add to project
      widget.project.todos.add(newTodo);
      
      // Update project progress
      widget.project.lastUpdated = DateTime.now();
      
      // Trigger UI update
      setState(() {});
      
      // Save to GitHub
      final githubService = Provider.of<GitHubService>(context, listen: false);
      final updatedContent = MarkdownService.generateEnhancedProjectMarkdown(widget.project);
      
      // Get current file SHA
      String? currentSha;
      try {
        currentSha = await githubService.getFileSha(
          widget.project.owner,
          widget.project.repoName,
          '${widget.project.repoName}-TODO.md',
        );
      } catch (e) {
        // File might not exist yet, that's okay for creation
      }
      
      final success = await githubService.createOrUpdateFile(
        widget.project.owner,
        widget.project.repoName,
        '${widget.project.repoName}-TODO.md',
        updatedContent,
        'Add new to-do: $title',
        sha: currentSha,
      );
      
      if (!success) {
        throw Exception('Failed to save to-do to GitHub');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('To-do "$title" added successfully!'),
            backgroundColor: AppThemes.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      // Remove from local state on error
      widget.project.todos.removeLast();
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to-do: $e'),
            backgroundColor: AppThemes.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
