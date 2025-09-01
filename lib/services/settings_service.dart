import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SettingsService extends ChangeNotifier {
  static const String _autoRefreshKey = 'auto_refresh_enabled';
  static const String _refreshIntervalKey = 'refresh_interval_minutes';
  static const String _showCompletedTodosKey = 'show_completed_todos';
  static const String _groupTodosBySectionKey = 'group_todos_by_section';
  static const String _enableNotificationsKey = 'enable_notifications';
  static const String _cacheProjectDataKey = 'cache_project_data';
  static const String _maxCacheSizeKey = 'max_cache_size_mb';
  static const String _lastSyncTimeKey = 'last_sync_time';

  // Default values
  bool _autoRefreshEnabled = true;
  int _refreshIntervalMinutes = 15;
  bool _showCompletedTodos = true;
  bool _groupTodosBySection = true;
  bool _enableNotifications = false;
  bool _cacheProjectData = true;
  int _maxCacheSizeMB = 100;
  DateTime? _lastSyncTime;

  // Getters
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  int get refreshIntervalMinutes => _refreshIntervalMinutes;
  bool get showCompletedTodos => _showCompletedTodos;
  bool get groupTodosBySection => _groupTodosBySection;
  bool get enableNotifications => _enableNotifications;
  bool get cacheProjectData => _cacheProjectData;
  int get maxCacheSizeMB => _maxCacheSizeMB;
  DateTime? get lastSyncTime => _lastSyncTime;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _autoRefreshEnabled = prefs.getBool(_autoRefreshKey) ?? true;
      _refreshIntervalMinutes = prefs.getInt(_refreshIntervalKey) ?? 15;
      _showCompletedTodos = prefs.getBool(_showCompletedTodosKey) ?? true;
      _groupTodosBySection = prefs.getBool(_groupTodosBySectionKey) ?? true;
      _enableNotifications = prefs.getBool(_enableNotificationsKey) ?? false;
      _cacheProjectData = prefs.getBool(_cacheProjectDataKey) ?? true;
      _maxCacheSizeMB = prefs.getInt(_maxCacheSizeKey) ?? 100;
      
      final lastSyncString = prefs.getString(_lastSyncTimeKey);
      _lastSyncTime = lastSyncString != null ? DateTime.tryParse(lastSyncString) : null;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // Use defaults if loading fails
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_autoRefreshKey, _autoRefreshEnabled);
      await prefs.setInt(_refreshIntervalKey, _refreshIntervalMinutes);
      await prefs.setBool(_showCompletedTodosKey, _showCompletedTodos);
      await prefs.setBool(_groupTodosBySectionKey, _groupTodosBySection);
      await prefs.setBool(_enableNotificationsKey, _enableNotifications);
      await prefs.setBool(_cacheProjectDataKey, _cacheProjectData);
      await prefs.setInt(_maxCacheSizeKey, _maxCacheSizeMB);
      
      if (_lastSyncTime != null) {
        await prefs.setString(_lastSyncTimeKey, _lastSyncTime!.toIso8601String());
      }
      
      debugPrint('Settings saved successfully');
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // Update methods
  Future<void> setAutoRefreshEnabled(bool value) async {
    if (_autoRefreshEnabled != value) {
      _autoRefreshEnabled = value;
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> setRefreshIntervalMinutes(int minutes) async {
    if (_refreshIntervalMinutes != minutes) {
      _refreshIntervalMinutes = minutes;
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> setShowCompletedTodos(bool value) async {
    if (_showCompletedTodos != value) {
      _showCompletedTodos = value;
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> setGroupTodosBySection(bool value) async {
    if (_groupTodosBySection != value) {
      _groupTodosBySection = value;
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> setEnableNotifications(bool value) async {
    if (_enableNotifications != value) {
      _enableNotifications = value;
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> setCacheProjectData(bool value) async {
    if (_cacheProjectData != value) {
      _cacheProjectData = value;
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> setMaxCacheSizeMB(int mb) async {
    if (_maxCacheSizeMB != mb) {
      _maxCacheSizeMB = mb;
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateLastSyncTime() async {
    _lastSyncTime = DateTime.now();
    await _saveSettings();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _autoRefreshEnabled = true;
    _refreshIntervalMinutes = 15;
    _showCompletedTodos = true;
    _groupTodosBySection = true;
    _enableNotifications = false;
    _cacheProjectData = true;
    _maxCacheSizeMB = 100;
    _lastSyncTime = null;
    
    await _saveSettings();
    notifyListeners();
  }

  // Utility methods
  String getFormattedLastSyncTime() {
    if (_lastSyncTime == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  String getFormattedDateTime(DateTime dateTime) {
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }

  String getFormattedDate(DateTime dateTime) {
    return DateFormat.yMMMd().format(dateTime);
  }

  String getFormattedTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }

  // Get all settings as a map for export
  Map<String, dynamic> getAllSettings() {
    return {
      'autoRefreshEnabled': _autoRefreshEnabled,
      'refreshIntervalMinutes': _refreshIntervalMinutes,
      'showCompletedTodos': _showCompletedTodos,
      'groupTodosBySection': _groupTodosBySection,
      'enableNotifications': _enableNotifications,
      'cacheProjectData': _cacheProjectData,
      'maxCacheSizeMB': _maxCacheSizeMB,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
    };
  }
}
