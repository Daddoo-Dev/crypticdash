import '../models/project.dart';

class MarkdownService {
  // Support multiple TODO file names
  static const List<String> _projectFileNames = [
    'TODO.md',
    'PROJECT.md',
  ];
  
  // Get the primary project file name
  static String getProjectFileName() => _projectFileNames.first;
  
  // Get all supported project file names
  static List<String> getProjectFileNames() => List.from(_projectFileNames);
  
  // Check if a filename is a valid project file
  static bool isValidProjectFile(String filename) {
    final lowerFilename = filename.toLowerCase();
    return _projectFileNames.any((name) => lowerFilename == name.toLowerCase()) ||
           lowerFilename.endsWith('-todo.md');
  }

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

  // New method to parse our enhanced TODO format
  static Project? parseEnhancedTodoMarkdown(String markdown, String repoName, String owner) {
    try {
      final lines = markdown.split('\n');
      String projectName = repoName;
      String description = '';
      List<Todo> todos = [];
      String notes = '';
      double progress = 0.0;
      String currentPhase = '';
      String nextMilestone = '';
      
      int currentSection = -1;
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        if (line.isEmpty) continue;
        
        // Check for headers
        if (line.startsWith('# ')) {
          projectName = line.substring(2).trim();
        } else if (line.startsWith('## 📋 Project Overview')) {
          currentSection = 0;
        } else if (line.startsWith('## 🎯 Project Goals')) {
          currentSection = 1;
        } else if (line.startsWith('## 🚀 Development Phases')) {
          currentSection = 2;
        } else if (line.startsWith('## 📊 Progress Tracking')) {
          currentSection = 3;
        } else if (line.startsWith('## 📝 Notes & Updates')) {
          currentSection = 4;
        } else if (line.startsWith('---')) {
          break;
        } else {
          // Process content based on current section
          switch (currentSection) {
            case 0: // Project Overview
              if (line.startsWith('**Repository**:') || 
                  line.startsWith('**Owner**:') || 
                  line.startsWith('**Language**:') ||
                  line.startsWith('**Status**:')) {
                // Skip metadata lines
              } else if (line.isNotEmpty && !line.startsWith('**')) {
                description += line + '\n';
              }
              break;
            case 1: // Project Goals
              if (line.startsWith('- [x] ')) {
                // Completed goal - could be converted to a todo
                final title = line.substring(6).trim();
                final todo = Todo(
                  id: _generateTodoId(title),
                  title: title,
                  isCompleted: true,
                  createdAt: DateTime.now(),
                  completedAt: DateTime.now(),
                );
                todos.add(todo);
              } else if (line.startsWith('- [ ] ')) {
                // Pending goal
                final title = line.substring(6).trim();
                final todo = Todo(
                  id: _generateTodoId(title),
                  title: title,
                  isCompleted: false,
                  createdAt: DateTime.now(),
                  completedAt: null,
                );
                todos.add(todo);
              }
              break;
            case 2: // Development Phases
              if (line.startsWith('### Phase') && line.contains('✅ COMPLETED')) {
                // Extract phase name
                final phaseMatch = RegExp(r'### Phase \d+: (.+?) ✅').firstMatch(line);
                if (phaseMatch != null) {
                  currentPhase = phaseMatch.group(1) ?? '';
                }
              } else if (line.startsWith('### Phase') && line.contains('🚧 IN PROGRESS')) {
                // Extract phase name
                final phaseMatch = RegExp(r'### Phase \d+: (.+?) 🚧').firstMatch(line);
                if (phaseMatch != null) {
                  currentPhase = phaseMatch.group(1) ?? '';
                }
              } else if (line.startsWith('- [x] ')) {
                // Completed phase task
                final title = line.substring(6).trim();
                final todo = Todo(
                  id: _generateTodoId(title),
                  title: title,
                  isCompleted: true,
                  createdAt: DateTime.now(),
                  completedAt: DateTime.now(),
                );
                todos.add(todo);
              } else if (line.startsWith('- [ ] ')) {
                // Pending phase task
                final title = line.substring(6).trim();
                final todo = Todo(
                  id: _generateTodoId(title),
                  title: title,
                  isCompleted: false,
                  createdAt: DateTime.now(),
                  completedAt: null,
                );
                todos.add(todo);
              }
              break;
            case 3: // Progress Tracking
              if (line.contains('Overall Progress')) {
                final progressMatch = RegExp(r'(\d+)% Complete').firstMatch(line);
                if (progressMatch != null) {
                  progress = double.tryParse(progressMatch.group(1) ?? '0') ?? 0.0;
                }
              } else if (line.contains('Current Phase')) {
                final phaseMatch = RegExp(r'Current Phase.*?Phase \d+ - (.+?)$').firstMatch(line);
                if (phaseMatch != null) {
                  currentPhase = phaseMatch.group(1) ?? '';
                }
              } else if (line.contains('Next Milestone')) {
                final milestoneMatch = RegExp(r'Next Milestone.*?([^.]+)').firstMatch(line);
                if (milestoneMatch != null) {
                  nextMilestone = milestoneMatch.group(1)?.trim() ?? '';
                }
              }
              break;
            case 4: // Notes & Updates
              if (line.startsWith('### ')) {
                // Date header
                notes += '\n${line}\n';
              } else if (line.startsWith('- ') && line.isNotEmpty) {
                notes += line + '\n';
              }
              break;
          }
        }
      }
      
      // Clean up trailing newlines
      description = description.trim();
      notes = notes.trim();
      
      // Create enhanced project with additional metadata
      final project = Project(
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
      
      // Store additional metadata in notes if available
      if (currentPhase.isNotEmpty || nextMilestone.isNotEmpty) {
        final enhancedNotes = <String>[];
        if (notes.isNotEmpty) enhancedNotes.add(notes);
        if (currentPhase.isNotEmpty) enhancedNotes.add('Current Phase: $currentPhase');
        if (nextMilestone.isNotEmpty) enhancedNotes.add('Next Milestone: $nextMilestone');
        if (progress > 0) enhancedNotes.add('Overall Progress: ${progress.toStringAsFixed(0)}%');
        
        // Update the project with enhanced notes
        return project.copyWith(notes: enhancedNotes.join('\n\n'));
      }
      
      return project;
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
