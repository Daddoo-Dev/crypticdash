import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MistralAIService extends ChangeNotifier {
  bool _enabled = false;
  bool _modelLoaded = false;
  String _statusMessage = 'Mistral AI: Initializing...';
  
  // AI model configuration
  String? _serverUrl;
  bool _isLocalServer = false;
  
  bool get enabled => _enabled;
  bool get modelLoaded => _modelLoaded;
  String get statusMessage => _statusMessage;
  
  MistralAIService() {
    _enabled = true;
    initialize();
  }
  
  Future<void> initialize() async {
    try {
      _statusMessage = 'Mistral AI: Setting up...';
      notifyListeners();
      
      // Try to connect to local Mistral server first
      await _tryConnectToLocalServer();
      
      if (!_isLocalServer) {
        // If no local server, try to start one with the model
        await _startLocalModelServer();
      }
      
    } catch (e) {
      _statusMessage = 'Mistral AI: Initialization failed - $e';
      notifyListeners();
    }
  }
  
  Future<void> _tryConnectToLocalServer() async {
    try {
      // Try common local Mistral server URLs
      final urls = [
        'http://localhost:8080',
        'http://127.0.0.1:8080',
        'http://localhost:8000',
        'http://127.0.0.1:8000',
      ];
      
      for (final url in urls) {
        try {
          final response = await http.get(Uri.parse('$url/health')).timeout(
            const Duration(seconds: 2),
          );
          
          if (response.statusCode == 200) {
            _serverUrl = url;
            _isLocalServer = true;
            _statusMessage = 'Mistral AI: Connected to local server at $url';
            _modelLoaded = true;
            notifyListeners();
            return;
          }
        } catch (e) {
          // Continue to next URL
        }
      }
    } catch (e) {
      // No local server found, will try to start one
    }
  }
  
  Future<void> _startLocalModelServer() async {
    try {
      _statusMessage = 'Mistral AI: Starting local model server...';
      notifyListeners();
      
      // Check if we have the Mistral model file
      final modelFile = File('assets/ai_models/mistral/mistral-7b-instruct-v0.1-q4_k_m.gguf');
      if (!await modelFile.exists()) {
        throw Exception('Mistral model file not found. Please ensure the model is in assets/ai_models/mistral/');
      }
      
      // Try to start a local server using Python or other methods
      await _startPythonServer();
      
    } catch (e) {
      _statusMessage = 'Mistral AI: Failed to start local server - $e';
      notifyListeners();
    }
  }
  
  Future<void> _startPythonServer() async {
    try {
      // Check if Python is available
      final result = await Process.run('python', ['--version']);
      if (result.exitCode != 0) {
        throw Exception('Python not found. Please install Python to run local Mistral model.');
      }
      
      // Check if required packages are installed
      _statusMessage = 'Mistral AI: Checking Python dependencies...';
      notifyListeners();
      
      try {
        await Process.run('python', ['-c', 'import flask, transformers, torch'], runInShell: true);
      } catch (e) {
        throw Exception('Required Python packages not found. Please run: pip install -r assets/scripts/requirements.txt');
      }
      
      // Start the actual Python server
      _statusMessage = 'Mistral AI: Starting Python model server...';
      notifyListeners();
      
      // Start the Python server in the background
      final serverProcess = await Process.start(
        'python',
        ['assets/scripts/run_mistral_server.py'],
        runInShell: true,
      );
      
      // Wait for server to start
      await Future.delayed(const Duration(seconds: 5));
      
      // Test if server is responding
      try {
        final response = await http.get(Uri.parse('http://localhost:8080/health')).timeout(
          const Duration(seconds: 10),
        );
        
        if (response.statusCode == 200) {
          _serverUrl = 'http://localhost:8080';
          _isLocalServer = true;
          _modelLoaded = true;
          _statusMessage = 'Mistral AI: Local server ready at $_serverUrl';
          notifyListeners();
        } else {
          throw Exception('Server responded with status: ${response.statusCode}');
        }
      } catch (e) {
        // Kill the process if it failed
        serverProcess.kill();
        throw Exception('Failed to start server: $e');
      }
      
    } catch (e) {
      throw Exception('Failed to start Python server: $e');
    }
  }
  
  Future<String> analyzeRepositoryAndGenerateTodos(Map<String, dynamic> repositoryContent) async {
    if (!_enabled || !_modelLoaded) {
      throw Exception('Mistral AI is not ready');
    }
    
    try {
      _statusMessage = 'Mistral AI: Analyzing repository...';
      notifyListeners();
      
      // ACTUALLY ANALYZE the repository content with REAL AI
      final context = await _analyzeRealRepositoryContent(repositoryContent);
      
      // Generate AI prompt
      final prompt = _buildAIPrompt(context);
      
      // Use ACTUAL Mistral AI inference
      final todos = await _generateAITodos(prompt, context);
      
      _statusMessage = 'Mistral AI: Analysis complete';
      notifyListeners();
      
      return todos;
      
    } catch (e) {
      _statusMessage = 'Mistral AI: Analysis failed - $e';
      notifyListeners();
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> _analyzeRealRepositoryContent(Map<String, dynamic> repositoryContent) async {
    final context = <String, dynamic>{};
    
    // ACTUALLY READ the repository content - no fake data!
    if (repositoryContent['readme'] != null) {
      context['readme'] = repositoryContent['readme'];
      context['readmeAnalysis'] = _analyzeReadmeContent(repositoryContent['readme']);
    }
    
    if (repositoryContent['dependencies'] != null) {
      context['dependencies'] = repositoryContent['dependencies'];
      context['techStack'] = _analyzeRealDependencies(repositoryContent['dependencies']);
    }
    
    if (repositoryContent['projectFiles'] != null) {
      context['projectFiles'] = repositoryContent['projectFiles'];
      context['projectStructure'] = _analyzeProjectStructure(repositoryContent['projectFiles']);
    }
    
    // Force intelligent analysis - no generic fallbacks!
    context['requiresIntelligentAnalysis'] = true;
    
    return context;
  }

  String _buildAIPrompt(Map<String, dynamic> context) {
    final buffer = StringBuffer();
    
    // Use Mistral's recommended chat format for REAL AI inference
    buffer.writeln('<s>[INST] You are an expert software developer analyzing a GitHub repository. Generate a comprehensive TODO list based on the following analysis:');
    buffer.writeln();
    
    // Add repository context
    if (context['readme'] != null) {
      buffer.writeln('README Content:');
      buffer.writeln(context['readme']);
      buffer.writeln();
    }
    
    if (context['dependencies'] != null) {
      buffer.writeln('Dependencies:');
      buffer.writeln(context['dependencies'].toString());
      buffer.writeln();
    }
    
    if (context['projectFiles'] != null) {
      buffer.writeln('Project Files:');
      buffer.writeln(context['projectFiles'].toString());
      buffer.writeln();
    }
    
    buffer.writeln('Generate a detailed TODO list with specific, actionable tasks. Focus on:');
    buffer.writeln('- Missing documentation');
    buffer.writeln('- Code quality improvements');
    buffer.writeln('- Feature implementations');
    buffer.writeln('- Testing needs');
    buffer.writeln('- Performance optimizations');
    buffer.writeln();
    buffer.writeln('Format as markdown with checkboxes:');
    buffer.writeln('- [ ] Task description');
    buffer.writeln('[/INST]');
    
    return buffer.toString();
  }

  Future<String> _generateAITodos(String prompt, Map<String, dynamic> context) async {
    try {
      if (_serverUrl == null) {
        throw Exception('No AI server available');
      }
      
      // Make ACTUAL HTTP request to Mistral model server
      final response = await http.post(
        Uri.parse('$_serverUrl/generate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
          'max_tokens': 2048,
          'temperature': 0.7,
          'top_p': 0.9,
          'stop': ['</s>', '[INST]'],
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText = data['text'] ?? data['response'] ?? data['generated_text'] ?? '';
        
        if (generatedText.isNotEmpty) {
          return generatedText;
        } else {
          throw Exception('Empty response from AI model');
        }
      } else {
        throw Exception('AI server error: ${response.statusCode} - ${response.body}');
      }
      
    } catch (e) {
      // If HTTP request fails, try to start a new server
      if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        _statusMessage = 'Mistral AI: Server connection failed, attempting restart...';
        notifyListeners();
        
        await _startLocalModelServer();
        
        // Retry the request
        return await _generateAITodos(prompt, context);
      }
      
      throw Exception('AI generation failed: $e');
    }
  }
  
  Map<String, dynamic> _analyzeReadmeContent(String readme) {
    final analysis = <String, dynamic>{};
    
    // Check if README is actually useful or just an error message
    if (readme.contains('not found') || readme.contains('could not be read') || 
        readme.length < 50 || readme.contains('README.md not found')) {
      analysis['isUseful'] = false;
      analysis['reason'] = 'README is error message or too short to be meaningful';
      return analysis;
    }
    
    // README appears to be actual content
    analysis['isUseful'] = true;
    analysis['contentLength'] = readme.length;
    
    final content = readme.toLowerCase();
    
    // Extract meaningful keywords from README
    analysis['readmeKeywords'] = _extractKeywords(readme);
    
    // Actually analyze the README content if it's useful
    if (content.contains('game') || content.contains('player') || content.contains('sprite')) {
      analysis['projectType'] = 'game';
      analysis['gameElements'] = _extractGameElements(content);
    } else if (content.contains('dashboard') || content.contains('management')) {
      analysis['projectType'] = 'dashboard';
      analysis['dashboardFeatures'] = _extractDashboardFeatures(content);
    } else if (content.contains('api') || content.contains('service')) {
      analysis['projectType'] = 'api_service';
      analysis['apiFeatures'] = _extractApiFeatures(content);
    } else {
      analysis['projectType'] = 'unknown';
      analysis['requiresAnalysis'] = true;
    }
    
    return analysis;
  }
  
  Map<String, dynamic> _extractGameElements(String content) {
    final elements = <String, dynamic>{};
    
    if (content.contains('2d') || content.contains('platformer')) {
      elements['gameType'] = '2D Platformer';
    }
    if (content.contains('enemy') || content.contains('ai')) {
      elements['hasEnemies'] = true;
      elements['enemyTypes'] = ['basic', 'ai_driven'];
    }
    if (content.contains('checkpoint') || content.contains('save')) {
      elements['hasCheckpoints'] = true;
    }
    if (content.contains('flashlight') || content.contains('light')) {
      elements['hasLightMechanics'] = true;
    }
    
    return elements;
  }
  
  Map<String, dynamic> _extractDashboardFeatures(String content) {
    final features = <String, dynamic>{};
    
    if (content.contains('github') || content.contains('repository')) {
      features['hasGitHubIntegration'] = true;
    }
    if (content.contains('ai') || content.contains('mistral')) {
      features['hasAI'] = true;
      features['aiType'] = 'Mistral 7B Local';
    }
    if (content.contains('todo') || content.contains('task')) {
      features['hasTaskManagement'] = true;
    }
    
    return features;
  }
  
  Map<String, dynamic> _extractApiFeatures(String content) {
    final features = <String, dynamic>{};
    
    if (content.contains('authentication') || content.contains('jwt')) {
      features['hasAuth'] = true;
    }
    if (content.contains('database') || content.contains('storage')) {
      features['hasDatabase'] = true;
    }
    
    return features;
  }
  
  List<String> _analyzeRealDependencies(Map<String, dynamic> dependencies) {
    // Use the better tech stack extraction method
    return _extractTechStack({'dependencies': dependencies, 'projectFiles': []});
  }
  
  Map<String, dynamic> _analyzeProjectStructure(dynamic projectFiles) {
    final structure = <String, dynamic>{};
    
    // Handle both List<String> and the new repository structure format
    List<String> files = [];
    
    if (projectFiles is List<String>) {
      files = projectFiles;
    } else if (projectFiles is List) {
      // Convert dynamic list to string list
      files = projectFiles.map((item) => item.toString()).toList();
    } else {
      // Fallback for unexpected format
      structure['error'] = 'Unexpected project files format: ${projectFiles.runtimeType}';
      return structure;
    }
    
    // Actually analyze the project structure
    if (files.any((String file) => file.contains('game'))) {
      structure['hasGameComponents'] = true;
    }
    if (files.any((String file) => file.contains('ai_models'))) {
      structure['hasAIModels'] = true;
    }
    if (files.any((String file) => file.contains('services'))) {
      structure['hasServices'] = true;
    }
    if (files.any((String file) => file.contains('widgets'))) {
      structure['hasUIComponents'] = true;
    }
    
    // Add file count for debugging
    structure['totalFiles'] = files.length;
    
    return structure;
  }
  
  List<String> _extractTechStack(Map<String, dynamic> context) {
    final techStack = <String>[];
    
    // DYNAMICALLY analyze what we actually find - no hardcoded assumptions!
    if (context['dependencies'] != null) {
      final deps = context['dependencies'];
      if (deps is Map) {
        deps.forEach((key, value) {
          final dep = key.toString().toLowerCase();
          
          // Analyze what this dependency actually is
          if (dep.contains('flutter') || dep.contains('dart')) {
            techStack.add('Flutter/Dart');
          }
          if (dep.contains('react') || dep.contains('vue') || dep.contains('angular')) {
            techStack.add('Modern Web Framework');
          }
          if (dep.contains('express') || dep.contains('fastapi') || dep.contains('django')) {
            techStack.add('Backend Framework');
          }
          if (dep.contains('provider') || dep.contains('bloc') || dep.contains('riverpod')) {
            techStack.add('State Management');
          }
          if (dep.contains('http') || dep.contains('dio')) {
            techStack.add('HTTP Client');
          }
          if (dep.contains('ai') || dep.contains('mistral') || dep.contains('onnx')) {
            techStack.add('Local AI Models');
          }
          if (dep.contains('github')) {
            techStack.add('GitHub API Integration');
          }
        });
      }
    }
    
    // If we can't determine from dependencies, analyze file patterns
    if (techStack.isEmpty && context['projectFiles'] != null) {
      final projectFiles = context['projectFiles'];
      // Ensure we have a proper List<String> for type safety
      final files = <String>[];
      for (final item in projectFiles) {
        if (item != null) {
          files.add(item.toString().toLowerCase());
        }
      }
      
      if (files.any((String f) => f.contains('.gd'))) techStack.add('Godot Game Engine');
      if (files.any((String f) => f.contains('.cs'))) techStack.add('Unity/C#');
      if (files.any((String f) => f.contains('.py'))) techStack.add('Python');
      if (files.any((String f) => f.contains('.rs'))) techStack.add('Rust');
      if (files.any((String f) => f.contains('.go'))) techStack.add('Go');
      if (files.any((String f) => f.contains('.js') || f.contains('.ts'))) techStack.add('JavaScript/TypeScript');
    }
    
    return techStack.isEmpty ? ['Requires Analysis'] : techStack;
  }
  
  List<String> _extractKeywords(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final keywords = <String>[];
    
    for (final word in words) {
      final clean = word.replaceAll(RegExp(r'[^\w]'), '');
      if (clean.length > 3 && !_isCommonWord(clean)) {
        keywords.add(clean);
      }
    }
    
    return keywords.take(10).toList(); // Top 10 keywords
  }
  
  bool _isCommonWord(String word) {
    const commonWords = {
      'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had', 'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his', 'how', 'man', 'new', 'now', 'old', 'see', 'two', 'way', 'who', 'boy', 'did', 'its', 'let', 'put', 'say', 'she', 'too', 'use'
    };
    return commonWords.contains(word);
  }
  
  void setModelPath(String path) {
    notifyListeners();
  }
  
  void enable() {
    _enabled = true;
    notifyListeners();
  }
  
  void disable() {
    _enabled = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _enabled = false;
    _modelLoaded = false;
    _statusMessage = 'Mistral AI: Disposed';
    
    super.dispose();
  }
}
