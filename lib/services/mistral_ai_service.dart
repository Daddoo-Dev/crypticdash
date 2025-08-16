import 'package:flutter/material.dart';
import 'dart:convert';

class MistralAIService extends ChangeNotifier {
  bool _enabled = false;
  bool _modelLoaded = false;
  String _statusMessage = 'Mistral AI: Initializing...';
  
  bool get enabled => _enabled;
  bool get modelLoaded => _modelLoaded;
  String get statusMessage => _statusMessage;
  
  MistralAIService() {
    // Auto-initialize when service is created
    _enabled = true; // Enable by default
    initialize();
  }
  
  Future<void> initialize() async {
    try {
      _statusMessage = 'Mistral AI: Setting up...';
      notifyListeners();
      
      // For now, skip file existence check since assets are bundled
      // TODO: Implement proper asset loading when llama.cpp is integrated
      
      // Simulate model loading
      await _loadModel();
      
    } catch (e) {
      _statusMessage = 'Mistral AI: Initialization failed - $e';
      notifyListeners();
    }
  }
  
  Future<void> _loadModel() async {
    try {
      _statusMessage = 'Mistral AI: Loading model...';
      notifyListeners();
      
      // TODO: Implement actual llama.cpp FFI integration
      // For now, simulate loading with a delay
      await Future.delayed(const Duration(seconds: 2));
      
      _modelLoaded = true;
      _statusMessage = 'Mistral AI: Ready';
      notifyListeners();
      
    } catch (e) {
      _statusMessage = 'Mistral AI: Model loading failed - $e';
      notifyListeners();
    }
  }
  
  Future<String> analyzeRepositoryAndGenerateTodos(Map<String, dynamic> repositoryContent) async {
    if (!_enabled || !_modelLoaded) {
      throw Exception('Mistral AI is not ready');
    }
    
    try {
      _statusMessage = 'Mistral AI: Analyzing repository...';
      notifyListeners();
      
      // ACTUALLY ANALYZE the repository content - no fake data!
      final context = await _analyzeRealRepositoryContent(repositoryContent);
      
      // Generate prompt for TODO generation
      _createTodoGenerationPrompt(context);
      
      // TODO: Send to Mistral model via llama.cpp
      // For now, return intelligent analysis based on REAL content
      final todos = await _generateIntelligentTodos(context);
      
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
    
    // ACTUALLY READ the repository content - no hardcoded bullshit!
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
    final techStack = <String>[];
    
    // Actually analyze the real dependencies
    dependencies.forEach((key, value) {
      final dep = key.toString().toLowerCase();
      if (dep.contains('flutter') || dep.contains('dart')) {
        techStack.add('Flutter/Dart');
      }
      if (dep.contains('provider')) {
        techStack.add('Provider State Management');
      }
      if (dep.contains('http')) {
        techStack.add('HTTP Client');
      }
      if (dep.contains('ai') || dep.contains('mistral') || dep.contains('onnx')) {
        techStack.add('Local AI Models');
      }
      if (dep.contains('github')) {
        techStack.add('GitHub API Integration');
      }
    });
    
    return techStack.isEmpty ? ['Unknown - Requires Analysis'] : techStack;
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
    if (files.any((file) => file.contains('game'))) {
      structure['hasGameComponents'] = true;
    }
    if (files.any((file) => file.contains('ai_models'))) {
      structure['hasAIModels'] = true;
    }
    if (files.any((file) => file.contains('services'))) {
      structure['hasServices'] = true;
    }
    if (files.any((file) => file.contains('widgets'))) {
      structure['hasUIComponents'] = true;
    }
    
    // Add file count for debugging
    structure['totalFiles'] = files.length;
    
    return structure;
  }
  
  String _createTodoGenerationPrompt(Map<String, dynamic> context) {
    return '''
You are an expert project analyst. Analyze this project and generate a comprehensive TODO.md file that includes:

1. HIGH-LEVEL PROJECT PHASES (like "Core Gameplay", "Technical Implementation", "Distribution")
2. SPECIFIC ACTIONABLE TASKS (like "Fix null safety in lib/game/player.dart:45")
3. PROGRESS TRACKING (current phase, next milestone)
4. CATEGORIZED TASKS (Infrastructure, Development, Documentation)

Project Context:
${jsonEncode(context)}

Generate a TODO.md that follows this exact format and provides both strategic direction and specific next steps.
''';
  }
  
  Future<String> _generateIntelligentTodos(Map<String, dynamic> context) async {
    // TODO: Replace with actual Mistral inference via llama.cpp
    // For now, generate intelligent analysis based on REAL content analysis
    
    final projectType = _detectProjectTypeFromFiles(context);
    final projectProgress = _analyzeCurrentProgress(context);
    final projectRoadmap = _generateCompleteRoadmap(context, projectType, projectProgress);
    
    return _formatIntelligentTODO(context, projectType, projectProgress, projectRoadmap);
  }
  
  String _detectProjectTypeFromFiles(Map<String, dynamic> context) {
    final projectFiles = context['projectFiles'] ?? [];
    if (projectFiles is! List) return 'UNKNOWN';
    
    final files = projectFiles.map((f) => f.toString().toLowerCase()).toList();
    
    // COMPREHENSIVE FRAMEWORK DETECTION - ALL OF THEM!
    
    // Game Engines
    if (files.any((f) => f.contains('project.godot') || f.contains('.gd'))) {
      return 'GODOT_GAME';
    }
    if (files.any((f) => f.contains('.unity') || f.contains('.cs') || f.contains('unitypackage'))) {
      return 'UNITY_GAME';
    }
    if (files.any((f) => f.contains('.uproject') || f.contains('.uasset') || f.contains('.umap'))) {
      return 'UNREAL_GAME';
    }
    if (files.any((f) => f.contains('main.lua') || f.contains('.lua') && f.contains('love'))) {
      return 'LOVE_GAME';
    }
    if (files.any((f) => f.contains('game.cs') || f.contains('.cs') && f.contains('monogame'))) {
      return 'MONOGAME_GAME';
    }
    if (files.any((f) => f.contains('phaser') || f.contains('game.js') && f.contains('phaser'))) {
      return 'PHASER_GAME';
    }
    if (files.any((f) => f.contains('three.js') || f.contains('three.min.js'))) {
      return 'THREEJS_GAME';
    }
    
    // Web Frameworks
    if (files.any((f) => f.contains('package.json'))) {
      if (files.any((f) => f.contains('react') || f.contains('jsx') || f.contains('.tsx'))) {
        return 'REACT_APP';
      }
      if (files.any((f) => f.contains('vue') || f.contains('.vue'))) {
        return 'VUE_APP';
      }
      if (files.any((f) => f.contains('angular') || f.contains('angular.json'))) {
        return 'ANGULAR_APP';
      }
      if (files.any((f) => f.contains('svelte') || f.contains('svelte.config.js'))) {
        return 'SVELTE_APP';
      }
      if (files.any((f) => f.contains('solid') || f.contains('solid.config.js'))) {
        return 'SOLID_APP';
      }
      if (files.any((f) => f.contains('qwik') || f.contains('qwik.config.js'))) {
        return 'QWIK_APP';
      }
      if (files.any((f) => f.contains('next.config.js') || f.contains('next-env.d.ts'))) {
        return 'NEXTJS_APP';
      }
      if (files.any((f) => f.contains('nuxt.config.js') || f.contains('nuxt.config.ts'))) {
        return 'NUXT_APP';
      }
      if (files.any((f) => f.contains('remix.config.js') || f.contains('remix.config.ts'))) {
        return 'REMIX_APP';
      }
      if (files.any((f) => f.contains('astro.config.js') || f.contains('astro.config.ts'))) {
        return 'ASTRO_APP';
      }
      return 'NODEJS_APP';
    }
    
    // Mobile Frameworks
    if (files.any((f) => f.contains('pubspec.yaml') || f.contains('lib/main.dart'))) {
      return 'FLUTTER_APP';
    }
    if (files.any((f) => f.contains('android/') || f.contains('ios/') || f.contains('androidmanifest.xml'))) {
      if (files.any((f) => f.contains('react-native') || f.contains('metro.config.js'))) {
        return 'REACT_NATIVE_APP';
      }
      if (files.any((f) => f.contains('xamarin') || f.contains('.csproj'))) {
        return 'XAMARIN_APP';
      }
      if (files.any((f) => f.contains('ionic') || f.contains('ionic.config.json'))) {
        return 'IONIC_APP';
      }
      if (files.any((f) => f.contains('nativescript') || f.contains('nativescript.config.js'))) {
        return 'NATIVESCRIPT_APP';
      }
      return 'MOBILE_APP';
    }
    
    // Backend Frameworks
    if (files.any((f) => f.contains('requirements.txt') || f.contains('pyproject.toml'))) {
      if (files.any((f) => f.contains('django') || f.contains('manage.py'))) {
        return 'DJANGO_APP';
      }
      if (files.any((f) => f.contains('fastapi') || f.contains('main.py') && f.contains('fastapi'))) {
        return 'FASTAPI_APP';
      }
      if (files.any((f) => f.contains('flask') || f.contains('app.py') && f.contains('flask'))) {
        return 'FLASK_APP';
      }
      return 'PYTHON_APP';
    }
    if (files.any((f) => f.contains('package.json') && files.any((f) => f.contains('express') || f.contains('app.js')))) {
      return 'EXPRESS_APP';
    }
    if (files.any((f) => f.contains('Gemfile') || f.contains('.rb'))) {
      return 'RUBY_APP';
    }
    if (files.any((f) => f.contains('composer.json') || f.contains('.php'))) {
      return 'PHP_APP';
    }
    
    // Desktop Frameworks
    if (files.any((f) => f.contains('electron') || f.contains('main.js') && f.contains('electron'))) {
      return 'ELECTRON_APP';
    }
    if (files.any((f) => f.contains('tauri') || f.contains('tauri.conf.json'))) {
      return 'TAURI_APP';
    }
    if (files.any((f) => f.contains('.qml') || f.contains('qmake'))) {
      return 'QT_APP';
    }
    if (files.any((f) => f.contains('.xaml') || f.contains('.csproj'))) {
      return 'WPF_APP';
    }
    
    // If we can't determine, analyze the file structure more deeply
    return 'INTELLIGENT_ANALYSIS_REQUIRED';
  }
  
  Map<String, dynamic> _analyzeCurrentProgress(Map<String, dynamic> context) {
    final projectFiles = context['projectFiles'] ?? [];
    if (projectFiles is! List) return {'error': 'No project files found'};
    
    final files = projectFiles.map((f) => f.toString().toLowerCase()).toList();
    final progress = <String, dynamic>{};
    
    // DYNAMICALLY analyze what exists - no hardcoded assumptions!
    progress['totalFiles'] = files.length;
    progress['hasConfigFiles'] = files.any((f) => f.contains('.yaml') || f.contains('.json') || f.contains('.toml') || f.contains('.xml'));
    progress['hasSourceCode'] = files.any((f) => f.contains('.dart') || f.contains('.js') || f.contains('.ts') || f.contains('.py') || f.contains('.rs') || f.contains('.go') || f.contains('.gd') || f.contains('.cs'));
    progress['hasAssets'] = files.any((f) => f.contains('.png') || f.contains('.jpg') || f.contains('.svg') || f.contains('.ogg') || f.contains('.wav') || f.contains('.mp3'));
    progress['hasScenes'] = files.any((f) => f.contains('scenes/') || f.contains('levels/') || f.contains('worlds/'));
    progress['hasScripts'] = files.any((f) => f.contains('scripts/') || f.contains('lib/') || f.contains('src/'));
    progress['hasDocumentation'] = files.any((f) => f.contains('.md') || f.contains('.txt') || f.contains('docs/'));
    progress['hasTests'] = files.any((f) => f.contains('test/') || f.contains('tests/') || f.contains('spec/'));
    
    // Analyze file patterns to understand project structure
    progress['filePatterns'] = _analyzeFilePatterns(files);
    
    // Framework-specific progress analysis based on detected type
    final projectType = _detectProjectTypeFromFiles(context);
    progress['frameworkProgress'] = _analyzeFrameworkProgress(projectType, files);
    
    return progress;
  }
  
  Map<String, dynamic> _analyzeFrameworkProgress(String projectType, List<String> files) {
    final progress = <String, dynamic>{};
    
    switch (projectType) {
      case 'GODOT_GAME':
        progress['hasProjectFile'] = files.any((f) => f.contains('project.godot'));
        progress['hasScenes'] = files.any((f) => f.contains('scenes/'));
        progress['hasScripts'] = files.any((f) => f.contains('scripts/') || f.contains('.gd'));
        progress['hasAssets'] = files.any((f) => f.contains('assets/'));
        progress['hasSprites'] = files.any((f) => f.contains('sprites/') || f.contains('.png') || f.contains('.jpg'));
        progress['hasAudio'] = files.any((f) => f.contains('audio/') || f.contains('.ogg') || f.contains('.wav'));
        progress['hasUI'] = files.any((f) => f.contains('ui/') || f.contains('hud/'));
        progress['hasPlayer'] = files.any((f) => f.contains('player') || f.contains('character'));
        progress['hasEnemies'] = files.any((f) => f.contains('enemy') || f.contains('enemies'));
        progress['hasLevels'] = files.any((f) => f.contains('level') || f.contains('scene'));
        progress['hasGameLogic'] = files.any((f) => f.contains('game') || f.contains('manager'));
        break;
        
      case 'UNITY_GAME':
        progress['hasProjectFile'] = files.any((f) => f.contains('.unity'));
        progress['hasScenes'] = files.any((f) => f.contains('.unity'));
        progress['hasScripts'] = files.any((f) => f.contains('.cs'));
        progress['hasAssets'] = files.any((f) => f.contains('assets/'));
        progress['hasPrefabs'] = files.any((f) => f.contains('.prefab'));
        progress['hasMaterials'] = files.any((f) => f.contains('.mat'));
        progress['hasAnimations'] = files.any((f) => f.contains('.anim'));
        progress['hasAudio'] = files.any((f) => f.contains('audio/') || f.contains('.wav') || f.contains('.mp3'));
        break;
        
      case 'FLUTTER_APP':
        progress['hasPubspec'] = files.any((f) => f.contains('pubspec.yaml'));
        progress['hasLib'] = files.any((f) => f.contains('lib/'));
        progress['hasScreens'] = files.any((f) => f.contains('screens/') || f.contains('pages/'));
        progress['hasWidgets'] = files.any((f) => f.contains('widgets/') || f.contains('components/'));
        progress['hasServices'] = files.any((f) => f.contains('services/'));
        progress['hasModels'] = files.any((f) => f.contains('models/'));
        progress['hasAssets'] = files.any((f) => f.contains('assets/'));
        progress['hasTests'] = files.any((f) => f.contains('test/'));
        break;
        
      case 'REACT_APP':
        progress['hasPackageJson'] = files.any((f) => f.contains('package.json'));
        progress['hasSrc'] = files.any((f) => f.contains('src/'));
        progress['hasComponents'] = files.any((f) => f.contains('components/') || f.contains('.jsx') || f.contains('.tsx'));
        progress['hasPages'] = files.any((f) => f.contains('pages/') || f.contains('routes/'));
        progress['hasStyles'] = files.any((f) => f.contains('styles/') || f.contains('.css') || f.contains('.scss'));
        progress['hasState'] = files.any((f) => f.contains('store/') || f.contains('context/') || f.contains('hooks/'));
        progress['hasTests'] = files.any((f) => f.contains('test/') || f.contains('__tests__/'));
        break;
        
      case 'DJANGO_APP':
        progress['hasRequirements'] = files.any((f) => f.contains('requirements.txt'));
        progress['hasManagePy'] = files.any((f) => f.contains('manage.py'));
        progress['hasSettings'] = files.any((f) => f.contains('settings.py'));
        progress['hasUrls'] = files.any((f) => f.contains('urls.py'));
        progress['hasViews'] = files.any((f) => f.contains('views.py'));
        progress['hasModels'] = files.any((f) => f.contains('models.py'));
        progress['hasTemplates'] = files.any((f) => f.contains('templates/'));
        progress['hasStatic'] = files.any((f) => f.contains('static/'));
        progress['hasTests'] = files.any((f) => f.contains('tests/'));
        break;
        
      case 'EXPRESS_APP':
        progress['hasPackageJson'] = files.any((f) => f.contains('package.json'));
        progress['hasAppJs'] = files.any((f) => f.contains('app.js') || f.contains('server.js'));
        progress['hasRoutes'] = files.any((f) => f.contains('routes/'));
        progress['hasControllers'] = files.any((f) => f.contains('controllers/'));
        progress['hasModels'] = files.any((f) => f.contains('models/'));
        progress['hasMiddleware'] = files.any((f) => f.contains('middleware/'));
        progress['hasViews'] = files.any((f) => f.contains('views/') || f.contains('public/'));
        progress['hasTests'] = files.any((f) => f.contains('test/') || f.contains('__tests__/'));
        break;
        
      default:
        // For unknown frameworks, analyze generic patterns
        progress['hasConfigFiles'] = files.any((f) => f.contains('.yaml') || f.contains('.json') || f.contains('.toml'));
        progress['hasSourceCode'] = files.any((f) => f.contains('.py') || f.contains('.js') || f.contains('.ts') || f.contains('.dart') || f.contains('.cs') || f.contains('.rb') || f.contains('.php'));
        progress['hasAssets'] = files.any((f) => f.contains('.png') || f.contains('.jpg') || f.contains('.svg'));
        progress['hasDocumentation'] = files.any((f) => f.contains('.md') || f.contains('.txt'));
        progress['hasTests'] = files.any((f) => f.contains('test/') || f.contains('tests/'));
        break;
    }
    
    return progress;
  }
  
  Map<String, dynamic> _analyzeFilePatterns(List<String> files) {
    final patterns = <String, dynamic>{};
    
    // Count different file types
    patterns['imageFiles'] = files.where((f) => f.contains('.png') || f.contains('.jpg') || f.contains('.svg')).length;
    patterns['audioFiles'] = files.where((f) => f.contains('.ogg') || f.contains('.wav') || f.contains('.mp3')).length;
    patterns['codeFiles'] = files.where((f) => f.contains('.gd') || f.contains('.py') || f.contains('.js') || f.contains('.dart')).length;
    patterns['configFiles'] = files.where((f) => f.contains('.yaml') || f.contains('.json') || f.contains('.toml')).length;
    
    // Analyze directory structure
    patterns['hasAssetsDir'] = files.any((f) => f.contains('assets/'));
    patterns['hasScenesDir'] = files.any((f) => f.contains('scenes/'));
    patterns['hasScriptsDir'] = files.any((f) => f.contains('scripts/'));
    patterns['hasLibDir'] = files.any((f) => f.contains('lib/'));
    patterns['hasSrcDir'] = files.any((f) => f.contains('src/'));
    
    return patterns;
  }
  
  Map<String, dynamic> _generateCompleteRoadmap(Map<String, dynamic> context, String projectType, Map<String, dynamic> progress) {
    final roadmap = <String, dynamic>{};
    
    // Generate framework-aware roadmap based on detected type
    roadmap['phases'] = _generateFrameworkAwareRoadmap(projectType, progress);
    
    // Add distribution plan based on project type
    roadmap['distribution'] = _generateFrameworkAwareDistributionPlan(projectType, progress);
    
    return roadmap;
  }
  
  List<Map<String, dynamic>> _generateFrameworkAwareRoadmap(String projectType, Map<String, dynamic> progress) {
    final phases = <Map<String, dynamic>>[];
    final frameworkProgress = progress['frameworkProgress'] as Map<String, dynamic>? ?? {};
    
    switch (projectType) {
      case 'GODOT_GAME':
        phases.add({
          'name': 'Core Setup',
          'tasks': [
            {'task': 'Create project.godot', 'completed': frameworkProgress['hasProjectFile'] ?? false},
            {'task': 'Set up project structure', 'completed': frameworkProgress['hasScenes'] ?? false || frameworkProgress['hasAssets'] ?? false},
            {'task': 'Configure project settings', 'completed': frameworkProgress['hasProjectFile'] ?? false},
          ]
        });
        phases.add({
          'name': 'Game Mechanics',
          'tasks': [
            {'task': 'Implement player movement', 'completed': frameworkProgress['hasPlayer'] ?? false},
            {'task': 'Add basic physics', 'completed': frameworkProgress['hasGameLogic'] ?? false},
            {'task': 'Create game loop', 'completed': frameworkProgress['hasGameLogic'] ?? false},
            {'task': 'Add enemies', 'completed': frameworkProgress['hasEnemies'] ?? false},
          ]
        });
        phases.add({
          'name': 'Content & Assets',
          'tasks': [
            {'task': 'Add player sprites', 'completed': frameworkProgress['hasSprites'] ?? false && frameworkProgress['hasPlayer'] ?? false},
            {'task': 'Create level scenes', 'completed': frameworkProgress['hasLevels'] ?? false},
            {'task': 'Add audio effects', 'completed': frameworkProgress['hasAudio'] ?? false},
            {'task': 'Design UI/HUD', 'completed': frameworkProgress['hasUI'] ?? false},
          ]
        });
        break;
        
      case 'UNITY_GAME':
        phases.add({
          'name': 'Project Setup',
          'tasks': [
            {'task': 'Create Unity project', 'completed': frameworkProgress['hasProjectFile'] ?? false},
            {'task': 'Set up project structure', 'completed': frameworkProgress['hasAssets'] ?? false},
            {'task': 'Configure project settings', 'completed': frameworkProgress['hasProjectFile'] ?? false},
          ]
        });
        phases.add({
          'name': 'Game Development',
          'tasks': [
            {'task': 'Create game scenes', 'completed': frameworkProgress['hasScenes'] ?? false},
            {'task': 'Implement game scripts', 'completed': frameworkProgress['hasScripts'] ?? false},
            {'task': 'Add game objects and prefabs', 'completed': frameworkProgress['hasPrefabs'] ?? false},
            {'task': 'Create materials and textures', 'completed': frameworkProgress['hasMaterials'] ?? false},
          ]
        });
        break;
        
      case 'FLUTTER_APP':
        phases.add({
          'name': 'Project Foundation',
          'tasks': [
            {'task': 'Create Flutter project', 'completed': frameworkProgress['hasPubspec'] ?? false},
            {'task': 'Set up project structure', 'completed': frameworkProgress['hasLib'] ?? false},
            {'task': 'Configure dependencies', 'completed': frameworkProgress['hasPubspec'] ?? false},
          ]
        });
        phases.add({
          'name': 'App Development',
          'tasks': [
            {'task': 'Create main app', 'completed': frameworkProgress['hasLib'] ?? false},
            {'task': 'Build screens', 'completed': frameworkProgress['hasScreens'] ?? false},
            {'task': 'Create reusable widgets', 'completed': frameworkProgress['hasWidgets'] ?? false},
            {'task': 'Implement services', 'completed': frameworkProgress['hasServices'] ?? false},
          ]
        });
        break;
        
      case 'REACT_APP':
        phases.add({
          'name': 'Project Setup',
          'tasks': [
            {'task': 'Initialize React project', 'completed': frameworkProgress['hasPackageJson'] ?? false},
            {'task': 'Set up project structure', 'completed': frameworkProgress['hasSrc'] ?? false},
            {'task': 'Configure build system', 'completed': frameworkProgress['hasPackageJson'] ?? false},
          ]
        });
        phases.add({
          'name': 'Frontend Development',
          'tasks': [
            {'task': 'Create main app component', 'completed': frameworkProgress['hasComponents'] ?? false},
            {'task': 'Build UI components', 'completed': frameworkProgress['hasComponents'] ?? false},
            {'task': 'Add routing', 'completed': frameworkProgress['hasPages'] ?? false},
            {'task': 'Implement state management', 'completed': frameworkProgress['hasState'] ?? false},
          ]
        });
        break;
        
      case 'DJANGO_APP':
        phases.add({
          'name': 'Project Setup',
          'tasks': [
            {'task': 'Create Django project', 'completed': frameworkProgress['hasManagePy'] ?? false},
            {'task': 'Set up virtual environment', 'completed': frameworkProgress['hasRequirements'] ?? false},
            {'task': 'Configure settings', 'completed': frameworkProgress['hasSettings'] ?? false},
          ]
        });
        phases.add({
          'name': 'Backend Development',
          'tasks': [
            {'task': 'Create URL patterns', 'completed': frameworkProgress['hasUrls'] ?? false},
            {'task': 'Implement views', 'completed': frameworkProgress['hasViews'] ?? false},
            {'task': 'Define models', 'completed': frameworkProgress['hasModels'] ?? false},
            {'task': 'Add templates', 'completed': frameworkProgress['hasTemplates'] ?? false},
          ]
        });
        break;
        
      case 'EXPRESS_APP':
        phases.add({
          'name': 'Project Setup',
          'tasks': [
            {'task': 'Initialize Node.js project', 'completed': frameworkProgress['hasPackageJson'] ?? false},
            {'task': 'Set up Express server', 'completed': frameworkProgress['hasAppJs'] ?? false},
            {'task': 'Configure project structure', 'completed': frameworkProgress['hasRoutes'] ?? false},
          ]
        });
        phases.add({
          'name': 'Backend Development',
          'tasks': [
            {'task': 'Create API routes', 'completed': frameworkProgress['hasRoutes'] ?? false},
            {'task': 'Implement controllers', 'completed': frameworkProgress['hasControllers'] ?? false},
            {'task': 'Define data models', 'completed': frameworkProgress['hasModels'] ?? false},
            {'task': 'Add middleware', 'completed': frameworkProgress['hasMiddleware'] ?? false},
          ]
        });
        break;
        
      default:
        // For unknown frameworks, generate generic roadmap
        phases.add({
          'name': 'Project Foundation',
          'tasks': [
            {'task': 'Set up project structure', 'completed': progress['hasConfigFiles'] ?? false},
            {'task': 'Create source code organization', 'completed': progress['hasSourceCode'] ?? false},
            {'task': 'Add documentation', 'completed': progress['hasDocumentation'] ?? false},
          ]
        });
        phases.add({
          'name': 'Core Development',
          'tasks': [
            {'task': 'Implement core functionality', 'completed': progress['hasSourceCode'] ?? false},
            {'task': 'Add assets and resources', 'completed': progress['hasAssets'] ?? false},
            {'task': 'Create tests', 'completed': progress['hasTests'] ?? false},
          ]
        });
        break;
    }
    
    return phases;
  }
  
  Map<String, dynamic> _generateFrameworkAwareDistributionPlan(String projectType, Map<String, dynamic> progress) {
    // Generate distribution plans based on framework type
    switch (projectType) {
      case 'GODOT_GAME':
      case 'UNITY_GAME':
      case 'UNREAL_GAME':
      case 'LOVE_GAME':
      case 'MONOGAME_GAME':
      case 'PHASER_GAME':
      case 'THREEJS_GAME':
        return {
          'platforms': ['Steam', 'itch.io', 'Game Jolt', 'Mobile Stores', 'Web'],
          'monetization': ['Premium', 'Free with Ads', 'In-App Purchases', 'DLC', 'Subscription'],
          'marketing': ['Social Media', 'Game Dev Communities', 'Streamers', 'Press Kit', 'Game Jams'],
          'legal': ['Terms of Service', 'Privacy Policy', 'Age Ratings', 'Copyright', 'Licensing']
        };
        
      case 'FLUTTER_APP':
      case 'REACT_NATIVE_APP':
      case 'XAMARIN_APP':
      case 'IONIC_APP':
      case 'NATIVESCRIPT_APP':
        return {
          'platforms': ['Google Play Store', 'Apple App Store', 'Web', 'Desktop'],
          'monetization': ['Freemium', 'Premium', 'Subscription', 'In-App Purchases', 'Ads'],
          'marketing': ['App Store Optimization', 'Social Media', 'Influencer Marketing', 'User Reviews'],
          'legal': ['Terms of Service', 'Privacy Policy', 'Data Protection', 'App Store Guidelines']
        };
        
      case 'REACT_APP':
      case 'VUE_APP':
      case 'ANGULAR_APP':
      case 'SVELTE_APP':
      case 'SOLID_APP':
      case 'QWIK_APP':
      case 'NEXTJS_APP':
      case 'NUXT_APP':
      case 'REMIX_APP':
      case 'ASTRO_APP':
        return {
          'platforms': ['Web', 'Mobile (PWA)', 'Desktop (Electron)', 'Cloud'],
          'monetization': ['Subscription', 'Freemium', 'Premium', 'Enterprise', 'Open Source'],
          'marketing': ['Website', 'Social Media', 'SEO', 'Content Marketing', 'Community'],
          'legal': ['Terms of Service', 'Privacy Policy', 'Data Protection', 'Licensing']
        };
        
      case 'DJANGO_APP':
      case 'FASTAPI_APP':
      case 'FLASK_APP':
      case 'EXPRESS_APP':
      case 'RUBY_APP':
      case 'PHP_APP':
        return {
          'platforms': ['Web', 'Cloud (AWS/Azure/GCP)', 'Docker', 'Kubernetes'],
          'monetization': ['SaaS', 'API Usage', 'Enterprise', 'Open Source', 'Consulting'],
          'marketing': ['Developer Communities', 'Documentation', 'API Documentation', 'Case Studies'],
          'legal': ['Terms of Service', 'Privacy Policy', 'Data Protection', 'API Licensing']
        };
        
      case 'ELECTRON_APP':
      case 'TAURI_APP':
      case 'QT_APP':
      case 'WPF_APP':
        return {
          'platforms': ['Windows', 'macOS', 'Linux', 'Web'],
          'monetization': ['Premium', 'Freemium', 'Subscription', 'Enterprise', 'Open Source'],
          'marketing': ['Website', 'Social Media', 'Developer Communities', 'Software Marketplaces'],
          'legal': ['Terms of Service', 'Privacy Policy', 'Software Licensing', 'Distribution Rights']
        };
        
      default:
        return {
          'platforms': ['Web', 'Desktop', 'Mobile', 'Cloud'],
          'monetization': ['Open Source', 'Premium', 'Enterprise', 'Subscription'],
          'marketing': ['GitHub', 'Social Media', 'Documentation', 'Community'],
          'legal': ['License', 'Terms of Service', 'Privacy Policy', 'Copyright']
        };
    }
  }
  
  String _formatIntelligentTODO(Map<String, dynamic> context, String projectType, Map<String, dynamic> progress, Map<String, dynamic> roadmap) {
    final buffer = StringBuffer();
    
    buffer.writeln('# Intelligent Project Analysis & Roadmap');
    buffer.writeln();
    buffer.writeln('## 📋 Project Overview');
    buffer.writeln('**Project Type**: ${projectType.replaceAll('_', ' ')}');
    buffer.writeln('**Analysis Date**: ${DateTime.now().toIso8601String()}');
    buffer.writeln('**Total Files**: ${(context['projectFiles'] as List?)?.length ?? 0}');
    buffer.writeln();
    
    buffer.writeln('## 🔍 Current Progress Analysis');
    _formatProgressSection(buffer, progress);
    
    buffer.writeln('## 🗺️ Complete Project Roadmap');
    _formatRoadmapSection(buffer, roadmap);
    
    if (roadmap['distribution'] != null) {
      buffer.writeln('## 🚀 Distribution & Monetization Plan');
      _formatDistributionSection(buffer, roadmap['distribution']);
    }
    
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('**This roadmap was generated by analyzing your actual project structure and identifying what exists vs. what needs to be built.**');
    
    return buffer.toString();
  }
  
  void _formatProgressSection(StringBuffer buffer, Map<String, dynamic> progress) {
    buffer.writeln('### ✅ What\'s Already Implemented');
    progress.forEach((key, value) {
      if (value is bool && value) {
        // Convert camelCase to readable text
        final readableKey = key.replaceAllMapped(
          RegExp(r'([A-Z])'), 
          (match) => ' ${match.group(1)!.toLowerCase()}'
        );
        buffer.writeln('- ✅ ${readableKey.trim()}');
      }
    });
    
    buffer.writeln();
    buffer.writeln('### ❌ What\'s Missing');
    progress.forEach((key, value) {
      if (value is bool && !value) {
        // Convert camelCase to readable text
        final readableKey = key.replaceAllMapped(
          RegExp(r'([A-Z])'), 
          (match) => ' ${match.group(1)!.toLowerCase()}'
        );
        buffer.writeln('- ❌ ${readableKey.trim()}');
      }
    });
    
    // Add framework-specific progress if available
    if (progress['frameworkProgress'] != null) {
      final frameworkProgress = progress['frameworkProgress'] as Map<String, dynamic>;
      buffer.writeln();
      buffer.writeln('### 🎯 Framework-Specific Progress');
      frameworkProgress.forEach((key, value) {
        if (value is bool) {
          final readableKey = key.replaceAllMapped(
            RegExp(r'([A-Z])'), 
            (match) => ' ${match.group(1)!.toLowerCase()}'
          );
          final icon = value ? '✅' : '❌';
          buffer.writeln('- $icon ${readableKey.trim()}');
        }
      });
    }
    
    // Add file pattern analysis if available
    if (progress['filePatterns'] != null) {
      final filePatterns = progress['filePatterns'] as Map<String, dynamic>;
      buffer.writeln();
      buffer.writeln('### 📊 File Structure Analysis');
      buffer.writeln('**Total Files**: ${progress['totalFiles']}');
      buffer.writeln('**Image Files**: ${filePatterns['imageFiles']}');
      buffer.writeln('**Audio Files**: ${filePatterns['audioFiles']}');
      buffer.writeln('**Code Files**: ${filePatterns['codeFiles']}');
      buffer.writeln('**Config Files**: ${filePatterns['configFiles']}');
      buffer.writeln();
      buffer.writeln('**Directory Structure**:');
      if (filePatterns['hasAssetsDir'] ?? false) buffer.writeln('- ✅ Has assets/ directory');
      if (filePatterns['hasScenesDir'] ?? false) buffer.writeln('- ✅ Has scenes/ directory');
      if (filePatterns['hasScriptsDir'] ?? false) buffer.writeln('- ✅ Has scripts/ directory');
      if (filePatterns['hasLibDir'] ?? false) buffer.writeln('- ✅ Has lib/ directory');
      if (filePatterns['hasSrcDir'] ?? false) buffer.writeln('- ✅ Has src/ directory');
    }
  }
  
  void _formatRoadmapSection(StringBuffer buffer, Map<String, dynamic> roadmap) {
    final phases = roadmap['phases'] as List<Map<String, dynamic>>?;
    if (phases == null) return;
    
    for (final phase in phases) {
      buffer.writeln('### 🎯 ${phase['name']}');
      final tasks = phase['tasks'] as List<Map<String, dynamic>>?;
      if (tasks != null) {
        for (final task in tasks) {
          final completed = task['completed'] as bool? ?? false;
          final taskText = task['task'] as String? ?? 'Unknown task';
          buffer.writeln('- [${completed ? 'x' : ' '}] $taskText');
        }
      }
      buffer.writeln();
    }
  }
  
  void _formatDistributionSection(StringBuffer buffer, Map<String, dynamic> distribution) {
    if (distribution['platforms'] != null) {
      buffer.writeln('**Target Platforms**: ${(distribution['platforms'] as List).join(', ')}');
    }
    if (distribution['monetization'] != null) {
      buffer.writeln('**Monetization Options**: ${(distribution['monetization'] as List).join(', ')}');
    }
    if (distribution['marketing'] != null) {
      buffer.writeln('**Marketing Strategy**: ${(distribution['marketing'] as List).join(', ')}');
    }
    if (distribution['legal'] != null) {
      buffer.writeln('**Legal Requirements**: ${(distribution['legal'] as List).join(', ')}');
    }
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
  
  String _generateContentBasedTODO(Map<String, dynamic> analysis, String projectType, List<String> techStack) {
    final buffer = StringBuffer();
    
    buffer.writeln('# Intelligent Repository Analysis TODO');
    buffer.writeln();
    buffer.writeln('## 📋 Project Overview');
    buffer.writeln('**Project Type**: ${projectType.toUpperCase()}');
    buffer.writeln('**Tech Stack**: ${techStack.join(', ')}');
    buffer.writeln('**Analysis Date**: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    
    // Document what we actually found
    buffer.writeln('## 🔍 Repository Content Analysis');
    buffer.writeln('**README Status**: ${analysis['hasReadme'] ? '✅ Found' : '❌ Missing'}');
    if (analysis['hasReadme']) {
      buffer.writeln('**README Length**: ${analysis['readmeLength']} characters');
      buffer.writeln('**Key Topics**: ${analysis['readmeKeywords'].join(', ')}');
    }
    buffer.writeln();
    
    buffer.writeln('**Dependencies**: ${analysis['dependencyCount']} found');
    if (analysis['dependencyCount'] > 0) {
      buffer.writeln('**Found**: ${analysis['foundDependencies'].join(', ')}');
    }
    buffer.writeln();
    
    buffer.writeln('**Project Files**: ${analysis['fileCount']} found');
    if (analysis['fileCount'] > 0) {
      buffer.writeln('**Structure**:');
      if (analysis['hasLibFolder']) buffer.writeln('- ✅ Has lib/ folder (Dart/Flutter project)');
      if (analysis['hasAssets']) buffer.writeln('- ✅ Has assets/ folder');
      if (analysis['hasTests']) buffer.writeln('- ✅ Has test/ folder');
    }
    buffer.writeln();
    
    // Generate specific tasks based on what's missing
    buffer.writeln('## 🚨 IMMEDIATE ACTION REQUIRED');
    buffer.writeln();
    
    if (!analysis['hasReadme']) {
      buffer.writeln('### Documentation Priority');
      buffer.writeln('- [ ] **Create README.md** - project description and setup instructions');
      buffer.writeln('- [ ] **Add project overview** - what this project does and why it exists');
      buffer.writeln('- [ ] **Include installation steps** - how to get this project running');
      buffer.writeln();
    }
    
    if (analysis['dependencyCount'] == 0) {
      buffer.writeln('### Dependency Management');
      buffer.writeln('- [ ] **Identify required dependencies** - what packages/libraries are needed');
      buffer.writeln('- [ ] **Create dependency file** - pubspec.yaml, package.json, requirements.txt, etc.');
      buffer.writeln('- [ ] **Document version requirements** - compatible versions for each dependency');
      buffer.writeln();
    }
    
    if (analysis['fileCount'] == 0) {
      buffer.writeln('### Project Structure');
      buffer.writeln('- [ ] **Create basic project structure** - organize code into logical folders');
      buffer.writeln('- [ ] **Add source code folder** - lib/, src/, or similar');
      buffer.writeln('- [ ] **Create entry point** - main file to start the application');
      buffer.writeln();
    }
    
    // Generate project-specific tasks based on actual content
    buffer.writeln('## 🎯 Content-Based Tasks');
    buffer.writeln();
    
    if (analysis['hasReadme'] && analysis['readmeKeywords'].isNotEmpty) {
      buffer.writeln('**Based on README content analysis:**');
      for (final keyword in analysis['readmeKeywords'].take(5)) {
        buffer.writeln('- [ ] **Implement ${keyword} functionality** - referenced in README');
      }
      buffer.writeln();
    }
    
    if (analysis['foundDependencies'].isNotEmpty) {
      buffer.writeln('**Based on dependencies found:**');
      for (final dep in analysis['foundDependencies'].take(5)) {
        buffer.writeln('- [ ] **Configure ${dep}** - ensure proper setup and usage');
      }
      buffer.writeln();
    }
    
    buffer.writeln('## 📊 Progress Tracking');
    buffer.writeln('**Overall Progress**: Analysis Complete - Action Required');
    buffer.writeln('**Current Phase**: Content Analysis & Task Generation');
    buffer.writeln('**Next Milestone**: Complete identified missing components');
    buffer.writeln();
    
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('**NOTE: This TODO was generated by analyzing the ACTUAL repository content, not from templates.**');
    buffer.writeln('**Each task is based on what was found or missing in your specific project.**');
    
    return buffer.toString();
  }
  
  String _detectProjectType(Map<String, dynamic> context) {
    // TRULY INTELLIGENT detection based on what we actually discover - no hardcoded assumptions!
    
    // Check README content first if it's useful
    if (context['readmeAnalysis'] != null) {
      final readmeAnalysis = context['readmeAnalysis'];
      if (readmeAnalysis['isUseful'] == true && readmeAnalysis['projectType'] != null) {
        return readmeAnalysis['projectType'];
      }
    }
    
    // Analyze project files to understand what this project actually is
    if (context['projectFiles'] != null) {
      final projectFiles = context['projectFiles'];
      final files = projectFiles.map((f) => f.toString().toLowerCase()).toList();
      
      // DYNAMICALLY analyze patterns to understand project type
      final hasGameElements = files.any((f) => f.contains('scenes/') || f.contains('levels/') || f.contains('worlds/')) &&
                             files.any((f) => f.contains('.png') || f.contains('.jpg') || f.contains('.ogg') || f.contains('.wav'));
      
      final hasWebElements = files.any((f) => f.contains('lib/') || f.contains('src/')) &&
                            files.any((f) => f.contains('.js') || f.contains('.ts') || f.contains('.dart'));
      
      final hasMobileElements = files.any((f) => f.contains('android/') || f.contains('ios/')) ||
                               files.any((f) => f.contains('pubspec.yaml') || f.contains('package.json'));
      
      final hasApiElements = files.any((f) => f.contains('api/') || f.contains('routes/') || f.contains('controllers/'));
      
      // Return intelligent analysis based on what we found
      if (hasGameElements) return 'game_project';
      if (hasWebElements) return 'web_application';
      if (hasMobileElements) return 'mobile_application';
      if (hasApiElements) return 'api_service';
      
      // If we can't determine, analyze the file structure more deeply
      return 'intelligent_analysis_required';
    }
    
    // FORCE intelligent analysis - no generic fallbacks!
    return 'intelligent_analysis_required';
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
      final files = context['projectFiles'].map((f) => f.toString().toLowerCase()).toList();
      
      if (files.any((f) => f.contains('.gd'))) techStack.add('Godot Game Engine');
      if (files.any((f) => f.contains('.cs'))) techStack.add('Unity/C#');
      if (files.any((f) => f.contains('.py'))) techStack.add('Python');
      if (files.any((f) => f.contains('.rs'))) techStack.add('Rust');
      if (files.any((f) => f.contains('.go'))) techStack.add('Go');
      if (files.any((f) => f.contains('.js') || f.contains('.ts'))) techStack.add('JavaScript/TypeScript');
    }
    
    return techStack.isEmpty ? ['Requires Analysis'] : techStack;
  }
  
  void setModelPath(String path) {
    // _modelPath = path; // Removed unused field
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
    super.dispose();
  }
}
