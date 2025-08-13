import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../theme/app_themes.dart';
import '../widgets/project_tile.dart';
import '../widgets/add_project_dialog.dart';
import '../services/theme_service.dart';
import '../screens/project_selection_screen.dart';
import '../services/github_service.dart'; // Added import for GitHubService
import '../screens/auth_screen.dart'; // Added import for AuthScreen
import '../services/project_selection_service.dart'; // Added import for ProjectSelectionService
import '../screens/project_detail_screen.dart'; // Added import for ProjectDetailScreen

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
    // Use a post-frame callback to avoid BuildContext issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjects();
    });
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.loadProjects();
    } catch (e) {
      if (mounted) {
        // Only show error message if widget is still mounted
        setState(() {
          _isLoading = false;
        });
        // Use a delayed callback to ensure context is fully available
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load projects: $e'),
                backgroundColor: AppThemes.errorRed,
              ),
            );
          }
        });
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

    // Apply connection filter
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

  SliverGridDelegate _getGridDelegate(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate optimal card width based on screen size
    double maxCardWidth;
    double aspectRatio;
    
    if (screenWidth < 600) {
      // Small screens: single column
      maxCardWidth = screenWidth - 32; // Full width minus padding
      aspectRatio = 0.9;
    } else if (screenWidth < 900) {
      // Medium screens: 2 columns
      maxCardWidth = (screenWidth - 48) / 2; // Account for spacing
      aspectRatio = 0.85;
    } else if (screenWidth < 1200) {
      // Large screens: 3 columns
      maxCardWidth = (screenWidth - 64) / 3;
      aspectRatio = 0.8;
    } else {
      // Extra large screens: 4+ columns
      maxCardWidth = (screenWidth - 80) / 4;
      aspectRatio = 0.75;
    }
    
    // Ensure minimum and maximum card sizes
    maxCardWidth = maxCardWidth.clamp(280.0, 500.0);
    
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCardWidth,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    );
  }

  void _toggleTheme() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    themeService.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDarkMode = themeService.isDarkMode;
        
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(
                  themeService.getLogoAsset(),
                  height: 32,
                  width: 32,
                ),
                const SizedBox(width: 12),
                Text(themeService.getAppName()),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadProjects,
                tooltip: 'Refresh Projects',
              ),
              IconButton(
                icon: const Icon(Icons.manage_accounts),
                onPressed: () => _showProjectManagement(context),
                tooltip: 'Manage Projects',
              ),
              IconButton(
                icon: Icon(themeService.getThemeIcon()),
                onPressed: _toggleTheme,
                tooltip: 'Switch Theme (${themeService.getThemeModeName()})',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context),
                tooltip: 'Logout',
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
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _showProjectManagement(context),
                              icon: const Icon(Icons.manage_accounts),
                              label: const Text('Manage Projects'),
                              style: AppThemes.secondaryButtonStyle,
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _loadProjects,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: _getGridDelegate(context),
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
      },
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddProjectDialog(),
    );
  }

  void _openProjectDetails(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }

  void _showProjectManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Project Management',
              style: AppThemes.headlineSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Repository Selection'),
              subtitle: const Text('Select or deselect repositories to monitor'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProjectSelectionScreen(isSetupMode: false)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset Setup'),
              subtitle: const Text('Start over with repository selection'),
              onTap: () {
                Navigator.of(context).pop();
                _showResetSetupDialog(context);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Setup'),
        content: const Text(
          'This will clear your current repository selection and take you back to the initial setup. '
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetSetup();
            },
            style: AppThemes.primaryButtonStyle,
            child: const Text('Reset Setup'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSetup() async {
    try {
      final projectSelectionService = Provider.of<ProjectSelectionService>(context, listen: false);
      await projectSelectionService.resetSetup();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProjectSelectionScreen(isSetupMode: true)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset setup: $e'),
            backgroundColor: AppThemes.errorRed,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout? This will clear your GitHub authentication.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _logout();
            },
            style: AppThemes.primaryButtonStyle,
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final githubService = Provider.of<GitHubService>(context, listen: false);
      await githubService.clearAccessToken();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: AppThemes.errorRed,
          ),
        );
      }
    }
  }
}
