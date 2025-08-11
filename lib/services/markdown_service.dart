import '../models/project.dart';

class MarkdownService {
  static const String _projectFileName = 'PROJECT.md';
  
  static String getProjectFileName() => _projectFileName;

  static String generateProjectMarkdown(Project project) {
    final buffer = StringBuffer();
    
    // Project header
    buffer.writeln('# ${project.name}');
    buffer.writeln();
    
    // Overview
    if (project.description.isNotEmpty) {
      buffer.writeln('## Overview');
      buffer.writeln(project.description);
      buffer.writeln();
    }
    
    // Progress
    buffer.writeln('## Progress: ${project.progress.toStringAsFixed(0)}% Complete');
    buffer.writeln();
    
    // Todo list
    buffer.writeln('## Todo List');
    for (final todo in project.todos) {
      final checkbox = todo.isCompleted ? '[x]' : '[ ]';
      buffer.writeln('- $checkbox ${todo.title}');
      if (todo.notes != null && todo.notes!.isNotEmpty) {
        buffer.writeln('  - ${todo.notes}');
      }
    }
    buffer.writeln();
    
    // Notes
    if (project.notes.isNotEmpty) {
      buffer.writeln('## Notes');
      buffer.writeln(project.notes);
      buffer.writeln();
    }
    
    // Metadata
    buffer.writeln('---');
    buffer.writeln('Last updated: ${project.lastUpdated.toIso8601String()}');
    buffer.writeln('Total todos: ${project.totalTodos}');
    buffer.writeln('Completed: ${project.completedTodos}');
    buffer.writeln('Pending: ${project.pendingTodos}');
    
    return buffer.toString();
  }

  static Project? parseProjectMarkdown(String markdown, String repoName, String owner) {
    try {
      final lines = markdown.split('\n');
      String projectName = repoName;
      String description = '';
      List<Todo> todos = [];
      String notes = '';
      
      int currentSection = -1; // -1: none, 0: overview, 1: progress, 2: todos, 3: notes
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        if (line.isEmpty) continue;
        
        // Check for headers
        if (line.startsWith('# ')) {
          projectName = line.substring(2).trim();
        } else if (line.startsWith('## Overview')) {
          currentSection = 0;
        } else if (line.startsWith('## Progress:')) {
          currentSection = 1;
        } else if (line.startsWith('## Todo List')) {
          currentSection = 2;
        } else if (line.startsWith('## Notes')) {
          currentSection = 3;
        } else if (line.startsWith('---')) {
          break; // End of content, metadata follows
        } else {
          // Process content based on current section
          switch (currentSection) {
            case 0: // Overview
              if (line.isNotEmpty) {
                description += line + '\n';
              }
              break;
            case 2: // Todo List
              if (line.startsWith('- [ ] ') || line.startsWith('- [x] ')) {
                final isCompleted = line.startsWith('- [x] ');
                final title = line.substring(6).trim();
                final todo = Todo(
                  id: _generateTodoId(title),
                  title: title,
                  isCompleted: isCompleted,
                  createdAt: DateTime.now(),
                  completedAt: isCompleted ? DateTime.now() : null,
                );
                todos.add(todo);
              }
              break;
            case 3: // Notes
              if (line.isNotEmpty) {
                notes += line + '\n';
              }
              break;
          }
        }
      }
      
      // Clean up trailing newlines
      description = description.trim();
      notes = notes.trim();
      
      return Project(
        id: _generateProjectId(owner, repoName),
        name: projectName,
        description: description,
        repositoryUrl: 'https://github.com/$owner/$repoName',
        owner: owner,
        repoName: repoName,
        todos: todos,
        notes: notes,
        lastUpdated: DateTime.now(),
        isConnected: true,
      );
    } catch (e) {
      return null;
    }
  }

  static String _generateProjectId(String owner, String repoName) {
    return '${owner}_$repoName';
  }

  static String _generateTodoId(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  static List<String> getProjectTemplates() {
    return [
      'Web App',
      'Mobile App',
      'API',
      'Library',
      'CLI Tool',
      'Custom',
    ];
  }

  static String getTemplateContent(String templateName) {
    switch (templateName) {
      case 'Web App':
        return '''# ${templateName}
## Overview
A web application project

## Progress: 0% Complete

## Todo List
- [ ] Project setup and planning
- [ ] Design system and UI components
- [ ] Frontend development
- [ ] Backend API development
- [ ] Database design and setup
- [ ] Testing and quality assurance
- [ ] Deployment and CI/CD setup
- [ ] Documentation
- [ ] Performance optimization
- [ ] Security audit

## Notes
Project started on ${DateTime.now().toIso8601String()}
''';
      
      case 'Mobile App':
        return '''# ${templateName}
## Overview
A mobile application project

## Progress: 0% Complete

## Todo List
- [ ] Project setup and planning
- [ ] UI/UX design and wireframes
- [ ] Core functionality development
- [ ] Platform-specific features
- [ ] Testing on devices
- [ ] App store preparation
- [ ] Beta testing
- [ ] Final polish and optimization
- [ ] App store submission
- [ ] Post-launch monitoring

## Notes
Project started on ${DateTime.now().toIso8601String()}
''';
      
      case 'API':
        return '''# ${templateName}
## Overview
An API service project

## Progress: 0% Complete

## Todo List
- [ ] Project setup and planning
- [ ] API design and specification
- [ ] Database schema design
- [ ] Core API endpoints
- [ ] Authentication and authorization
- [ ] Input validation and error handling
- [ ] Testing and documentation
- [ ] Performance optimization
- [ ] Security hardening
- [ ] Deployment setup
- [ ] Monitoring and logging

## Notes
Project started on ${DateTime.now().toIso8601String()}
''';
      
      default:
        return '''# ${templateName}
## Overview
Custom project template

## Progress: 0% Complete

## Todo List
- [ ] Project planning
- [ ] Development
- [ ] Testing
- [ ] Deployment

## Notes
Project started on ${DateTime.now().toIso8601String()}
''';
    }
  }

  // New methods for TODO.md files
  static String generateInitialTodoContent(String projectName) {
    return '''# ${projectName} - Development Tasks

## Progress: 0% Complete

## Todo List
- [ ] Project setup and planning
- [ ] Core functionality development
- [ ] Testing and quality assurance
- [ ] Documentation
- [ ] Deployment preparation

## Notes
Project started on ${DateTime.now().toIso8601String()}
''';
  }

  static String generateTodoContent(List<Todo> todos) {
    final buffer = StringBuffer();
    
    buffer.writeln('# Development Tasks');
    buffer.writeln();
    
    // Progress
    final completed = todos.where((todo) => todo.isCompleted).length;
    final total = todos.length;
    final progress = total > 0 ? (completed / total * 100) : 0.0;
    buffer.writeln('## Progress: ${progress.toStringAsFixed(0)}% Complete');
    buffer.writeln();
    
    // Todo list
    buffer.writeln('## Todo List');
    for (final todo in todos) {
      final checkbox = todo.isCompleted ? '[x]' : '[ ]';
      buffer.writeln('- $checkbox ${todo.title}');
      if (todo.notes != null && todo.notes!.isNotEmpty) {
        buffer.writeln('  - ${todo.notes}');
      }
    }
    buffer.writeln();
    
    // Metadata
    buffer.writeln('---');
    buffer.writeln('Last updated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total todos: $total');
    buffer.writeln('Completed: $completed');
    buffer.writeln('Pending: ${total - completed}');
    
    return buffer.toString();
  }

  static List<Todo> parseTodosFromMarkdown(String markdown) {
    final todos = <Todo>[];
    final lines = markdown.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('- [ ] ') || trimmedLine.startsWith('- [x] ')) {
        final isCompleted = trimmedLine.startsWith('- [x] ');
        final title = trimmedLine.substring(6).trim();
        final todo = Todo(
          id: _generateTodoId(title),
          title: title,
          isCompleted: isCompleted,
          createdAt: DateTime.now(),
          completedAt: isCompleted ? DateTime.now() : null,
        );
        todos.add(todo);
      }
    }
    
    return todos;
  }
}
