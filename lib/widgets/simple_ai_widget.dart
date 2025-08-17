import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/project.dart';
import '../services/onnx_ai_service.dart';
import '../services/github_service.dart';

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
                    Icon(
                      aiService.enabled ? Icons.smart_toy : Icons.smart_toy_outlined,
                      color: aiService.enabled ? Colors.blue : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ONNX AI Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModelInfo(),
                const SizedBox(height: 16),
                _buildStatusMessage(aiService),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing || !aiService.modelLoaded
                            ? null
                            : () => _generateTODOMD(context, aiService),
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.task_alt),
                        label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze & Generate TODO.md'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing || !aiService.modelLoaded
                            ? null
                            : () => _generateInsights(context, aiService),
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lightbulb),
                        label: Text(_isAnalyzing ? 'Analyzing...' : 'Generate Insights'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isAnalyzing) ...[
                  const SizedBox(height: 16),
                  const YetiLoadingWidget(message: 'AI is analyzing your repository...'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model: Gemma 3 270M IT',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Size: 1.0 GB (ONNX Q4)'),
          Text('Purpose: Local AI analysis and TODO generation'),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(ONNXAIService aiService) {
    Color statusColor;
    IconData statusIcon;

    if (aiService.statusMessage.contains('Ready')) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (aiService.statusMessage.contains('failed') || 
               aiService.statusMessage.contains('error')) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              aiService.statusMessage,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTODOMD(BuildContext context, ONNXAIService aiService) async {
    // Store context before async gap
    final currentContext = context;
    
    try {
      setState(() {
        _isAnalyzing = true;
      });
      
      // Check if TODO.md already exists
      String? existingTodo = '';
      try {
        final githubService = Provider.of<GitHubService>(currentContext, listen: false);
        existingTodo = await githubService.getFileContent(
          widget.project.owner, 
          widget.project.repoName, 
          'TODO.md'
        );
      } catch (e) {
        // TODO.md doesn't exist, that's fine
        existingTodo = null;
      }
      
      // Gather actual repository content for AI analysis
      final repositoryContent = await _gatherRepositoryContent(currentContext);
      
      // Use intelligent TODO management with actual repository content
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
        
        final title = existingTodo != null ? 'Updated TODO.md' : 'Generated TODO.md';
        _showGeneratedContent(currentContext, title, todoContent);
      }
    } catch (e) {
      if (currentContext.mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _showErrorDialog(currentContext, 'Error managing TODO: $e');
      }
    }
  }

  Future<void> _generateInsights(BuildContext context, ONNXAIService aiService) async {
    // Store context before async gap
    final currentContext = context;
    
    try {
      setState(() {
        _isAnalyzing = true;
      });
      
      // Gather actual repository content for AI analysis
      final repositoryContent = await _gatherRepositoryContent(currentContext);
      
      final insights = await aiService.analyzeRepositoryAndGenerateTodos(
        widget.project.name,
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
        _showGeneratedContent(currentContext, 'Project Insights', insights);
      }
    } catch (e) {
      if (currentContext.mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _showErrorDialog(currentContext, 'Error generating insights: $e');
      }
    }
  }

  void _showGeneratedContent(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Gather actual repository content for AI analysis
  Future<Map<String, dynamic>> _gatherRepositoryContent(BuildContext context) async {
    final content = <String, dynamic>{};
    
    try {
      final githubService = Provider.of<GitHubService>(context, listen: false);
      
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
