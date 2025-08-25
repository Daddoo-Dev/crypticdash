import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/github_repository.dart';
import 'gist_service.dart';

class ProjectSelectionService extends ChangeNotifier {
  static const String _selectedProjectsKey = 'selected_projects';
  static const String _hasCompletedSetupKey = 'has_completed_setup';
  static const String _lastSetupDateKey = 'last_setup_date';
  static const String _lastGistSyncKey = 'last_gist_sync';
  
  Set<int> _selectedProjectIds = {};
  bool _hasCompletedSetup = false;
  DateTime? _lastSetupDate;
  DateTime? _lastGistSync;
  VoidCallback? _onSelectionChanged;
  GistService? _gistService;
  bool _isGistEnabled = false;
  
  Set<int> get selectedProjectIds => _selectedProjectIds;
  bool get hasCompletedSetup => _hasCompletedSetup;
  DateTime? get lastSetupDate => _lastSetupDate;
  DateTime? get lastGistSync => _lastGistSync;
  bool get isGistEnabled => _isGistEnabled;
  
  ProjectSelectionService() {
    _loadSettings();
  }
  
  /// Test method to manually trigger the callback
  void testCallback() {
    debugPrint('ProjectSelectionService: Testing callback manually');
    if (_onSelectionChanged != null) {
      debugPrint('ProjectSelectionService: Calling test callback');
      _onSelectionChanged?.call();
      debugPrint('ProjectSelectionService: Test callback completed');
    } else {
      debugPrint('ProjectSelectionService: ERROR - No callback available for test');
    }
  }
  
  void setOnSelectionChangedCallback(VoidCallback callback) {
    debugPrint('ProjectSelectionService: setOnSelectionChangedCallback called');
    _onSelectionChanged = callback;
    debugPrint('ProjectSelectionService: Callback set to: valid callback');
  }
  
  /// Initialize Gist service for cross-device sync
  Future<void> initializeGistService(String githubToken, String username) async {
    try {
      _gistService = GistService(githubToken);
      _isGistEnabled = true;
      
      // Try to sync from Gist on initialization
      await _syncFromGist();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize Gist service: $e');
      _isGistEnabled = false;
    }
  }
  
  /// Sync repository selections from Gist
  Future<void> _syncFromGist() async {
    if (_gistService == null || !_isGistEnabled) return;
    
    try {
      final preferences = await _gistService!.getPreferences();
      if (preferences != null && preferences.containsKey('selectedRepos')) {
        final selectedRepoNames = List<String>.from(preferences['selectedRepos'] ?? []);
        
        // Convert repository names to IDs (we'll need to get this from the repository list)
        // For now, we'll store the names and match them later
        await _loadSettings(); // Load local settings first
        
        // If we have Gist data and it's newer than local, use it
        final gistLastUpdated = preferences['lastUpdated'];
        if (gistLastUpdated != null) {
          final gistDate = DateTime.tryParse(gistLastUpdated);
          if (gistDate != null && (_lastGistSync == null || gistDate.isAfter(_lastGistSync!))) {
            // Gist data is newer, update local storage
            await _updateLocalSelectionsFromGist(selectedRepoNames);
            _lastGistSync = gistDate;
            await _saveSettings();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to sync from Gist: $e');
    }
  }
  
  /// Update local selections based on Gist data
  Future<void> _updateLocalSelectionsFromGist(List<String> selectedRepoNames) async {
    // This is a simplified approach - in a real implementation,
    // you'd want to match by repository name or full name
    // For now, we'll just store the names and handle matching later
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('gist_selected_repos', selectedRepoNames);
  }
  
  /// Sync current selections to Gist
  Future<void> _syncToGist() async {
    if (_gistService == null || !_isGistEnabled) return;
    
    try {
      final preferences = {
        'selectedRepos': _selectedProjectIds.toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      final success = await _gistService!.createOrUpdatePreferencesGist(preferences);
      if (success) {
        _lastGistSync = DateTime.now();
        await _saveSettings();
        debugPrint('Successfully synced selections to Gist');
      } else {
        debugPrint('Failed to sync selections to Gist');
      }
    } catch (e) {
      debugPrint('Error syncing to Gist: $e');
    }
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedIds = prefs.getStringList(_selectedProjectsKey) ?? [];
      final hasSetup = prefs.getBool(_hasCompletedSetupKey) ?? false;
      final lastSetupString = prefs.getString(_lastSetupDateKey);
      final lastGistSyncString = prefs.getString(_lastGistSyncKey);
      
      _selectedProjectIds = selectedIds.map((id) => int.parse(id)).toSet();
      _hasCompletedSetup = hasSetup;
      _lastSetupDate = lastSetupString != null ? DateTime.tryParse(lastSetupString) : null;
      _lastGistSync = lastGistSyncString != null ? DateTime.tryParse(lastGistSyncString) : null;
      notifyListeners();
    } catch (e) {
      // Handle error silently, use defaults
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringIds = _selectedProjectIds.map((id) => id.toString()).toList();
      await prefs.setStringList(_selectedProjectsKey, stringIds);
      await prefs.setBool(_hasCompletedSetupKey, _hasCompletedSetup);
      if (_lastSetupDate != null) {
        await prefs.setString(_lastSetupDateKey, _lastSetupDate!.toIso8601String());
      }
      if (_lastGistSync != null) {
        await prefs.setString(_lastGistSyncKey, _lastGistSync!.toIso8601String());
      }
      
      debugPrint('ProjectSelectionService: Local settings saved successfully');
      debugPrint('ProjectSelectionService: Selected IDs: $stringIds');
      
      // Sync to Gist if enabled (but don't fail if this doesn't work)
      if (_isGistEnabled) {
        try {
          await _syncToGist();
        } catch (e) {
          debugPrint('Gist sync failed, but local storage succeeded: $e');
          // Don't let Gist failure break local storage
        }
      }
      
      // Notify other services that selection has changed
      if (_onSelectionChanged != null) {
        debugPrint('ProjectSelectionService: Calling selection changed callback');
        _onSelectionChanged?.call();
      } else {
        debugPrint('ProjectSelectionService: No selection changed callback set');
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      rethrow;
    }
  }
  
  bool isProjectSelected(int projectId) {
    return _selectedProjectIds.contains(projectId);
  }
  
  Future<void> toggleProjectSelection(int projectId) async {
    debugPrint('ProjectSelectionService: toggleProjectSelection called for ID: $projectId');
    debugPrint('ProjectSelectionService: Current selections before toggle: $_selectedProjectIds');
    
    if (_selectedProjectIds.contains(projectId)) {
      _selectedProjectIds.remove(projectId);
      debugPrint('ProjectSelectionService: Removed project $projectId from selections');
    } else {
      // Check if this repository is already selected
      if (_selectedProjectIds.contains(projectId)) {
        debugPrint('ProjectSelectionService: Repository $projectId is already selected, ignoring duplicate');
        return; // Don't add duplicates
      }
      _selectedProjectIds.add(projectId);
      debugPrint('ProjectSelectionService: Added project $projectId to selections');
    }
    
    debugPrint('ProjectSelectionService: Selections after toggle: $_selectedProjectIds');
    debugPrint('ProjectSelectionService: About to call notifyListeners()');
    notifyListeners();
    debugPrint('ProjectSelectionService: About to call _saveSettings()');
    await _saveSettings();
    
    debugPrint('ProjectSelectionService: Settings saved, notifying listeners');
    debugPrint('ProjectSelectionService: _onSelectionChanged callback exists: ${_onSelectionChanged != null}');
    if (_onSelectionChanged != null) {
      debugPrint('ProjectSelectionService: About to call _onSelectionChanged callback');
      _onSelectionChanged?.call();
      debugPrint('ProjectSelectionService: _onSelectionChanged callback completed');
    } else {
      debugPrint('ProjectSelectionService: WARNING - No selection changed callback set!');
    }
  }
  
  Future<void> selectAllProjects(List<GitHubRepository> repositories) async {
    _selectedProjectIds = repositories.map((repo) => repo.id).toSet();
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> deselectAllProjects() async {
    _selectedProjectIds.clear();
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> selectProjects(List<int> projectIds) async {
    _selectedProjectIds = projectIds.toSet();
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> markSetupComplete() async {
    _hasCompletedSetup = true;
    _lastSetupDate = DateTime.now();
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> resetSetup() async {
    _hasCompletedSetup = false;
    _lastSetupDate = null;
    _selectedProjectIds.clear();
    notifyListeners();
    await _saveSettings();
  }
  
  /// Force sync with Gist
  Future<void> forceGistSync() async {
    if (_isGistEnabled) {
      await _syncToGist();
    }
  }
  
  /// Disable Gist sync
  Future<void> disableGistSync() async {
    _isGistEnabled = false;
    _gistService = null;
    notifyListeners();
  }
  
  /// Enable Gist sync (re-initialize the service)
  Future<void> enableGistSync() async {
    try {
      // Get the GitHub token and username from the existing service
      // This will be called from the UI when user enables sync
      if (_gistService != null) {
        _isGistEnabled = true;
        notifyListeners();
        return;
      }
      
      // If no service exists, we need to initialize it
      // This will be handled by the ProjectService when it's available
      _isGistEnabled = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to enable Gist sync: $e');
      _isGistEnabled = false;
    }
  }
  
  // New method to check if user should see setup screen
  bool shouldShowSetupScreen() {
    return !_hasCompletedSetup || _selectedProjectIds.isEmpty;
  }
  
  // New method to check if user has any projects selected
  bool hasAnyProjectsSelected() {
    return _selectedProjectIds.isNotEmpty;
  }
  
  List<GitHubRepository> getFilteredRepositories(List<GitHubRepository> allRepositories) {
    return allRepositories.where((repo) => _selectedProjectIds.contains(repo.id)).toList();
  }
  
  int get selectedProjectCount => _selectedProjectIds.length;
  
  bool get hasSelectedProjects => _selectedProjectIds.isNotEmpty;
}
