import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/github_repository.dart';

class ProjectSelectionService extends ChangeNotifier {
  static const String _selectedProjectsKey = 'selected_projects';
  static const String _hasCompletedSetupKey = 'has_completed_setup';
  static const String _lastSetupDateKey = 'last_setup_date';
  
  Set<int> _selectedProjectIds = {};
  bool _hasCompletedSetup = false;
  DateTime? _lastSetupDate;
  VoidCallback? _onSelectionChanged;
  
  Set<int> get selectedProjectIds => _selectedProjectIds;
  bool get hasCompletedSetup => _hasCompletedSetup;
  DateTime? get lastSetupDate => _lastSetupDate;
  
  ProjectSelectionService() {
    _loadSettings();
  }
  
  void setOnSelectionChangedCallback(VoidCallback callback) {
    _onSelectionChanged = callback;
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedIds = prefs.getStringList(_selectedProjectsKey) ?? [];
      final hasSetup = prefs.getBool(_hasCompletedSetupKey) ?? false;
      final lastSetupString = prefs.getString(_lastSetupDateKey);
      
      _selectedProjectIds = selectedIds.map((id) => int.parse(id)).toSet();
      _hasCompletedSetup = hasSetup;
      _lastSetupDate = lastSetupString != null ? DateTime.tryParse(lastSetupString) : null;
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
      
      // Notify other services that selection has changed
      _onSelectionChanged?.call();
    } catch (e) {
      // Handle error silently
    }
  }
  
  bool isProjectSelected(int projectId) {
    return _selectedProjectIds.contains(projectId);
  }
  
  Future<void> toggleProjectSelection(int projectId) async {
    if (_selectedProjectIds.contains(projectId)) {
      _selectedProjectIds.remove(projectId);
    } else {
      _selectedProjectIds.add(projectId);
    }
    notifyListeners();
    await _saveSettings();
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
