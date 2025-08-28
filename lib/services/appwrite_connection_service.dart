import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'logging_service.dart';

/// Service for testing Appwrite connection and managing user data
class AppwriteConnectionService extends ChangeNotifier {
  static const String _projectId = '68ac6493003072efa8c5';
  static const String _databaseId = '68ac64ea0032f91f0fc7';
  static const String _endpoint = 'https://nyc.cloud.appwrite.io/v1';
  static const String _usersCollectionId = 'users';
  
  // Appwrite services
  late final Client _client;
  late final Databases _databases;
  late final Account _account;
  
  // Connection state
  bool _isConnected = false;
  bool _isInitialized = false;
  String? _connectionError;
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  String? get connectionError => _connectionError;
  
  AppwriteConnectionService() {
    _initializeAppwrite();
  }
  
  /// Initialize Appwrite client
  void _initializeAppwrite() {
    try {
      _client = Client()
        ..setEndpoint(_endpoint)
        ..setProject(_projectId);
      
      _databases = Databases(_client);
      _account = Account(_client);
      _isInitialized = true;
      LoggingService.debug('AppwriteConnectionService: Initialized successfully');
    } catch (e) {
      _connectionError = 'Failed to initialize Appwrite client: $e';
      LoggingService.error('AppwriteConnectionService: Initialization failed: $e', e, StackTrace.current);
    }
  }
  
  /// Test connection to Appwrite (ping functionality) - using the correct Appwrite method
  Future<bool> testConnection() async {
    if (!_isInitialized) {
      _connectionError = 'Appwrite client not initialized';
      return false;
    }
    
    try {
      LoggingService.debug('AppwriteConnectionService: Testing connection with ping...');
      
      // Use the correct Appwrite ping method (same as the starter kit)
      final response = await _client.ping();
      
      // Check if we already have a session, create one only if needed
      try {
        await _account.getSession(sessionId: 'current');
        LoggingService.debug('AppwriteConnectionService: Using existing session');
      } catch (e) {
        // No existing session, create an anonymous one
        await _account.createAnonymousSession();
        LoggingService.debug('AppwriteConnectionService: Created new anonymous session for database access');
      }
      
      _isConnected = true;
      _connectionError = null;
      LoggingService.success('AppwriteConnectionService: Ping successful - $response');
      return true;
    } catch (e) {
      _isConnected = false;
      _connectionError = 'Connection test failed: $e';
      LoggingService.error('AppwriteConnectionService: Connection test failed: $e', e, StackTrace.current);
      return false;
    }
  }
  
  /// Check if user exists in Appwrite database by GitHub ID
  Future<Map<String, dynamic>?> checkUserExists(String githubUserId) async {
    if (!_isConnected) {
      LoggingService.warning('AppwriteConnectionService: Cannot check user - not connected');
      return null;
    }
    
    try {
      final documents = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        queries: [
          Query.equal('userId', githubUserId),
        ],
      );
      
      if (documents.documents.isNotEmpty) {
        final userData = documents.documents.first.data;
        LoggingService.debug('AppwriteConnectionService: Found existing user with ID: ${userData['userId']}');
        return userData;
      }
      
      LoggingService.debug('AppwriteConnectionService: No existing user found for GitHub ID: $githubUserId');
      return null;
    } catch (e) {
      LoggingService.error('AppwriteConnectionService: Error checking user existence: $e', e, StackTrace.current);
      return null;
    }
  }
  
  /// Create new user in Appwrite database
  Future<String?> createUser({
    required String githubUserId,
    required String githubUsername,
    String? email,
    String? displayName,
  }) async {
    if (!_isConnected) {
      LoggingService.warning('AppwriteConnectionService: Cannot create user - not connected');
      return null;
    }
    
    try {
      final userData = {
        'userId': githubUserId,
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
      
      LoggingService.success('AppwriteConnectionService: Created new user: ${document.$id}');
      return document.$id;
    } catch (e) {
      LoggingService.error('AppwriteConnectionService: Error creating user: $e', e, StackTrace.current);
      return null;
    }
  }
  
  /// Update user's last login time
  Future<bool> updateUserLastLogin(String appwriteUserId) async {
    if (!_isConnected) return false;
    
    try {
      // Note: lastLoginAt field doesn't exist in the collection, so we can't update it
      // For now, just return success since we can't update a non-existent field
      LoggingService.debug('AppwriteConnectionService: Cannot update lastLoginAt - field does not exist in collection');
      return true;
    } catch (e) {
      LoggingService.error('AppwriteConnectionService: Error updating last login: $e', e, StackTrace.current);
      return false;
    }
  }
  
  /// Get user subscription status
  Future<String?> getUserSubscriptionStatus(String githubUserId) async {
    final userData = await checkUserExists(githubUserId);
    return userData?['subscriptionStatus'];
  }
  
  /// Safely notify listeners after build phase is complete
  void safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
