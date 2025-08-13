import 'package:flutter/widgets.dart';
import '../models/project.dart';
import '../models/github_repository.dart';
import '../services/github_service.dart';
import '../services/markdown_service.dart';
import '../services/project_selection_service.dart';

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
    });
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

  Future<Project?> _loadProjectFromRepo(GitHubRepository repo) async {
    try {
      final todoContent = await _fetchTodoFromGitHub(repo);
      
      if (todoContent != null) {
        final project = _parseProjectContent(repo, todoContent);
        return project;
      } else {
        return Project(
          id: repo.fullName,
          name: repo.name,
          owner: repo.owner,
          description: repo.description,
          repositoryUrl: repo.htmlUrl,
          repoName: repo.name,
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
      // Try to fetch {reponame}-todo.md from the repository first
      final todoFileName = '${repo.name}-todo.md';
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
      
      debugPrint('No TODO files found on GitHub for ${repo.name}');
      return null;
    } catch (e) {
      debugPrint('Error fetching TODO from GitHub for ${repo.name}: $e');
      return null;
    }
  }

  Project _parseProjectContent(GitHubRepository repo, String content) {
    // Try enhanced parsing first (our new format)
    final enhancedProject = MarkdownService.parseEnhancedTodoMarkdown(content, repo.name, repo.owner);
    if (enhancedProject != null) {
      debugPrint('Successfully parsed enhanced TODO format for ${repo.name}');
      return enhancedProject;
    }

    // Fallback to standard parsing
    final todos = MarkdownService.parseTodosFromMarkdown(content);
    debugPrint('Falling back to standard TODO parsing for ${repo.name}');

    return Project(
      id: repo.fullName,
      name: repo.name,
      owner: repo.owner,
      description: repo.description,
      repositoryUrl: repo.htmlUrl,
      repoName: repo.name,
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
      debugPrint('Error updating todo status: $e');
      rethrow;
    }
  }

  Future<void> updateTodoFileOnGitHub(String owner, String repo, String content) async {
    try {
      final fileName = '$repo-todo.md';
      const message = 'Update TODO file with proper formatting';
      
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
      debugPrint('Error updating TODO file on GitHub: $e');
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

