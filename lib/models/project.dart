class Project {
  final String id;
  final String name;
  final String description;
  final String repositoryUrl;
  final String owner;
  final String repoName;
  final List<Todo> todos;
  final String notes;
  DateTime lastUpdated;
  bool isConnected;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.repositoryUrl,
    required this.owner,
    required this.repoName,
    required this.todos,
    this.notes = '',
    required this.lastUpdated,
    this.isConnected = false,
  });

  double get progress {
    if (todos.isEmpty) return 0.0;
    final completed = todos.where((todo) => todo.isCompleted).length;
    return (completed / todos.length) * 100;
  }

  int get completedTodos => todos.where((todo) => todo.isCompleted).length;
  int get totalTodos => todos.length;
  int get pendingTodos => todos.where((todo) => !todo.isCompleted).length;

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? repositoryUrl,
    String? owner,
    String? repoName,
    List<Todo>? todos,
    String? notes,
    DateTime? lastUpdated,
    bool? isConnected,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      owner: owner ?? this.owner,
      repoName: repoName ?? this.repoName,
      todos: todos ?? this.todos,
      notes: notes ?? this.notes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'repositoryUrl': repositoryUrl,
      'owner': owner,
      'repoName': repoName,
      'todos': todos.map((todo) => todo.toJson()).toList(),
      'notes': notes,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isConnected': isConnected,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      repositoryUrl: json['repositoryUrl'],
      owner: json['owner'],
      repoName: json['repoName'],
      todos: (json['todos'] as List).map((todo) => Todo.fromJson(todo)).toList(),
      notes: json['notes'] ?? '',
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isConnected: json['isConnected'] ?? false,
    );
  }
}

class Todo {
  final String id;
  final String title;
  bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? notes;

  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.notes,
  });

  Todo copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    String? notes,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      notes: json['notes'],
    );
  }
}
