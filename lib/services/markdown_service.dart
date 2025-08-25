import '../models/project.dart';
import 'package:flutter/foundation.dart';

class MarkdownService {
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
      buffer.writeln('- $checkbox $todo.title');
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
        // Note: We don't override projectName from the file content
        // The project should always display the actual repository name
        if (line.startsWith('## ') && line.contains('Overview')) {
          currentSection = 0;
        } else if (line.startsWith('## ') && line.contains('Progress:')) {
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
                description += '$line\n';
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
                  section: 'General Tasks',
                );
                todos.add(todo);
              }
              break;
            case 3: // Notes
              if (line.isNotEmpty) {
                notes += '$line\n';
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

  static Project? parseEnhancedTodoMarkdown(String markdown, String owner, String repoName) {
    try {
      debugPrint('Starting enhanced parser for $repoName');
      final lines = markdown.split('\n');
      String projectName = repoName;
      String description = '';
      List<Todo> todos = [];
      String notes = '';
      
      String currentSection = '';
      bool inSubSection = false;
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        if (line.isEmpty) continue;
        
        debugPrint('Line $i: "$line" (currentSection: "$currentSection", inSubSection: $inSubSection)');
        
        // Check for headers
        // Note: We don't override projectName from the file content
        // The project should always display the actual repository name
        if (line.startsWith('## ')) {
          // Main section header
          if (line.contains('Overview') || line.contains('📋')) {
            currentSection = 'Project Overview';
          } else if (line.contains('Goals') || line.contains('🎯')) {
            currentSection = 'Project Goals';
          } else if (line.contains('Phases') || line.contains('🚀')) {
            currentSection = 'Development Phases';
          } else if (line.contains('Tasks') || line.contains('🔧')) {
            currentSection = 'Technical Tasks';
          } else if (line.contains('Documentation') || line.contains('📚')) {
            currentSection = 'Documentation';
          } else if (line.contains('Notes') || line.contains('📝')) {
            currentSection = 'Notes & Updates';
          } else if (line.contains('Progress') || line.contains('📊') || line.contains('Current Progress')) {
            currentSection = 'Progress Tracking';
          } else if (line.contains('Next Steps') || line.contains('Next') || line.contains('Steps')) {
            currentSection = 'Next Steps';
          } else if (line.contains('Roadmap') || line.contains('Road') || line.contains('Plan')) {
            currentSection = 'Roadmap';
          } else if (line.contains('Features') || line.contains('Capabilities')) {
            currentSection = 'Features';
          } else if (line.contains('Requirements') || line.contains('Needs')) {
            currentSection = 'Requirements';
          } else {
            // Default section for any other headers
            currentSection = line.substring(3).trim();
          }
          inSubSection = false;
          debugPrint('Main section: $currentSection');
        } else if (line.startsWith('### ')) {
          // Sub-section header
          inSubSection = true;
          debugPrint('Sub-section: $line');
        } else if (line.startsWith('- [x] ') || line.startsWith('- [ ] ') || 
                   line.contains('✅') || line.contains('⚙️') || line.contains('📊') || 
                   line.contains('📚') || line.contains('📝') || line.contains('📦') || 
                   line.contains('🔧') || line.contains('🚀') || line.contains('🧪') || 
                   line.contains('🎯') || line.contains('🔄') || line.contains('🔍')) {
          // Todo item - handle both standard checkboxes and emoji indicators
          bool isCompleted = false;
          String title = '';
          
          if (line.startsWith('- [x] ')) {
            isCompleted = true;
            title = line.substring(6).trim();
          } else if (line.startsWith('- [ ] ')) {
            isCompleted = false;
            title = line.substring(6).trim();
          } else {
            // Handle emoji-based todos
            isCompleted = line.contains('✅'); // Only ✅ indicates completed
            title = line.substring(2).trim(); // Remove the "- " prefix
          }
          
          // Determine section based on current context
          String sectionName = currentSection.isNotEmpty ? currentSection : 'General Tasks';
          
          debugPrint('Creating todo: $title in section: $sectionName (completed: $isCompleted)');
          
          final todo = Todo(
            id: _generateTodoId(title),
            title: title,
            isCompleted: isCompleted,
            createdAt: DateTime.now(),
            completedAt: isCompleted ? DateTime.now() : null,
            section: sectionName,
          );
          todos.add(todo);
        } else if (line.startsWith('---')) {
          // Section separator
          debugPrint('Section separator found');
        }
      }
      
      debugPrint('Enhanced parser completed. Found ${todos.length} todos in sections:');
      final sections = todos.map((t) => t.section).toSet();
      for (final section in sections) {
        final count = todos.where((t) => t.section == section).length;
        debugPrint('  $section: $count todos');
      }
      
      // Create project
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
      
      return todos.isNotEmpty ? project : null;
    } catch (e) {
      debugPrint('Error in enhanced parser: $e');
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
        return '''# $templateName
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
        return '''# $templateName
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
        return '''# $templateName
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
        return '''# $templateName
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

  static String generateInitialTodoContent(String projectName) {
    return '''# $projectName - Development Tasks

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
      buffer.writeln('- $checkbox $todo.title');
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
    debugPrint('Basic parser called');
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
          section: 'General Tasks',
        );
        todos.add(todo);
        debugPrint('Basic parser created todo: $title (General Tasks)');
      }
    }
    
    debugPrint('Basic parser found ${todos.length} todos');
    return todos;
  }

  static String generateFormattedTodoContent(String projectName, List<String> todos) {
    final buffer = StringBuffer();
    
    buffer.writeln('# $projectName');
    buffer.writeln();
    
    buffer.writeln('## 📋 Project Overview');
            buffer.writeln('A development project managed through crypticdash.');
    buffer.writeln();
    
    buffer.writeln('## 🎯 Project Goals');
    for (final todo in todos) {
      buffer.writeln('- [ ] $todo');
    }
    buffer.writeln();
    
    buffer.writeln('## 🚀 Development Phases');
    buffer.writeln('### Phase 1: Planning 📋');
    buffer.writeln('- [ ] Project setup and planning');
    buffer.writeln();
    buffer.writeln('### Phase 2: Development 🚧');
    buffer.writeln('- [ ] Core functionality development');
    buffer.writeln();
    buffer.writeln('### Phase 3: Testing 📋');
    buffer.writeln('- [ ] Testing and quality assurance');
    buffer.writeln();
    buffer.writeln('### Phase 4: Documentation 📋');
    buffer.writeln('- [ ] Documentation');
    buffer.writeln();
    buffer.writeln('### Phase 5: Deployment 📋');
    buffer.writeln('- [ ] Deployment preparation');
    buffer.writeln();
    
    buffer.writeln('## 📊 Progress Tracking');
    buffer.writeln('Overall Progress: 0% Complete');
    buffer.writeln('Current Phase: Phase 1 - Planning');
    buffer.writeln('Next Milestone: Complete project setup');
    buffer.writeln();
    
    buffer.writeln('## 📝 Notes & Updates');
    buffer.writeln('Project started on ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    
    buffer.writeln('---');
    buffer.writeln('Last updated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total todos: ${todos.length}');
    buffer.writeln('Completed: 0');
    buffer.writeln('Pending: ${todos.length}');
    
    return buffer.toString();
  }
  
  // Get section priority for sorting (lower number = higher priority)
  static int getSectionPriority(String? section) {
    if (section == null) return 999; // Unknown sections go last
    
    switch (section) {
      case 'Project Goals':
        return 1;
      case 'Development Phases':
        return 2;
      case 'Technical Tasks':
        return 3;
      case 'Documentation':
        return 4;
      case 'Notes & Updates':
        return 5;
      case 'Progress Tracking':
        return 6;
      case 'General Tasks':
        return 7;
      default:
        return 999; // Unknown sections go last
    }
  }

  static String generateEnhancedProjectMarkdown(Project project) {
    final buffer = StringBuffer();
    
    // Project header
    buffer.writeln('# ${project.name}');
    buffer.writeln();
    
    // Project Overview
    buffer.writeln('## 📋 Project Overview');
    buffer.writeln('**Repository**: https://github.com/yourusername/${project.repoName}');
    buffer.writeln('**Owner**: {{OWNER_NAME}}');
    buffer.writeln('**Language**: Dart/Flutter');
    buffer.writeln('**Last Updated**: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}');
    buffer.writeln('**Status**: Active Development');
    buffer.writeln();
    if (project.description.isNotEmpty) {
      buffer.writeln(project.description);
      buffer.writeln();
    }
    buffer.writeln('---');
    buffer.writeln();
    
    // Group todos by section
    final todosBySection = <String, List<Todo>>{};
    for (final todo in project.todos) {
      final section = todo.section ?? 'General Tasks';
      if (!todosBySection.containsKey(section)) {
        todosBySection[section] = [];
      }
      todosBySection[section]!.add(todo);
    }
    
    // Project Goals
    if (todosBySection.containsKey('Project Goals')) {
      buffer.writeln('## 🎯 Project Goals');
      for (final todo in todosBySection['Project Goals']!) {
        final checkbox = todo.isCompleted ? '[x]' : '[ ]';
        buffer.writeln('- $checkbox ${todo.title}');
      }
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }
    
    // Development Phases
    if (todosBySection.containsKey('Development Phases')) {
      buffer.writeln('## 🚀 Development Phases');
      
      // Group by sub-phases (this is a simplified approach)
      final phaseTodos = todosBySection['Development Phases']!;
      final completedTodos = phaseTodos.where((t) => t.isCompleted).toList();
      final pendingTodos = phaseTodos.where((t) => !t.isCompleted).toList();
      
      if (completedTodos.isNotEmpty) {
        buffer.writeln('### Phase 1: Planning & Setup ✅ COMPLETED');
        for (final todo in completedTodos.take(6)) {
          buffer.writeln('- [x] ${todo.title}');
        }
        buffer.writeln();
      }
      
      if (pendingTodos.isNotEmpty) {
        buffer.writeln('### Phase 5: AI-Powered Project Analysis 🆕 NEW FEATURE');
        for (final todo in pendingTodos.take(9)) {
          buffer.writeln('- [ ] ${todo.title}');
        }
        buffer.writeln();
      }
      
      buffer.writeln('---');
      buffer.writeln();
    }
    
    // Technical Tasks
    if (todosBySection.containsKey('Technical Tasks')) {
      buffer.writeln('## 🔧 Technical Tasks');
      
      final techTodos = todosBySection['Technical Tasks']!;
      final completedTech = techTodos.where((t) => t.isCompleted).toList();
      final pendingTech = techTodos.where((t) => !t.isCompleted).toList();
      
      if (completedTech.isNotEmpty) {
        buffer.writeln('### Infrastructure ✅ COMPLETED');
        for (final todo in completedTech.take(5)) {
          buffer.writeln('- [x] ${todo.title}');
        }
        buffer.writeln();
      }
      
      if (pendingTech.isNotEmpty) {
        buffer.writeln('### Development 🚧 IN PROGRESS');
        for (final todo in pendingTech) {
          buffer.writeln('- [ ] ${todo.title}');
        }
        buffer.writeln();
      }
      
      buffer.writeln('---');
      buffer.writeln();
    }
    
    // Documentation
    if (todosBySection.containsKey('Documentation')) {
      buffer.writeln('## 📚 Documentation');
      for (final todo in todosBySection['Documentation']!) {
        final checkbox = todo.isCompleted ? '[x]' : '[ ]';
        buffer.writeln('- $checkbox ${todo.title}');
      }
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }
    
    // Progress Tracking
    buffer.writeln('## 📊 Progress Tracking');
    buffer.writeln('Overall Progress: ${project.progress.toStringAsFixed(0)}% Complete');
    buffer.writeln('Current Phase: Phase 3 - Core Development');
    buffer.writeln('Next Milestone: Complete AI integration features');
    buffer.writeln();
    
    // Notes
    if (project.notes.isNotEmpty) {
      buffer.writeln('## 📝 Notes & Updates');
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
}
