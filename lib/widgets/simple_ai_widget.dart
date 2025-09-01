import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/project.dart';
import '../services/onnx_ai_service.dart';
import '../services/github_service.dart';
import '../services/project_service.dart';


import 'yeti_loading_widget.dart';

class SimpleAIWidget extends StatefulWidget {
  final Project project;
  
  const SimpleAIWidget({
    super.key,
    required this.project,
  });

  @override
  State<SimpleAIWidget> createState() => _SimpleAIWidgetState();
}

class _SimpleAIWidgetState extends State<SimpleAIWidget> {
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ONNXAIService>(
      builder: (context, aiService, child) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                     const Icon(
                       Icons.ac_unit,
                       color: Colors.blue,
                       size: 24,
                     ),
                    const SizedBox(width: 8),
                    const Text(
                       'Yeti Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                     _buildStatusBadge(aiService),
                  ],
                ),
                const SizedBox(height: 16),
                 if (_isAnalyzing) ...[
                   // Show centered Yeti animation during processing
                                       Container(
                      width: double.infinity,
                      height: 300, // Increased height to prevent overflow
                      decoration: BoxDecoration(
                        color: Colors.grey[50]?.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, // Prevent expansion
                            children: [
                              const YetiLoadingWidget(message: 'Yeti is analyzing your repository...'),
                const SizedBox(height: 16),
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                                 const SizedBox(height: 16),
                              Text(
                                'This may take a few moments...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                           ),
                         ),
                       ),
                 ] else ...[
                   // Show the button when not analyzing
                   Tooltip(
                     message: 'Analyze repository and generate To-Do file',
                     child: SizedBox(
                       width: double.infinity,
                         child: ElevatedButton.icon(
                         onPressed: !aiService.modelLoaded
                             ? null
                             : () => _generateTODOMD(context, aiService),
                         icon: const Icon(Icons.task_alt),
                         label: const Text('Analyze & Generate To-Do'),
                           style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.blue,
                             foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                         ),
                       ),
                     ),
                   ),
                 ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ONNXAIService aiService) {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    if (aiService.statusMessage.contains('Ready')) {
      badgeColor = Colors.green;
      statusText = 'Ready';
      statusIcon = Icons.check_circle;
    } else if (aiService.statusMessage.contains('failed') || 
               aiService.statusMessage.contains('error')) {
      badgeColor = Colors.red;
      statusText = 'Failed to Load';
      statusIcon = Icons.error;
    } else {
      badgeColor = Colors.orange;
      statusText = 'Loading';
      statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text(
            statusText,
              style: TextStyle(
              color: badgeColor,
                fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTODOMD(BuildContext context, ONNXAIService aiService) async {
    // Store context before async gap
    final currentContext = context;
    
    // Define todoFileName outside try block so it's accessible in the title
    final todoFileName = '${widget.project.repoName}-TODO.md';
    
    // Get GitHubService before async operations to avoid BuildContext issues
    final githubService = Provider.of<GitHubService>(currentContext, listen: false);
    
    try {
      // Add error boundary for setState
      if (mounted) {
      setState(() {
        _isAnalyzing = true;
      });
      }
      
      // Check if {reponame}-TODO.md already exists
      String? existingTodo = '';
      try {
        existingTodo = await githubService.getFileContent(
          widget.project.owner, 
          widget.project.repoName, 
          todoFileName
        );
      } catch (e) {
        // {reponame}-TODO.md doesn't exist, that's fine
        existingTodo = null;
      }
      
      // Gather actual repository content for AI analysis
      final repositoryContent = await _gatherRepositoryContent(githubService);
      
      // Use intelligent task management with actual repository content
      final todoContent = await aiService.manageRepositoryTodos(
        widget.project.name,
        existingTodoContent: existingTodo,
        readmeContent: repositoryContent['readme'],
        pubspecContent: repositoryContent['pubspec'],
        packageJsonContent: repositoryContent['packageJson'],
        sourceFiles: repositoryContent['sourceFiles'],
        dependencies: repositoryContent['dependencies'],
      );
      
      if (currentContext.mounted) {
        setState(() {
          _isAnalyzing = false;
        });
         
        // Show preview dialog with save/cancel options
        _showPreviewDialog(context, todoContent, todoFileName, existingTodo != null);
      }
    } catch (e) {
      if (currentContext.mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _showErrorDialog(currentContext, 'Error managing To-Do: $e');
      }
    }
  }

  void _showPreviewDialog(BuildContext context, String todoContent, String todoFileName, bool isUpdate) {
    final title = isUpdate ? 'Updated $todoFileName' : 'Generated $todoFileName';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(todoContent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _saveToGitHub(todoContent, todoFileName);
            },
            child: const Text('Save to GitHub'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveToGitHub(String todoContent, String todoFileName) async {
    try {
      final githubService = Provider.of<GitHubService>(context, listen: false);
      
      final success = await githubService.createOrUpdateTODOMD(
        widget.project.owner,
        widget.project.repoName,
        todoContent,
        'Update To-Do file with AI-generated analysis',
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $todoFileName saved to GitHub successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh the project data to show updated content
          try {
            final projectService = Provider.of<ProjectService>(context, listen: false);
            await projectService.refreshProject(widget.project);
          } catch (e) {
            // Log error but don't show to user since save was successful
            debugPrint('Error refreshing project after save: $e');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to save to GitHub. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving to GitHub: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  /// Gather actual repository content for AI analysis
  Future<Map<String, dynamic>> _gatherRepositoryContent(GitHubService githubService) async {
    final content = <String, dynamic>{};
    
    try {
      
      // Read README.md
      try {
        final readme = await githubService.getFileContent(
          widget.project.owner, 
          widget.project.repoName, 
          'README.md'
        );
          content['readme'] = readme;
              } catch (e) {
        content['readme'] = null;
      }
      
      // Read pubspec.yaml (Flutter/Dart)
      try {
        final pubspec = await githubService.getFileContent(
          widget.project.owner, 
          widget.project.repoName, 
          'pubspec.yaml'
        );
        content['pubspec'] = pubspec;
        if (pubspec != null) {
          content['dependencies'] = _parsePubspecDependencies(pubspec);
        }
      } catch (e) {
        content['pubspec'] = null;
        content['dependencies'] = null;
      }
      
      // Read package.json (Node.js/JavaScript)
      try {
        final packageJson = await githubService.getFileContent(
          widget.project.owner, 
          widget.project.repoName, 
          'package.json'
        );
        content['packageJson'] = packageJson;
        if (packageJson != null && content['dependencies'] == null) {
          content['dependencies'] = _parsePackageJsonDependencies(packageJson);
        }
      } catch (e) {
        content['packageJson'] = null;
      }
      
      // Get repository file structure
      try {
        final files = await githubService.getDirectoryContents(
          widget.project.owner, 
          widget.project.repoName, 
          ''
        );
        content['sourceFiles'] = files.map((f) => f['name'] as String).toList();
      } catch (e) {
        content['sourceFiles'] = [];
      }
      
    } catch (e) {
      // If we can't gather content, provide empty defaults
      content['readme'] = null;
      content['pubspec'] = null;
      content['packageJson'] = null;
      content['dependencies'] = null;
      content['sourceFiles'] = [];
    }
    
    return content;
  }

  Map<String, dynamic> _parsePubspecDependencies(String pubspecContent) {
    final deps = <String, dynamic>{};
    final lines = pubspecContent.split('\n');
    bool inDependencies = false;
    
    for (final line in lines) {
      if (line.trim() == 'dependencies:') {
        inDependencies = true;
        continue;
      }
      if (inDependencies && line.trim().startsWith('dev_dependencies:')) {
        break;
      }
      if (inDependencies && line.trim().isNotEmpty && !line.trim().startsWith('#')) {
        final parts = line.trim().split(':');
        if (parts.length >= 2) {
          final name = parts[0].trim();
          final version = parts[1].trim();
          deps[name] = version;
        }
      }
    }
    
    return deps;
  }

  Map<String, dynamic> _parsePackageJsonDependencies(String packageJsonContent) {
    try {
      final json = jsonDecode(packageJsonContent);
      if (json is Map<String, dynamic> && json.containsKey('dependencies')) {
        return Map<String, dynamic>.from(json['dependencies']);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return {};
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
