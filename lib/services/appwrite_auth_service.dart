import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'logging_service.dart';

/// Service for managing Appwrite user authentication and account creation
class AppwriteAuthService extends ChangeNotifier {
  static const String _projectId = '68ac6493003072efa8c5';
  static const String _databaseId = '68ac64ea0032f91f0fc7';
  static const String _endpoint = 'https://nyc.cloud.appwrite.io/v1';
  static const String _usersCollectionId = 'users';
  
  // Appwrite services
  late final Client _client;
  late final Databases _databases;
  late final Account _account;
  
  // Current user state
  String? _currentUserId;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  
  // Getters
  String? get currentUserId => _currentUserId;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  
  AppwriteAuthService() {
    _initializeAppwrite();
  }
  
  /// Initialize Appwrite client
  void _initializeAppwrite() {
    _client = Client()
      ..setEndpoint(_endpoint)
      ..setProject(_projectId);
    
    _databases = Databases(_client);
    _account = Account(_client);
    
    _checkExistingSession();
  }
  
  /// Check if there's an existing Appwrite session
  Future<void> _checkExistingSession() async {
    try {
      final session = await _account.getSession(sessionId: 'current');
      _currentUserId = session.userId;
      _isAuthenticated = true;
      LoggingService.debug('Found existing Appwrite session for user: $_currentUserId');
      notifyListeners();
    } catch (e) {
      LoggingService.debug('No existing Appwrite session: $e');
      _isAuthenticated = false;
      _currentUserId = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Ensure user has Appwrite data - called for existing users
  Future<void> ensureUserDataExists({
    required String githubUsername,
    required int githubUserId,
    String? email,
    String? displayName,
  }) async {
    try {
      // First, try to create or get Appwrite user account
      final appwriteUserId = await createOrGetUserAccount(
        githubUsername: githubUsername,
        githubUserId: githubUserId,
        email: email,
        displayName: displayName,
      );
      
      if (appwriteUserId != null) {
        // Now we have an authenticated Appwrite user, we can access the database
        _currentUserId = appwriteUserId;
        _isAuthenticated = true;
        LoggingService.success('Ensured Appwrite user data exists: $_currentUserId');
        notifyListeners();
      }
    } catch (e) {
      LoggingService.error('Error ensuring user data exists: $e', e, StackTrace.current);
    }
  }
  
  /// Create or get Appwrite user account for GitHub user
  Future<String?> createOrGetUserAccount({
    required String githubUsername,
    required int githubUserId,
    String? email,
    String? displayName,
  }) async {
    try {
      // Check if user already exists in Appwrite
      final existingUser = await _getUserByGitHubId(githubUserId.toString());
      
             if (existingUser != null) {
         // User exists, check if we need to update the email
         final currentEmail = existingUser['Email'];
         if (email != null && email != currentEmail) {
           // Update the email if it's different
           try {
             await _databases.updateDocument(
               databaseId: _databaseId,
               collectionId: _usersCollectionId,
               documentId: existingUser['\$id'],
               data: {
                 'Email': email,
               },
             );
             LoggingService.success('Updated email for existing user: $email');
           } catch (e) {
             LoggingService.error('Error updating email: $e', e, StackTrace.current);
           }
         }
         
         _currentUserId = existingUser['\$id'];
         _isAuthenticated = true;
         LoggingService.debug('Found existing Appwrite user: $_currentUserId');
         notifyListeners();
         return _currentUserId;
       }
      
             // Create new user document in Appwrite
       final userData = {
         'userId': githubUserId.toString(),
         'Email': email ?? 'no-email@placeholder.com', // Required field from actual collection
         'subscriptionStatus': 'free', // Required field from actual collection
         'createdAt': DateTime.now().toIso8601String(), // Required field from actual collection
         'trialStartDate': DateTime.now().toIso8601String(), // Optional field from actual collection
         'subscriptionExpiryDate': DateTime.now().add(Duration(days: 30)).toIso8601String(), // Optional field from actual collection
       };
      
      final document = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        documentId: 'unique()',
        data: userData,
      );
      
      _currentUserId = document.$id;
      _isAuthenticated = true;
      
      LoggingService.success('Created new Appwrite user: $_currentUserId');
      notifyListeners();
      
      return _currentUserId;
    } catch (e) {
      LoggingService.error('Error creating/getting Appwrite user account: $e', e, StackTrace.current);
      return null;
    }
  }
  
  /// Get user by GitHub ID
  Future<Map<String, dynamic>?> _getUserByGitHubId(String githubUserId) async {
    try {
      final documents = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        queries: [
          Query.equal('userId', githubUserId),
        ],
      );
      
      if (documents.documents.isNotEmpty) {
        return documents.documents.first.data;
      }
      return null;
    } catch (e) {
      LoggingService.error('Error getting user by GitHub ID: $e', e, StackTrace.current);
      return null;
    }
  }
  
  /// Update user's last login time
  Future<void> updateLastLogin() async {
    if (_currentUserId == null) return;
    
    try {
      // Note: lastLoginAt field doesn't exist in the collection schema
      // We can't update a non-existent field, so just log success
      LoggingService.debug('Last login update skipped - lastLoginAt field does not exist in collection schema');
    } catch (e) {
      LoggingService.error('Error updating last login time: $e', e, StackTrace.current);
    }
  }
  
  /// Get current user data from Appwrite
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (_currentUserId == null) return null;
    
    try {
      final document = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        documentId: _currentUserId!,
      );
      return document.data;
    } catch (e) {
      LoggingService.error('Error getting current user data: $e', e, StackTrace.current);
      return null;
    }
  }
  
  /// Sign out current user
  Future<void> signOut() async {
    try {
      if (_currentUserId != null) {
        await _account.deleteSession(sessionId: 'current');
      }
    } catch (e) {
      LoggingService.error('Error signing out: $e', e, StackTrace.current);
    } finally {
      _currentUserId = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }
  
  /// Check if user has premium subscription
  Future<bool> hasPremiumSubscription() async {
    try {
      final userData = await getCurrentUserData();
      if (userData != null) {
        final status = userData['subscriptionStatus'];
        return status == 'premium';
      }
      return false;
    } catch (e) {
      LoggingService.error('Error checking premium status: $e', e, StackTrace.current);
      return false;
    }
  }
  
  /// Update user's subscription status
  Future<void> updateSubscriptionStatus(String status) async {
    if (_currentUserId == null) return;
    
    try {
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        documentId: _currentUserId!,
        data: {
          'subscriptionStatus': status,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      LoggingService.success('Updated subscription status to: $status');
      notifyListeners();
    } catch (e) {
      LoggingService.error('Error updating subscription status: $e', e, StackTrace.current);
    }
  }
}
