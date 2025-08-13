import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';
import '../models/github_repository.dart';
import '../services/github_service.dart';
import '../services/markdown_service.dart';
import '../services/project_selection_service.dart';

class ProjectService extends ChangeNotifier {
  final GitHubService _githubService;
  final ProjectSelectionService _projectSelectionService;
  final List<Project> _projects = [];
  final Map<String, String> _projectPaths = {};

  ProjectService(this._githubService, this._projectSelectionService) {
    // Set up callback to refresh projects when selection changes
    // Use a post-frame callback to ensure the service is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_projectSelectionService != null) {
        _projectSelectionService.setOnSelectionChangedCallback(() {
          loadProjects();
        });
      }
    });
  }

  List<Project> get projects => List.unmodifiable(_projects);

  Future<void> loadProjects() async {
    try {
      final allRepos = await _githubService.getUserRepositories();
      
      // Filter to only selected repositories if ProjectSelectionService is available
      List<GitHubRepository> selectedRepos;
      if (_projectSelectionService != null) {
        selectedRepos = _projectSelectionService.getFilteredRepositories(allRepos);
      } else {
        // If ProjectSelectionService is not available yet, show all repos
        selectedRepos = allRepos;
      }
      
      _projects.clear();
      _projectPaths.clear();

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
      final localPath = await _getLocalRepoPath(repo);
      if (localPath == null) return null;

      // Look for existing TODO files with different names
      final todoFile = await _findExistingTodoFile(localPath, repo);
      if (todoFile == null) {
        // Create initial TODO.md if no existing file found
        await _createInitialTodoFile(repo, localPath);
      }

      final project = await _parseProjectFromTodoFile(repo, localPath);
      _projectPaths[repo.fullName] = localPath;
      return project;
    } catch (e) {
      debugPrint('Error loading project ${repo.name}: $e');
      return null;
    }
  }

  Future<File?> _findExistingTodoFile(String localPath, GitHubRepository repo) async {
    // Look for files in order of preference
    final possibleNames = [
      '${repo.name.toLowerCase()}-todo.md', // Our new format
      'TODO.md',                           // Standard format
      'PROJECT.md',                        // Legacy format
    ];

    for (final name in possibleNames) {
      final file = File('$localPath/$name');
      if (await file.exists()) {
        debugPrint('Found existing TODO file: $name for ${repo.name}');
        return file;
      }
    }

    return null;
  }

  Future<String?> _getLocalRepoPath(GitHubRepository repo) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final projectsDir = Directory('${appDir.path}/devdash_projects');
      
      if (!await projectsDir.exists()) {
        await projectsDir.create(recursive: true);
      }

      final repoDir = Directory('${projectsDir.path}/${repo.name}');
      if (!await repoDir.exists()) {
        // Create directory structure for now (simplified)
        await repoDir.create(recursive: true);
      }

      return repoDir.path;
    } catch (e) {
      debugPrint('Error getting local repo path: $e');
      return null;
    }
  }

  Future<void> _createInitialTodoFile(GitHubRepository repo, String localPath) async {
    try {
      // Create the TODO file with our new naming convention
      final fileName = '${repo.name.toLowerCase()}-todo.md';
      final todoContent = MarkdownService.generateInitialTodoContent(repo.name);
      final todoFile = File('$localPath/$fileName');
      await todoFile.writeAsString(todoContent);
      
      debugPrint('Created initial $fileName for ${repo.name}');
    } catch (e) {
      debugPrint('Error creating initial TODO file: $e');
      rethrow;
    }
  }

  Future<Project> _parseProjectFromTodoFile(GitHubRepository repo, String localPath) async {
    try {
      // Find the existing TODO file
      final todoFile = await _findExistingTodoFile(localPath, repo);
      if (todoFile == null) {
        // This shouldn't happen since we create files in _loadProjectFromRepo
        // but let's handle it gracefully
        debugPrint('No TODO file found for ${repo.name}, creating one now');
        await _createInitialTodoFile(repo, localPath);
        final newFile = await _findExistingTodoFile(localPath, repo);
        if (newFile == null) {
          throw Exception('Failed to create TODO file for ${repo.name}');
        }
        final content = await newFile.readAsString();
        return _parseProjectContent(repo, content);
      }

      final content = await todoFile.readAsString();
      debugPrint('Parsing TODO file: ${todoFile.path} for ${repo.name}');
      return _parseProjectContent(repo, content);
    } catch (e) {
      debugPrint('Error parsing project from TODO file: $e');
      rethrow;
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
      description: repo.description ?? '',
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

      // Update the local TODO.md file
      final localPath = _projectPaths[projectId];
      if (localPath != null) {
        await _updateTodoFile(project, localPath);
        debugPrint('Updated TODO.md for project: ${project.name}');
      }

      // Update project stats
      project.lastUpdated = DateTime.now();

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating todo status: $e');
      rethrow;
    }
  }

  Future<void> _updateTodoFile(Project project, String localPath) async {
    try {
      final todoContent = MarkdownService.generateTodoContent(project.todos);
      
      // Use the project name to determine the correct filename
      final fileName = '${project.repoName.toLowerCase()}-todo.md';
      final todoFile = File('$localPath/$fileName');
      
      // If the named file doesn't exist, try to find an existing TODO file
      if (!await todoFile.exists()) {
        final existingFile = await _findExistingTodoFile(localPath, 
          GitHubRepository(
            id: 0, // Dummy values for filename lookup
            name: project.repoName,
            fullName: project.id,
            description: project.description,
            htmlUrl: project.repositoryUrl,
            cloneUrl: '',
            sshUrl: '',
            isPrivate: false,
            isFork: false,
            language: '',
            stargazersCount: 0,
            watchersCount: 0,
            forksCount: 0,
            openIssuesCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            defaultBranch: 'main',
            permissions: {},
          )
        );
        
        if (existingFile != null) {
          // Update the existing file
          await existingFile.writeAsString(todoContent);
          debugPrint('Updated existing TODO file: ${existingFile.path}');
          return;
        }
      }
      
      // Update or create the named file
      await todoFile.writeAsString(todoContent);
      debugPrint('Updated TODO file: $fileName');
    } catch (e) {
      debugPrint('Error updating TODO file: $e');
      rethrow;
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
      _projectPaths.remove(projectId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing project: $e');
      rethrow;
    }
  }
}

