import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mistral_ai_service.dart';
import '../theme/app_themes.dart';
import '../models/project.dart';
import '../services/github_service.dart'; // Added import for GitHubService
import 'dart:convert'; // Added import for jsonDecode

class SimpleAIWidget extends StatelessWidget {
  final Project project;
  
  const SimpleAIWidget({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MistralAIService>(
      builder: (context, aiService, child) {
        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: AppThemes.primaryBlue),
                    const SizedBox(width: 8),
                    const Text(
                      'Mistral AI Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: aiService.enabled,
                      onChanged: (value) => value ? aiService.enable() : aiService.disable(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModelInfo(aiService),
                const SizedBox(height: 16),
                _buildStatusMessage(aiService),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: aiService.enabled ? () => _generateTODOMD(context, aiService) : null,
                        icon: const Icon(Icons.checklist),
                        label: const Text('Generate TODO.md'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: aiService.enabled ? () => _generateInsights(context, aiService) : null,
                        icon: const Icon(Icons.lightbulb),
                        label: const Text('Get Insights'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.successGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelInfo(MistralAIService aiService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemes.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model: Mistral 7B Instruct',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Size: 4.37 GB (Q4_K_M)'),
          Text('Purpose: Local AI analysis and TODO generation'),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(MistralAIService aiService) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: aiService.modelLoaded 
            ? AppThemes.successGreen.withValues(alpha: 0.1)
            : AppThemes.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            aiService.modelLoaded ? Icons.check_circle : Icons.info,
            color: aiService.modelLoaded ? AppThemes.successGreen : AppThemes.warningOrange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              aiService.statusMessage,
              style: TextStyle(
                color: aiService.modelLoaded ? AppThemes.successGreen : AppThemes.warningOrange,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTODOMD(BuildContext context, MistralAIService aiService) async {
    try {
      // ACTUALLY READ the repository content - no hardcoded bullshit!
      final repositoryContent = await _gatherRealRepositoryContent(context, project);
      
      final todoContent = await aiService.analyzeRepositoryAndGenerateTodos(repositoryContent);
      if (context.mounted) {
        _showGeneratedContent(context, 'Generated TODO.md', todoContent);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Error generating TODO: $e');
      }
    }
  }

  Future<void> _generateInsights(BuildContext context, MistralAIService aiService) async {
    try {
      // ACTUALLY READ the repository content - no hardcoded bullshit!
      final repositoryContent = await _gatherRealRepositoryContent(context, project);
      
      final insights = await aiService.analyzeRepositoryAndGenerateTodos(repositoryContent);
      if (context.mounted) {
        _showGeneratedContent(context, 'Project Insights', insights);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Error generating insights: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _gatherRealRepositoryContent(BuildContext context, Project project) async {
    final content = <String, dynamic>{};
    
    try {
      // Get the GitHub service from the context
      final githubService = Provider.of<GitHubService>(context, listen: false);
      
      // ACTUALLY READ the README
      try {
        final readme = await githubService.getFileContent(project.owner, project.repoName, 'README.md');
        if (readme != null && readme.isNotEmpty) {
          content['readme'] = readme;
          print('✅ README.md found: ${readme.length} characters');
        } else {
          content['readme'] = 'README.md is empty or could not be read';
          print('⚠️ README.md is empty or null');
        }
      } catch (e) {
        content['readme'] = 'README.md not found or could not be read';
        print('❌ README.md error: $e');
      }
      
      // ACTUALLY READ the dependencies
      try {
        final pubspec = await githubService.getFileContent(project.owner, project.repoName, 'pubspec.yaml');
        if (pubspec != null && pubspec.isNotEmpty) {
          content['dependencies'] = _parsePubspecDependencies(pubspec);
          print('✅ pubspec.yaml found and parsed');
        } else {
          print('⚠️ pubspec.yaml is empty or null');
          try {
            final packageJson = await githubService.getFileContent(project.owner, project.repoName, 'package.json');
            if (packageJson != null && packageJson.isNotEmpty) {
              content['dependencies'] = _parsePackageJsonDependencies(packageJson);
              print('✅ package.json found and parsed');
            } else {
              content['dependencies'] = {'error': 'No dependency files found'};
              print('❌ No dependency files found');
            }
          } catch (e2) {
            content['dependencies'] = {'error': 'Could not read dependency files: $e2'};
            print('❌ Dependency file error: $e2');
          }
        }
      } catch (e) {
        content['dependencies'] = {'error': 'Could not read pubspec.yaml: $e'};
        print('❌ pubspec.yaml error: $e');
      }
      
      // ACTUALLY LIST the project files
      try {
        final files = await _listProjectFiles(githubService, project);
        content['projectFiles'] = files;
      } catch (e) {
        content['projectFiles'] = ['Error listing project files: $e'];
      }
      
    } catch (e) {
      throw Exception('Failed to gather repository content: $e');
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
      // Fallback to basic parsing
    }
    return {'error': 'Could not parse package.json'};
  }

  Future<List<String>> _listProjectFiles(GitHubService githubService, Project project) async {
    final files = <String>[];
    
    try {
      // Use the new recursive repository exploration to discover ALL files and directories
      final structure = await githubService.exploreRepositoryStructure(project.owner, project.repoName);
      
      // Add all discovered files
      files.addAll(structure['files'] as List<String>);
      
      // Add all discovered directories
      files.addAll((structure['directories'] as List<String>).map((dir) => '$dir/ (directory)'));
      
      // Log what we found for debugging
      print('Discovered ${structure['files'].length} files and ${structure['directories'].length} directories');
      
    } catch (e) {
      files.add('Error exploring repository: $e');
    }
    
    return files;
  }

  void _showGeneratedContent(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(content),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement save functionality
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
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
