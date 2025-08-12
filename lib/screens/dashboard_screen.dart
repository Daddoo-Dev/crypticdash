import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../theme/app_themes.dart';
import '../widgets/project_tile.dart';
import '../widgets/add_project_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, connected, disconnected

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.loadProjects();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load projects: $e'),
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

  List<Project> _getFilteredProjects() {
    final projectService = Provider.of<ProjectService>(context, listen: false);
    List<Project> projects = projectService.projects;

    // Apply status filter
    if (_filterStatus == 'connected') {
      projects = projects.where((p) => p.isConnected).toList();
    } else if (_filterStatus == 'disconnected') {
      projects = projects.where((p) => !p.isConnected).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      projects = projectService.searchProjects(_searchQuery);
    }

    return projects;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/devdash.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 12),
            const Text('CrypticDash'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
            tooltip: 'Refresh Projects',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings screen
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
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
                const SizedBox(height: 16),

                // Filter Chips
                Row(
                  children: [
                    Text(
                      'Filter: ',
                      style: AppThemes.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterStatus == 'all',
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = 'all';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Connected'),
                      selected: _filterStatus == 'connected',
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = 'connected';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Disconnected'),
                      selected: _filterStatus == 'disconnected',
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = 'disconnected';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Projects Grid
          Expanded(
            child: Consumer<ProjectService>(
              builder: (context, projectService, child) {
                final projects = _getFilteredProjects();

                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: AppThemes.neutralGrey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No projects found matching "$_searchQuery"'
                              : 'No projects found',
                          style: AppThemes.titleMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a project to get started',
                          style: AppThemes.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddProjectDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Project'),
                          style: AppThemes.primaryButtonStyle,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadProjects,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0, // Changed from 1.2 to 1.0 to give more height
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return ProjectTile(
                        project: project,
                        onTap: () => _openProjectDetails(project),
                        onRefresh: () => _loadProjects(),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context),
        backgroundColor: AppThemes.primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddProjectDialog(),
    );
  }

  void _openProjectDetails(Project project) {
    // TODO: Navigate to project detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${project.name}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
