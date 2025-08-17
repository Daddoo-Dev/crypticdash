import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/github_repository.dart';
import '../services/github_service.dart';
import '../services/project_selection_service.dart';
import '../theme/app_themes.dart';
import 'dashboard_screen.dart';

class ProjectSelectionScreen extends StatefulWidget {
  final bool isSetupMode;
  
  const ProjectSelectionScreen({
    super.key,
    this.isSetupMode = true,
  });

  @override
  State<ProjectSelectionScreen> createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> {
  bool _isLoading = true;
  List<GitHubRepository> _repositories = [];
  String _searchQuery = '';

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
      
      if (mounted) {
        setState(() {
          _repositories = repos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load repositories: $e'),
            backgroundColor: AppThemes.errorRed,
          ),
        );
      }
    }
  }

  List<GitHubRepository> get _filteredRepositories {
    if (_searchQuery.isEmpty) return _repositories;
    return _repositories.where((repo) =>
      repo.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      repo.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      repo.owner.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _proceedToDashboard() {
    final projectSelectionService = Provider.of<ProjectSelectionService>(context, listen: false);
    
    // Only mark setup as complete if user has selected at least one project
    if (projectSelectionService.selectedProjectCount > 0) {
      projectSelectionService.markSetupComplete();
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  void _saveAndReturn() {
    final projectSelectionService = Provider.of<ProjectSelectionService>(context, listen: false);
    
    // If user has selected projects and setup wasn't complete, mark it as complete
    if (projectSelectionService.selectedProjectCount > 0 && !projectSelectionService.hasCompletedSetup) {
      projectSelectionService.markSetupComplete();
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final projectSelectionService = Provider.of<ProjectSelectionService>(context);
    final selectedCount = projectSelectionService.selectedProjectCount;
    final totalCount = _repositories.length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetupMode ? 'Select Projects to Monitor' : 'Manage Projects'),
        automaticallyImplyLeading: !widget.isSetupMode,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isSetupMode ? 'Welcome to crypticdash!' : 'Manage Your Projects',
                    style: AppThemes.headlineMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isSetupMode 
                        ? 'Select which GitHub repositories you want to monitor and track progress.'
                        : 'Select or deselect repositories to monitor in your dashboard.',
                    style: AppThemes.bodyLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selected: $selectedCount of $totalCount',
                    style: AppThemes.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search repositories...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        projectSelectionService.selectAllProjects(_filteredRepositories);
                      },
                      icon: const Icon(Icons.select_all),
                      label: const Text('Select All'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        projectSelectionService.deselectAllProjects();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Repository List
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _filteredRepositories.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No repositories found',
                                style: AppThemes.titleMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filteredRepositories.length,
                        itemBuilder: (context, index) {
                          final repo = _filteredRepositories[index];
                          final isSelected = projectSelectionService.isProjectSelected(repo.id);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                projectSelectionService.toggleProjectSelection(repo.id);
                              },
                              title: Text(
                                repo.name,
                                style: AppThemes.titleMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (repo.description.isNotEmpty) ...[
                                    Text(
                                      repo.description,
                                      style: AppThemes.bodyMedium.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_circle,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        repo.owner,
                                        style: AppThemes.bodyMedium.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      if (repo.language.isNotEmpty) ...[
                                        Icon(
                                          Icons.code,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          repo.language,
                                          style: AppThemes.bodyMedium.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              secondary: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (repo.isPrivate)
                                    Icon(
                                      Icons.lock,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  if (repo.isFork)
                                    Icon(
                                      Icons.call_split,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

            const SizedBox(height: 24),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Selected: $selectedCount repositories',
                      style: AppThemes.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (widget.isSetupMode)
                    ElevatedButton(
                      onPressed: selectedCount > 0 ? _proceedToDashboard : null,
                      style: AppThemes.primaryButtonStyle,
                      child: const Text('Continue to Dashboard'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _saveAndReturn,
                      style: AppThemes.primaryButtonStyle,
                      child: const Text('Save Changes'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
