import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/project_service.dart';
import '../services/github_service.dart';
import '../models/github_repository.dart';
import '../theme/app_themes.dart';

class AddProjectDialog extends StatefulWidget {
  const AddProjectDialog({super.key});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  bool _isLoading = false;
  List<GitHubRepository> _repositories = [];
  GitHubRepository? _selectedRepository;
  String _selectedTemplate = 'Web App';

  @override
  void initState() {
    super.initState();
    _loadRepositories();
  }

  Future<void> _loadRepositories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final githubService = Provider.of<GitHubService>(context, listen: false);
      final repos = await githubService.getUserRepositories();
      
      // Filter repositories that the user can write to
      final writableRepos = repos.where((repo) => repo.canWrite).toList();
      
      setState(() {
        _repositories = writableRepos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load repositories: $e'),
            backgroundColor: AppThemes.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _addProject() async {
    if (_selectedRepository == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.loadProjects();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project ${_selectedRepository!.name} added successfully!'),
            backgroundColor: AppThemes.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add project: $e'),
            backgroundColor: AppThemes.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppThemes.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Project',
                    style: AppThemes.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Repository Selection
                    Text(
                      'Select Repository',
                      style: AppThemes.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (_repositories.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppThemes.lightGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'No writable repositories found. Make sure you have the necessary permissions.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppThemes.neutralGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<GitHubRepository>(
                          value: _selectedRepository,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          hint: const Text('Choose a repository...'),
                          items: _repositories.map((repo) {
                            return DropdownMenuItem(
                              value: repo,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    repo.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    repo.description.isNotEmpty 
                                        ? repo.description 
                                        : 'No description',
                                    style: TextStyle(
                                      color: AppThemes.neutralGrey,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRepository = value;
                            });
                          },
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Template Selection
                    Text(
                      'Project Template',
                      style: AppThemes.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 8,
                      children: [
                        'Web App',
                        'Mobile App',
                        'API',
                        'Library',
                        'CLI Tool',
                        'Custom',
                      ].map((template) {
                        return FilterChip(
                          label: Text(template),
                          selected: _selectedTemplate == template,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTemplate = template;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Template Preview
                    if (_selectedTemplate != 'Custom') ...[
                      Text(
                        'Template Preview',
                        style: AppThemes.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppThemes.lightGrey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppThemes.neutralGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTemplate,
                              style: AppThemes.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A ${_selectedTemplate.toLowerCase()} project template with common development tasks and milestones.',
                              style: AppThemes.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _selectedRepository != null && !_isLoading 
                              ? _addProject 
                              : null,
                          style: AppThemes.primaryButtonStyle,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Add Project'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
