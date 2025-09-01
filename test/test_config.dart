import 'package:crypticdash/models/github_repository.dart';
import 'package:crypticdash/models/project.dart';

/// Test configuration and utilities for CrypticDash tests
class TestConfig {
  /// Create a mock GitHub repository for testing
  static GitHubRepository createMockRepository({
    int id = 1,
    String name = 'test-repo',
    String fullName = 'user/test-repo',
    String description = 'Test repository',
    bool isPrivate = false,
    String source = 'personal',
  }) {
    return GitHubRepository(
      id: id,
      name: name,
      fullName: fullName,
      description: description,
      htmlUrl: 'https://github.com/$fullName',
      cloneUrl: 'https://github.com/$fullName.git',
      sshUrl: 'git@github.com:$fullName.git',
      isPrivate: isPrivate,
      isFork: false,
      language: 'Dart',
      stargazersCount: 0,
      watchersCount: 0,
      forksCount: 0,
      openIssuesCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      defaultBranch: 'main',
      permissions: {'push': true, 'pull': true, 'admin': false},
      ownerLogin: 'user',
      source: source,
    );
  }

  /// Create a mock Project for testing
  static Project createMockProject({
    String id = 'test-repo',
    String name = 'test-repo',
    String description = 'Test repository',
    bool isConnected = true,
    List<Todo> todos = const [],
  }) {
    return Project(
      id: id,
      name: name,
      description: description,
      repositoryUrl: 'https://github.com/user/$name',
      owner: 'user',
      repoName: name,
      todos: todos,
      lastUpdated: DateTime.now(),
      isConnected: isConnected,
    );
  }

  /// Create a mock Todo for testing
  static Todo createMockTodo({
    String id = 'todo-1',
    String title = 'Test todo',
    bool isCompleted = false,
    String? section,
  }) {
    return Todo(
      id: id,
      title: title,
      isCompleted: isCompleted,
      createdAt: DateTime.now(),
      section: section,
    );
  }
}
