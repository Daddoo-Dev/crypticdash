import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';
import '../models/github_repository.dart';
import '../services/github_service.dart';
import '../services/markdown_service.dart';

class ProjectService extends ChangeNotifier {
  final GitHubService _githubService;
  final List<Project> _projects = [];
  final Map<String, String> _projectPaths = {};

  ProjectService(this._githubService);

  List<Project> get projects => List.unmodifiable(_projects);

  Future<void> loadProjects() async {
    try {
      final repos = await _githubService.getUserRepositories();
      _projects.clear();
      _projectPaths.clear();

      for (final repo in repos) {
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

      final todoFile = File('$localPath/TODO.md');
      if (!await todoFile.exists()) {
        // Create initial TODO.md if it doesn't exist
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
      final todoContent = MarkdownService.generateInitialTodoContent(repo.name);
      final todoFile = File('$localPath/TODO.md');
      await todoFile.writeAsString(todoContent);
      
      debugPrint('Created initial TODO.md for ${repo.name}');
    } catch (e) {
      debugPrint('Error creating initial TODO file: $e');
      rethrow;
    }
  }

  Future<Project> _parseProjectFromTodoFile(GitHubRepository repo, String localPath) async {
    try {
      final todoFile = File('$localPath/TODO.md');
      final content = await todoFile.readAsString();
      
      final todos = MarkdownService.parseTodosFromMarkdown(content);

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
    } catch (e) {
      debugPrint('Error parsing project from TODO file: $e');
      rethrow;
    }
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
      final todoFile = File('$localPath/TODO.md');
      await todoFile.writeAsString(todoContent);
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

