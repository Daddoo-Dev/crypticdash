class GitHubRepository {
  final int id;
  final String name;
  final String fullName;
  final String description;
  final String htmlUrl;
  final String cloneUrl;
  final String sshUrl;
  final bool isPrivate;
  final bool isFork;
  final String language;
  final int stargazersCount;
  final int watchersCount;
  final int forksCount;
  final int openIssuesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? pushedAt;
  final String defaultBranch;
  final Map<String, dynamic> permissions;

  GitHubRepository({
    required this.id,
    required this.name,
    required this.fullName,
    required this.description,
    required this.htmlUrl,
    required this.cloneUrl,
    required this.sshUrl,
    required this.isPrivate,
    required this.isFork,
    required this.language,
    required this.stargazersCount,
    required this.watchersCount,
    required this.forksCount,
    required this.openIssuesCount,
    required this.createdAt,
    required this.updatedAt,
    this.pushedAt,
    required this.defaultBranch,
    required this.permissions,
  });

  bool get canWrite => permissions['push'] == true;
  bool get canRead => permissions['pull'] == true;
  bool get canAdmin => permissions['admin'] == true;

  String get owner => fullName.split('/').first;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fullName': fullName,
      'description': description,
      'htmlUrl': htmlUrl,
      'cloneUrl': cloneUrl,
      'sshUrl': sshUrl,
      'isPrivate': isPrivate,
      'isFork': isFork,
      'language': language,
      'stargazersCount': stargazersCount,
      'watchersCount': watchersCount,
      'forksCount': forksCount,
      'openIssuesCount': openIssuesCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pushedAt': pushedAt?.toIso8601String(),
      'defaultBranch': defaultBranch,
      'permissions': permissions,
    };
  }

  factory GitHubRepository.fromJson(Map<String, dynamic> json) {
    return GitHubRepository(
      id: json['id'],
      name: json['name'],
      fullName: json['full_name'],
      description: json['description'] ?? '',
      htmlUrl: json['html_url'],
      cloneUrl: json['clone_url'],
      sshUrl: json['ssh_url'],
      isPrivate: json['private'] ?? false,
      isFork: json['fork'] ?? false,
      language: json['language'] ?? '',
      stargazersCount: json['stargazers_count'] ?? 0,
      watchersCount: json['watchers_count'] ?? 0,
      forksCount: json['forks_count'] ?? 0,
      openIssuesCount: json['open_issues_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      pushedAt: json['pushed_at'] != null ? DateTime.parse(json['pushed_at']) : null,
      defaultBranch: json['default_branch'] ?? 'main',
      permissions: json['permissions'] ?? {},
    );
  }
}
