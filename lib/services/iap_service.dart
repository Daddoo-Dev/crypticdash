import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';


/// Appwrite-based subscription service for CrypticDash
class IAPService extends ChangeNotifier {
  static const String _premiumProductId = 'crypticdash_premium_yearly';
  static const String _trialKey = 'trial_start_date';
  static const String _subscriptionKey = 'subscription_status';
  
  // Appwrite configuration
  static const String _projectId = 'nyc-68ac6493003072efa8c5';
  static const String _databaseId = '68ac64ea0032f91f0fc7';
  static const String _endpoint = 'https://cloud.appwrite.io';
  
  // Subscription state
  SubscriptionStatus _subscriptionStatus = SubscriptionStatus.free;
  DateTime? _trialStartDate;
  bool _isInitialized = false;
  String? _currentUserId;
  
  // Appwrite services
  late final Client _client;
  late final Databases _databases;
  late final Account _account;
  
  // Getters
  SubscriptionStatus get subscriptionStatus => _subscriptionStatus;
  DateTime? get trialStartDate => _trialStartDate;
  bool get isInitialized => _isInitialized;
  bool get isPremiumActive => _subscriptionStatus == SubscriptionStatus.premium;
  bool get isInTrialPeriod => _isInTrialPeriod();
  
  IAPService() {
    _initializeAppwrite();
  }
  
  /// Initialize Appwrite client
  void _initializeAppwrite() {
    _client = Client()
      ..setEndpoint(_endpoint)
      ..setProject(_projectId);
    
    _databases = Databases(_client);
    _account = Account(_client);
    
    _initializeService();
  }
  
  /// Initialize the subscription service
  Future<void> _initializeService() async {
    try {
      // Load stored data first
      await _loadStoredData();
      
      // Try to get current user from Appwrite
      await _getCurrentUser();
      
      // Check current subscription status
      await _refreshSubscriptionStatus();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing Appwrite subscription service: $e');
      // Fallback to stored data
      await _loadStoredData();
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// Get current user from Appwrite
  Future<void> _getCurrentUser() async {
    try {
      final session = await _account.getSession(sessionId: 'current');
      _currentUserId = session.userId;
      debugPrint('Current user ID: $_currentUserId');
    } catch (e) {
      debugPrint('No active session, using local data: $e');
      _currentUserId = null;
    }
  }
  
  /// Load stored subscription and trial data
  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load trial start date
      final trialDateString = prefs.getString(_trialKey);
      if (trialDateString != null) {
        _trialStartDate = DateTime.parse(trialDateString);
      }
      
      // Load subscription status
      final subscriptionString = prefs.getString(_subscriptionKey);
      if (subscriptionString != null) {
        _subscriptionStatus = SubscriptionStatus.values.firstWhere(
          (e) => e.toString() == subscriptionString,
          orElse: () => SubscriptionStatus.free,
        );
      }
      
      // If no trial date is set, set it now (first time user)
      if (_trialStartDate == null) {
        _trialStartDate = DateTime.now();
        await prefs.setString(_trialKey, _trialStartDate!.toIso8601String());
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading IAP data: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// Check if user is currently in trial period
  bool _isInTrialPeriod() {
    if (_trialStartDate == null) return false;
    
    final trialEnd = _trialStartDate!.add(const Duration(days: 30));
    return DateTime.now().isBefore(trialEnd);
  }
  
  /// Get remaining trial days
  int getTrialDaysRemaining() {
    if (!_isInTrialPeriod()) return 0;
    
    final trialEnd = _trialStartDate!.add(const Duration(days: 30));
    final remaining = trialEnd.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
  
  /// Purchase premium subscription (simulated for now)
  Future<bool> purchasePremium() async {
    try {
      // For now, simulate a successful purchase
      // In a real app, this would integrate with payment processing
      _subscriptionStatus = SubscriptionStatus.premium;
      
      // Save to Appwrite if user is authenticated
      if (_currentUserId != null) {
        await _saveUserToAppwrite();
        await _logSubscriptionEvent('purchase', null, 'premium');
      }
      
      await _saveSubscriptionStatus();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error purchasing premium: $e');
      return false;
    }
  }
  
  /// Restore purchases (simulated for now)
  Future<bool> restorePurchases() async {
    try {
      // For now, just refresh the subscription status
      await _refreshSubscriptionStatus();
      return _subscriptionStatus == SubscriptionStatus.premium;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }
  
  /// Check subscription status with Appwrite
  Future<void> _refreshSubscriptionStatus() async {
    try {
      if (_currentUserId != null) {
        // Try to get user data from Appwrite
        final userData = await _getUserFromAppwrite();
        if (userData != null) {
          _subscriptionStatus = _parseSubscriptionStatus(userData['subscriptionStatus']);
          if (userData['trialStartDate'] != null) {
            _trialStartDate = DateTime.parse(userData['trialStartDate']);
          }
        }
      }
      
      await _saveSubscriptionStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing subscription status: $e');
    }
  }
  
  /// Get user data from Appwrite
  Future<Map<String, dynamic>?> _getUserFromAppwrite() async {
    try {
      final documents = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: 'users',
        queries: [
          Query.equal('userId', _currentUserId),
        ],
      );
      
      if (documents.documents.isNotEmpty) {
        final userDoc = documents.documents.first;
        return userDoc.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user from Appwrite: $e');
      return null;
    }
  }
  
  /// Save user to Appwrite
  Future<void> _saveUserToAppwrite() async {
    try {
      final userData = {
        'userId': _currentUserId,
        'email': 'user@example.com', // This should come from actual user data
        'subscriptionStatus': _subscriptionStatus.toString(),
        'trialStartDate': _trialStartDate?.toIso8601String(),
        'subscriptionExpiryDate': null, // Set when implementing real expiry
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Check if user already exists
      final existingUser = await _getUserFromAppwrite();
      if (existingUser != null) {
        // Update existing user
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: 'users',
          documentId: existingUser['\$id'],
          data: userData,
        );
      } else {
        // Create new user
        await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: 'users',
          documentId: 'unique()',
          data: userData,
        );
      }
      
      debugPrint('User saved to Appwrite successfully');
    } catch (e) {
      debugPrint('Error saving user to Appwrite: $e');
    }
  }
  
  /// Log subscription event to Appwrite
  Future<void> _logSubscriptionEvent(String eventType, String? oldStatus, String newStatus) async {
    try {
      final eventData = {
        'userId': _currentUserId,
        'eventType': eventType,
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
      };
      
      await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: 'subscription_events',
        documentId: 'unique()',
        data: eventData,
      );
      
      debugPrint('Subscription event logged to Appwrite');
    } catch (e) {
      debugPrint('Error logging subscription event: $e');
    }
  }
  
  /// Parse subscription status from string
  SubscriptionStatus _parseSubscriptionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'premium':
        return SubscriptionStatus.premium;
      case 'expired':
        return SubscriptionStatus.expired;
      default:
        return SubscriptionStatus.free;
    }
  }
  
  /// Save subscription status to local storage
  Future<void> _saveSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subscriptionKey, _subscriptionStatus.toString());
    } catch (e) {
      debugPrint('Error saving subscription status: $e');
    }
  }
  
  /// Get subscription info for display
  SubscriptionInfo getSubscriptionInfo() {
    return SubscriptionInfo(
      status: _subscriptionStatus,
      isInTrial: _isInTrialPeriod(),
      trialDaysRemaining: getTrialDaysRemaining(),
      productId: _premiumProductId,
      price: _getLocalizedPrice(),
    );
  }
  
  /// Get localized price for current platform
  String _getLocalizedPrice() {
    return '\$9.99/year';
  }
  
  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}

/// Subscription status enum
enum SubscriptionStatus {
  free,
  premium,
  expired,
}

/// Subscription information for UI display
class SubscriptionInfo {
  final SubscriptionStatus status;
  final bool isInTrial;
  final int trialDaysRemaining;
  final String productId;
  final String price;
  
  const SubscriptionInfo({
    required this.status,
    required this.isInTrial,
    required this.trialDaysRemaining,
    required this.productId,
    required this.price,
  });
  
  bool get canAddRepositories {
    switch (status) {
      case SubscriptionStatus.premium:
        return true;
      case SubscriptionStatus.free:
        return false;
      case SubscriptionStatus.expired:
        return false;
    }
  }
  
  int get maxRepositories {
    if (status == SubscriptionStatus.premium) return -1; // Unlimited
    
    if (isInTrial) return 3; // Trial period
    
    return 1; // Free tier
  }
}

/// Abstract base class for platform-specific IAP services
abstract class PlatformIAPService {
  /// Purchase a product
  Future<bool> purchaseProduct(String productId);
  
  /// Restore purchases
  Future<bool> restorePurchases();
  
  /// Check if user has active subscription
  Future<bool> hasActiveSubscription(String productId);
  
  /// Get product details
  Future<ProductDetails?> getProductDetails(String productId);
  
  /// Dispose resources
  void dispose();
}

/// Product details
class ProductDetails {
  final String id;
  final String title;
  final String description;
  final String price;
  final String currencyCode;
  
  const ProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
  });
}
