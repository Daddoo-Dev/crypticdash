import 'package:flutter/widgets.dart';
import '../models/project.dart';
import '../models/github_repository.dart';
import '../services/github_service.dart';
import '../services/markdown_service.dart';
import '../services/project_selection_service.dart';
import '../services/user_identity_service.dart';

class ProjectService extends ChangeNotifier {
  final GitHubService _githubService;
  final ProjectSelectionService _projectSelectionService;
  final List<Project> _projects = [];

  ProjectService(this._githubService, this._projectSelectionService) {
    // Set up callback to refresh projects when selection changes
    // Use a post-frame callback to ensure the service is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _projectSelectionService.setOnSelectionChangedCallback(() {
        loadProjects();
      });
      
      // Initialize Gist service for cross-device sync
      _initializeGistService();
    });
  }
  
  /// Initialize Gist service for cross-device sync
  Future<void> _initializeGistService() async {
    try {
      // Get the GitHub token and username
      final token = _githubService.accessToken;
      final username = await UserIdentityService.getUsername();
      
      if (token != null && username != null) {
        await _projectSelectionService.initializeGistService(token, username);
        debugPrint('Gist service initialized successfully');
      } else {
        debugPrint('Cannot initialize Gist service: missing token or username');
      }
    } catch (e) {
      debugPrint('Error initializing Gist service: $e');
    }
  }

  List<Project> get projects => List.unmodifiable(_projects);

  Future<void> loadProjects() async {
    try {
      final allRepos = await _githubService.getUserRepositories();
      
      // Filter to only selected repositories if ProjectSelectionService is available
      List<GitHubRepository> selectedRepos;
      selectedRepos = _projectSelectionService.getFilteredRepositories(allRepos);
      
      _projects.clear();

      for (final repo in selectedRepos) {
        final project = await _loadProjectFromRepo(repo);
        if (project != null) {
          _projects.add(project);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading projects: $e');
      rethrow;
    }
  }

  /// Refresh a specific project by reloading it from GitHub
  Future<void> refreshProject(Project project) async {
    try {
      // Find the project in the list
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        // Fetch the updated TODO content directly
        final todoContent = await _fetchTodoFromGitHubDirect(project.owner, project.repoName);
        
        if (todoContent != null) {
          // Parse the updated content and update the project
          final updatedProject = _parseProjectContentFromContent(
            project, 
            todoContent, 
            project.owner
          );
          if (updatedProject != null) {
            _projects[index] = updatedProject;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error refreshing project ${project.name}: $e');
    }
  }

  /// Fetch TODO content directly without creating a full GitHubRepository object
  Future<String?> _fetchTodoFromGitHubDirect(String owner, String repoName) async {
    try {
      // Try to fetch {reponame}-TODO.md from the repository first (correct format)
      final todoFileName = '$repoName-TODO.md';
      final todoContent = await _githubService.getFileContent(owner, repoName, todoFileName);
      if (todoContent != null) {
        debugPrint('Found $todoFileName on GitHub for $repoName');
        return todoContent;
      }
      
      // Try alternative names
      final alternativeNames = ['TODO.md', 'PROJECT.md', 'README.md'];
      for (final fileName in alternativeNames) {
        final content = await _githubService.getFileContent(owner, repoName, fileName);
        if (content != null) {
          debugPrint('Found $fileName on GitHub for $repoName');
          return content;
        }
      }
      
      debugPrint('No TODO file found for $repoName');
      return null;
    } catch (e) {
      debugPrint('Error fetching TODO from GitHub for $repoName: $e');
      return null;
    }
  }

  /// Parse project content from TODO content string
  Project? _parseProjectContentFromContent(Project existingProject, String todoContent, String owner) {
    try {
      final enhancedProject = MarkdownService.parseEnhancedTodoMarkdown(todoContent, owner, existingProject.repoName);
      if (enhancedProject != null) {
        return enhancedProject.copyWith(
          lastUpdated: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing project content: $e');
      return null;
    }
  }

  Future<Project?> _loadProjectFromRepo(GitHubRepository repo) async {
    try {
      debugPrint('=== Loading Project Debug ===');
      debugPrint('Repo: ${repo.name}');
      debugPrint('Full Name: ${repo.fullName}');
      debugPrint('Owner (computed): ${repo.owner}');
      debugPrint('HTML URL: ${repo.htmlUrl}');
      
      // Get the authenticated user's identity
      final authenticatedUsername = await UserIdentityService.getUsername();
      debugPrint('Authenticated Username: $authenticatedUsername');
      debugPrint('=== End Debug ===');
      
      final todoContent = await _fetchTodoFromGitHub(repo);
      
      if (todoContent != null) {
        final project = _parseProjectContent(repo, todoContent, authenticatedUsername);
        return project;
      } else {
        return Project(
          id: repo.fullName,
          name: repo.name,
          owner: authenticatedUsername ?? repo.owner, // Use authenticated user as owner
          description: repo.description,
          repositoryUrl: repo.htmlUrl,
          repoName: repo.name, // Use actual repository name, not username
          todos: [],
          notes: '',
          lastUpdated: DateTime.now(),
          isConnected: true,
        );
      }
    } catch (e) {
      debugPrint('Error loading project ${repo.name}: $e');
      return null;
    }
  }

  Future<String?> _fetchTodoFromGitHub(GitHubRepository repo) async {
    try {
      // Try to fetch {reponame}-TODO.md from the repository first (correct format)
      final todoFileName = '${repo.name}-TODO.md';
      final todoContent = await _githubService.getFileContent(repo.owner, repo.name, todoFileName);
      if (todoContent != null) {
        debugPrint('Found $todoFileName on GitHub for ${repo.name}');
        return todoContent;
      }
      
      // Try alternative names
      final alternativeNames = ['TODO.md', 'PROJECT.md', 'README.md'];
      for (final fileName in alternativeNames) {
        final content = await _githubService.getFileContent(repo.owner, repo.name, fileName);
        if (content != null) {
          debugPrint('Found $fileName on GitHub for ${repo.name}');
          return content;
        }
      }
      
      debugPrint('No to-do files found on GitHub for ${repo.name}');
      return null;
    } catch (e) {
      debugPrint('Error fetching to-do from GitHub for ${repo.name}: $e');
      return null;
    }
  }

  Project _parseProjectContent(GitHubRepository repo, String content, String? authenticatedUsername) {
    // Use authenticated username as owner, repository name as repoName
    final owner = authenticatedUsername ?? repo.owner;
    final repoName = repo.name; // This should be the actual repository name (e.g., "crypticdash")
    
    debugPrint('Creating project with:');
    debugPrint('  Owner: $owner (authenticated user)');
    debugPrint('  Repo Name: $repoName (repository name)');
    debugPrint('  Full Name: ${repo.fullName}');
    
    // Try enhanced parsing first (our new format)
    final enhancedProject = MarkdownService.parseEnhancedTodoMarkdown(content, owner, repoName);
    if (enhancedProject != null) {
      debugPrint('Successfully parsed enhanced to-do format for ${repo.name}');
      return enhancedProject;
    }

    // Fallback to standard parsing
    final todos = MarkdownService.parseTodosFromMarkdown(content);
    debugPrint('Falling back to standard to-do parsing for ${repo.name}');

    return Project(
      id: repo.fullName,
      name: repo.name,
      owner: owner,
      description: repo.description,
      repositoryUrl: repo.htmlUrl,
      repoName: repoName,
      todos: todos,
      notes: '',
      lastUpdated: DateTime.now(),
      isConnected: true,
    );
  }

  Future<void> updateTodoStatus(String projectId, String todoId, bool isCompleted) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      final todo = project.todos.firstWhere((t) => t.id == todoId);
      todo.isCompleted = isCompleted;

      // Update project stats
      project.lastUpdated = DateTime.now();

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating to-do status: $e');
      rethrow;
    }
  }

  Future<void> updateTodoFileOnGitHub(String owner, String repo, String content) async {
    try {
              final fileName = '$repo-TODO.md';
      const message = 'Update to-do file with proper formatting';
      
      // Get current file SHA if it exists
      String? sha;
      try {
        sha = await _githubService.getFileSha(owner, repo, fileName);
      } catch (e) {
        // File doesn't exist, will create new one
      }
      
      final success = await _githubService.createOrUpdateFile(
        owner, 
        repo, 
        fileName, 
        content, 
        message,
        sha: sha,
      );
      
      if (success) {
        debugPrint('Successfully updated $fileName on GitHub');
      } else {
        debugPrint('Failed to update $fileName on GitHub');
      }
    } catch (e) {
      debugPrint('Error updating to-do file on GitHub: $e');
    }
  }

  List<Project> searchProjects(String query) {
    if (query.isEmpty) return _projects;
    
    return _projects.where((project) {
      return project.name.toLowerCase().contains(query.toLowerCase()) ||
             project.description.toLowerCase().contains(query.toLowerCase()) ||
             project.owner.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<void> addProject(GitHubRepository repo) async {
    try {
      final project = await _loadProjectFromRepo(repo);
      if (project != null) {
        _projects.add(project);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding project: $e');
      rethrow;
    }
  }

  Future<void> removeProject(String projectId) async {
    try {
      _projects.removeWhere((p) => p.id == projectId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing project: $e');
      rethrow;
    }
  }
}

