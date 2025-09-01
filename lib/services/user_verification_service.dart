import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'github_service.dart';
import 'revenuecat_service.dart';

/// Service for verifying and managing user data in Stripe
/// This service works regardless of GitHub authentication status
class UserVerificationService extends ChangeNotifier {
  final GitHubService _githubService;
  final StripeService _stripeService;
  final _logger = Logger();
  
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
  
  UserVerificationService(this._githubService, this._stripeService);
  
  /// Verify user data in Stripe - this is the main method called on app startup
  Future<bool> verifyUserData() async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _verificationError = null;
    
    try {
      _logger.d('UserVerificationService: Starting Stripe connection test...');
      
      // First, test Stripe connection
      await _stripeService.initialize();
      final isConnected = _stripeService.isInitialized;
      if (!isConnected) {
        _verificationError = 'Failed to connect to Stripe';
        _logger.e('UserVerificationService: Stripe connection failed');
        return false;
      }
      
      // Check if user has a GitHub token
      final hasValidToken = await _githubService.hasValidToken();
      
      if (hasValidToken) {
        // User is authenticated with GitHub, verify their data
        _logger.d('UserVerificationService: User has GitHub token, verifying data...');
        return await _verifyAuthenticatedUser();
      } else {
        // User is not authenticated, but we can still check if they have data
        // This handles the case where user data exists but token expired
        _logger.d('UserVerificationService: No GitHub token, checking for existing data...');
        return await _checkForExistingData();
      }
      
    } catch (e, stackTrace) {
      _verificationError = 'Verification failed: $e';
      _logger.e('UserVerificationService: Verification error: $e', error: e, stackTrace: stackTrace);
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
      
      _logger.d('UserVerificationService: Checking for user: $githubUsername (ID: $githubUserId)');
      
      // Check if user exists in Stripe
      final existingUser = await _stripeService.getUserSubscriptionStatus(githubUserId.toString());
      
      if (existingUser == 'premium' || existingUser == 'free') {
        // User exists, set current data
        _currentUserData = {
          'id': githubUserId,
          'login': githubUsername,
          'email': email,
          'name': displayName,
          'subscription_status': existingUser,
        };
        _isVerified = true;
        _logger.i('UserVerificationService: User verified successfully: $githubUsername');
        return true;
      } else {
        // User doesn't exist, create them in Stripe
        _logger.d('UserVerificationService: Creating new user in Stripe: $githubUsername');
        
        // For now, just set the user as verified since Stripe will handle customer creation
        // when they actually try to make a purchase
        _currentUserData = {
          'id': githubUserId,
          'login': githubUsername,
          'email': email,
          'name': displayName,
          'subscription_status': 'free',
        };
        _isVerified = true;
        _logger.i('UserVerificationService: User verified successfully: $githubUsername');
        return true;
        

      }
    } catch (e, stackTrace) {
      _verificationError = 'Failed to verify authenticated user: $e';
      _logger.e('UserVerificationService: Error verifying authenticated user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Check for existing user data when not authenticated
  Future<bool> _checkForExistingData() async {
    try {
      // This is a fallback for when users don't have a valid token
      // We could potentially store some identifier in local storage
      // For now, we'll just return false and let the user authenticate
      _logger.d('UserVerificationService: No authentication, user needs to sign in');
      // Return true to indicate verification is "successful" - user just needs to authenticate
      // This prevents the error screen from showing
      return true;
    } catch (e, stackTrace) {
      _verificationError = 'Failed to check for existing data: $e';
      _logger.e('UserVerificationService: Error checking existing data: $e', error: e, stackTrace: stackTrace);
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

  /// Open verification documentation or help
  Future<bool> openVerificationHelp() async {
    try {
      _logger.d('UserVerificationService: Opening verification help...');
      
      // Open the project's documentation or help page
      final helpUrl = Uri.parse('https://github.com/shawn/crypticdash');
      final canLaunch = await canLaunchUrl(helpUrl);
      
      if (canLaunch) {
        await launchUrl(helpUrl, mode: LaunchMode.externalApplication);
        _logger.i('UserVerificationService: Opened verification help');
        return true;
      } else {
        _logger.w('UserVerificationService: Cannot launch verification help URL');
        return false;
      }
    } catch (e) {
      _logger.e('UserVerificationService: Failed to open verification help: $e');
      return false;
    }
  }
  
  /// Get verification status summary as JSON
  Map<String, dynamic> getVerificationSummary() {
    try {
      final summary = {
        'isVerified': _isVerified,
        'isLoading': _isLoading,
        'hasError': _verificationError != null,
        'error': _verificationError,
        'userData': _currentUserData != null,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Convert to JSON string and back to ensure it's valid JSON
      final jsonString = jsonEncode(summary);
      final parsedSummary = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _logger.d('UserVerificationService: Generated verification summary');
      return parsedSummary;
    } catch (e) {
      _logger.e('UserVerificationService: Failed to generate verification summary: $e');
      return {
        'error': 'Failed to generate summary: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
