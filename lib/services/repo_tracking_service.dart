import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'github_service.dart';
import 'gist_service.dart';
import 'iap_service.dart';

/// Service for tracking repositories and enforcing subscription limits
/// Uses hybrid storage: local + GitHub Gist for cross-device protection
class RepoTrackingService extends ChangeNotifier {
  static const String _reposKey = 'tracked_repositories';
  static const String _gistIdKey = 'repo_tracking_gist_id';

  
  final GitHubService _githubService;
  final IAPService _iapService;
  
  // Local storage
  final Set<String> _trackedRepos = {};
  String? _gistId;
  
  // Getters
  Set<String> get trackedRepos => Set.unmodifiable(_trackedRepos);
  int get totalReposEverAdded => _trackedRepos.length;
  bool get isInitialized => _gistId != null;
  
  RepoTrackingService(this._githubService, this._iapService) {
    _loadStoredData();
    _iapService.addListener(_onIAPStatusChanged);
  }
  
  /// Load stored repository data
  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load tracked repositories
      final reposList = prefs.getStringList(_reposKey) ?? [];
      _trackedRepos.addAll(reposList);
      
      // Load Gist ID
      _gistId = prefs.getString(_gistIdKey);
      
      // If no Gist exists, create one
      if (_gistId == null) {
        await _createTrackingGist();
      } else {
        // Sync with existing Gist
        await _syncFromGist();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading repo tracking data: $e');
    }
  }
  
  /// Create a new GitHub Gist for tracking repositories
  Future<void> _createTrackingGist() async {
    try {
      final hasToken = await _githubService.hasValidToken();
      if (!hasToken) {
        debugPrint('No GitHub token available for Gist creation');
        return;
      }
      
      final gistData = {
        'repositories': _trackedRepos.toList(),
        'created_at': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      final success = await GistService(_githubService.accessToken!).createOrUpdatePreferencesGist(gistData);
      if (success) {
        // Get the Gist ID by finding the created Gist
        final gistId = await _findTrackingGist();
        if (gistId != null) {
          _gistId = gistId;
          await _saveGistId();
          debugPrint('Created tracking Gist: $_gistId');
        }
      }
    } catch (e) {
      debugPrint('Error creating tracking Gist: $e');
    }
  }
  
  /// Find the tracking Gist by description
  Future<String?> _findTrackingGist() async {
    try {
      if (_githubService.accessToken == null) return null;
      
      // We'll need to extend GistService to support custom descriptions
      // For now, use a workaround by checking the existing GistService
      return null; // 
    } catch (e) {
      debugPrint('Error finding tracking Gist: $e');
      return null;
    }
  }
  
  /// Save Gist ID to local storage
  Future<void> _saveGistId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_gistId != null) {
        await prefs.setString(_gistIdKey, _gistId!);
      }
    } catch (e) {
      debugPrint('Error saving Gist ID: $e');
    }
  }
  
  /// Sync repository data from GitHub Gist
  Future<void> _syncFromGist() async {
    try {
      if (_gistId == null) return;
      
      final hasToken = await _githubService.hasValidToken();
      if (!hasToken) return;
      
      // For now, we'll use the existing GistService to get preferences
      // This is a temporary solution until we implement custom Gist tracking
      final gistService = GistService(_githubService.accessToken!);
      final preferences = await gistService.getPreferences();
      
      if (preferences != null && preferences.containsKey('repositories')) {
        final reposList = List<String>.from(preferences['repositories'] ?? []);
        
        // Merge with local data (union of both sets)
        _trackedRepos.addAll(reposList);
        await _saveTrackedRepos();
        
        debugPrint('Synced ${reposList.length} repositories from Gist');
      }
    } catch (e) {
      debugPrint('Error syncing from Gist: $e');
    }
  }
  
  /// Save tracked repositories to local storage
  Future<void> _saveTrackedRepos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_reposKey, _trackedRepos.toList());
    } catch (e) {
      debugPrint('Error saving tracked repos: $e');
    }
  }
  
  /// Check if user can add a new repository
  Future<bool> canAddRepository() async {
    if (_iapService.isPremiumActive) {
      return true; // Premium users can add unlimited repos
    }
    
    if (_iapService.isInTrialPeriod) {
      return totalReposEverAdded < 3; // Trial users: max 3 repos
    }
    
    return totalReposEverAdded < 1; // Free users: max 1 repo
  }
  
  /// Add a repository to tracking
  Future<bool> addRepository(String repoId) async {
    try {
      // Check if user can add more repositories
      if (!await canAddRepository()) {
        debugPrint('Repository limit reached. Cannot add: $repoId');
        return false;
      }
      
      // Add to local storage
      _trackedRepos.add(repoId);
      await _saveTrackedRepos();
      
      // Sync to GitHub Gist
      await _syncToGist();
      
      notifyListeners();
      debugPrint('Added repository to tracking: $repoId');
      return true;
    } catch (e) {
      debugPrint('Error adding repository: $e');
      return false;
    }
  }
  
  /// Remove a repository from tracking
  Future<bool> removeRepository(String repoId) async {
    try {
      // Remove from local storage
      final removed = _trackedRepos.remove(repoId);
      if (removed) {
        await _saveTrackedRepos();
        
        // Sync to GitHub Gist
        await _syncToGist();
        
        notifyListeners();
        debugPrint('Removed repository from tracking: $repoId');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing repository: $e');
      return false;
    }
  }
  
  /// Sync current repository list to GitHub Gist
  Future<void> _syncToGist() async {
    try {
      if (_gistId == null) return;
      
      final hasToken = await _githubService.hasValidToken();
      if (!hasToken) return;
      
      // Use GistService to update the preferences
      final gistService = GistService(_githubService.accessToken!);
      final gistData = {
        'repositories': _trackedRepos.toList(),
        'updated_at': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      await gistService.createOrUpdatePreferencesGist(gistData);
      debugPrint('Synced ${_trackedRepos.length} repositories to Gist');
    } catch (e) {
      debugPrint('Error syncing to Gist: $e');
    }
  }
  
  /// Check if a repository is being tracked
  bool isRepositoryTracked(String repoId) {
    return _trackedRepos.contains(repoId);
  }
  
  /// Get repository limit information
  RepoLimitInfo getRepoLimitInfo() {
    final subscriptionInfo = _iapService.getSubscriptionInfo();
    
    return RepoLimitInfo(
      currentCount: totalReposEverAdded,
      maxAllowed: subscriptionInfo.maxRepositories,
      isPremium: _iapService.isPremiumActive,
      isInTrial: _iapService.isInTrialPeriod,
      trialDaysRemaining: _iapService.getTrialDaysRemaining(),
      canAddMore: totalReposEverAdded < subscriptionInfo.maxRepositories,
    );
  }
  
  /// Handle IAP status changes
  void _onIAPStatusChanged() {
    // Notify listeners when subscription status changes
    // This allows UI to update repository limits
    notifyListeners();
  }
  
  /// Force refresh from Gist (useful for manual sync)
  Future<void> refreshFromGist() async {
    await _syncFromGist();
  }
  
  /// Get detailed tracking information
  TrackingInfo getTrackingInfo() {
    return TrackingInfo(
      totalRepos: totalReposEverAdded,
      gistId: _gistId,
      isGistSynced: _gistId != null,
      lastSync: DateTime.now(), //
      subscriptionInfo: _iapService.getSubscriptionInfo(),
      limitInfo: getRepoLimitInfo(),
    );
  }
  
  /// Dispose resources
  @override
  void dispose() {
    _iapService.removeListener(_onIAPStatusChanged);
    super.dispose();
  }
}

/// Repository limit information for UI display
class RepoLimitInfo {
  final int currentCount;
  final int maxAllowed; // -1 means unlimited
  final bool isPremium;
  final bool isInTrial;
  final int trialDaysRemaining;
  final bool canAddMore;
  
  const RepoLimitInfo({
    required this.currentCount,
    required this.maxAllowed,
    required this.isPremium,
    required this.isInTrial,
    required this.trialDaysRemaining,
    required this.canAddMore,
  });
  
  String get limitDescription {
    if (isPremium) {
      return 'Unlimited repositories';
    }
    
    if (isInTrial) {
      return '$currentCount of 3 repositories ($trialDaysRemaining trial days left)';
    }
    
    return '$currentCount of 1 repository';
  }
  
  String get upgradeMessage {
    if (isPremium) {
      return 'You have unlimited access!';
    }
    
    if (isInTrial) {
      return 'Enjoy your trial! Upgrade to keep unlimited access.';
    }
    
    return 'Upgrade to Premium for unlimited repositories!';
  }
}

/// Detailed tracking information
class TrackingInfo {
  final int totalRepos;
  final String? gistId;
  final bool isGistSynced;
  final DateTime lastSync;
  final SubscriptionInfo subscriptionInfo;
  final RepoLimitInfo limitInfo;
  
  const TrackingInfo({
    required this.totalRepos,
    required this.gistId,
    required this.isGistSynced,
    required this.lastSync,
    required this.subscriptionInfo,
    required this.limitInfo,
  });
}
