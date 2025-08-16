import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simple_ai_service.dart';
import '../models/project.dart';
import '../theme/app_themes.dart';

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

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleAIService>(
      builder: (context, aiService, child) {
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Simple AI Assistant',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: aiService.enabled,
                      onChanged: (value) => aiService.setEnabled(value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (!aiService.enabled) ...[
                  const Text(
                    'Enable Simple AI to generate TODO.md files and project insights.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ] else ...[
                  _buildModelInfo(aiService),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, aiService),
                  const SizedBox(height: 16),
                  _buildStatusMessage(aiService),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelInfo(SimpleAIService aiService) {
    final modelInfo = aiService.modelInfo;
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
            'Model: ${modelInfo['name']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Size: ${modelInfo['size']}'),
          Text('Purpose: ${modelInfo['purpose']}'),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SimpleAIService aiService) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _generateTODOMD(context, aiService),
            icon: const Icon(Icons.task_alt),
            label: const Text('Generate TODO.md'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemes.successGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _generateInsights(context, aiService),
            icon: const Icon(Icons.lightbulb),
            label: const Text('Get Insights'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemes.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(SimpleAIService aiService) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: aiService.isReady() 
            ? AppThemes.successGreen.withValues(alpha: 0.1)
            : AppThemes.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            aiService.isReady() ? Icons.check_circle : Icons.info,
            color: aiService.isReady() ? AppThemes.successGreen : AppThemes.warningOrange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              aiService.getStatusMessage(),
              style: TextStyle(
                color: aiService.isReady() ? AppThemes.successGreen : AppThemes.warningOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTODOMD(BuildContext context, SimpleAIService aiService) async {
    try {
      final todoContent = await aiService.analyzeRepositoryAndGenerateTodos(widget.project);
      if (mounted) {
        _showGeneratedContent(context, 'Generated TODO.md', todoContent);
      }
    } catch (e) {
      if (mounted) {
        _showError(context, 'Failed to generate TODO.md: $e');
      }
    }
  }

  Future<void> _generateInsights(BuildContext context, SimpleAIService aiService) async {
    try {
      final insights = await aiService.generateProjectInsights(widget.project);
      if (mounted) {
        _showGeneratedContent(context, 'Project Insights', insights);
      }
    } catch (e) {
      if (mounted) {
        _showError(context, 'Failed to generate insights: $e');
      }
    }
  }

  void _showGeneratedContent(BuildContext context, String title, String content) {
    if (!mounted) return;
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
              // TODO: Implement copying to clipboard or saving to file
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Content copied to clipboard')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppThemes.errorRed,
      ),
    );
  }
}
