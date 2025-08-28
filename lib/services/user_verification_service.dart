import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'logging_service.dart';
import 'appwrite_connection_service.dart';
import 'github_service.dart';

/// Service for verifying and managing user data in Appwrite
/// This service works regardless of GitHub authentication status
class UserVerificationService extends ChangeNotifier {
  final AppwriteConnectionService _appwriteService;
  final GitHubService _githubService;
  
  // User state
  Map<String, dynamic>? _currentUserData;
  bool _isVerified = false;
  bool _isLoading = false;
  String? _verificationError;
  
  // Getters
  Map<String, dynamic>? get currentUserData => _currentUserData;
  bool get isVerified => _isVerified;
  bool get isLoading => _isLoading;
  String? get verificationError => _verificationError;
  
  UserVerificationService(this._appwriteService, this._githubService);
  
  /// Verify user data in Appwrite - this is the main method called on app startup
  Future<bool> verifyUserData() async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _verificationError = null;
    
    try {
      LoggingService.debug('UserVerificationService: Starting Appwrite connection test...');
      
      // First, test Appwrite connection
      final isConnected = await _appwriteService.testConnection();
      if (!isConnected) {
        _verificationError = 'Failed to connect to Appwrite';
        LoggingService.error('UserVerificationService: Appwrite connection failed');
        return false;
      }
      
      // Check if user has a GitHub token
      final hasValidToken = await _githubService.hasValidToken();
      
      if (hasValidToken) {
        // User is authenticated with GitHub, verify their data
        LoggingService.debug('UserVerificationService: User has GitHub token, verifying data...');
        return await _verifyAuthenticatedUser();
      } else {
        // User is not authenticated, but we can still check if they have data
        // This handles the case where user data exists but token expired
        LoggingService.debug('UserVerificationService: No GitHub token, checking for existing data...');
        return await _checkForExistingData();
      }
      
    } catch (e, stackTrace) {
      _verificationError = 'Verification failed: $e';
      LoggingService.error('UserVerificationService: Verification error: $e', e, stackTrace);
      return false;
    } finally {
      _isLoading = false;
      // Only notify listeners after the build phase is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
  
  /// Verify user data for authenticated users
  Future<bool> _verifyAuthenticatedUser() async {
    try {
      final userData = await _githubService.getAuthenticatedUser();
      if (userData == null) {
        _verificationError = 'Failed to get GitHub user data';
        return false;
      }
      
      final githubUserId = userData['id'].toString();
      final githubUsername = userData['login'];
      final email = userData['email'];
      final displayName = userData['name'];
      
      LoggingService.debug('UserVerificationService: Checking for user: $githubUsername (ID: $githubUserId)');
      
      // Check if user exists in Appwrite
      final existingUser = await _appwriteService.checkUserExists(githubUserId);
      
      if (existingUser != null) {
        // User exists, update last login and set current data
        _currentUserData = existingUser;
        _isVerified = true;
        
        // Update last login time
        final appwriteUserId = existingUser['\$id'];
        if (appwriteUserId != null) {
          await _appwriteService.updateUserLastLogin(appwriteUserId);
        }
        
        LoggingService.success('UserVerificationService: User verified successfully: ${existingUser['githubUsername']}');
        return true;
      } else {
        // User doesn't exist, create them
        LoggingService.debug('UserVerificationService: Creating new user: $githubUsername');
        
        final newUserId = await _appwriteService.createUser(
          githubUserId: githubUserId,
          githubUsername: githubUsername,
          email: email,
          displayName: displayName,
        );
        
        if (newUserId != null) {
          // Get the newly created user data
          final newUserData = await _appwriteService.checkUserExists(githubUserId);
          if (newUserData != null) {
            _currentUserData = newUserData;
            _isVerified = true;
            LoggingService.success('UserVerificationService: New user created and verified: $githubUsername');
            return true;
          }
        }
        
        _verificationError = 'Failed to create new user';
        return false;
      }
    } catch (e, stackTrace) {
      _verificationError = 'Failed to verify authenticated user: $e';
      LoggingService.error('UserVerificationService: Error verifying authenticated user: $e', e, stackTrace);
      return false;
    }
  }
  
  /// Check for existing user data when not authenticated
  Future<bool> _checkForExistingData() async {
    try {
      // This is a fallback for when users don't have a valid token
      // We could potentially store some identifier in local storage
      // For now, we'll just return false and let the user authenticate
      LoggingService.debug('UserVerificationService: No authentication, user needs to sign in');
      // Return true to indicate verification is "successful" - user just needs to authenticate
      // This prevents the error screen from showing
      return true;
    } catch (e, stackTrace) {
      _verificationError = 'Failed to check for existing data: $e';
      LoggingService.error('UserVerificationService: Error checking existing data: $e', e, stackTrace);
      return false;
    }
  }
  
  /// Get current user's subscription status
  String getCurrentSubscriptionStatus() {
    if (_currentUserData != null) {
      return _currentUserData!['subscriptionStatus'] ?? 'free';
    }
    return 'free';
  }
  
  /// Check if user has premium subscription
  bool hasPremiumSubscription() {
    return getCurrentSubscriptionStatus() == 'premium';
  }
  
  /// Clear current user data (useful for logout)
  void clearUserData() {
    _currentUserData = null;
    _isVerified = false;
    _verificationError = null;
    notifyListeners();
  }
  
  /// Refresh user verification (useful after authentication changes)
  Future<bool> refreshVerification() async {
    return await verifyUserData();
  }
}
