import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';
import 'platform_iap_services.dart';
import 'appwrite_auth_service.dart';
import 'logging_service.dart';

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
  
  // Appwrite services
  late final Client _client;
  late final Databases _databases;
  
  // Platform-specific IAP services
  late final PlatformIAPService _platformService;
  
  // Appwrite auth service reference
  AppwriteAuthService? _authService;
  
  // Getters
  SubscriptionStatus get subscriptionStatus => _subscriptionStatus;
  DateTime? get trialStartDate => _trialStartDate;
  bool get isInitialized => _isInitialized;
  bool get isPremiumActive => _subscriptionStatus == SubscriptionStatus.premium;
  bool get isInTrialPeriod => _isInTrialPeriod();
  
  IAPService() {
    _initializeAppwrite();
  }
  
  /// Set the Appwrite auth service reference
  void setAuthService(AppwriteAuthService authService) {
    _authService = authService;
    _authService!.addListener(_onAuthStatusChanged);
    _refreshSubscriptionStatus();
  }
  
  /// Handle auth status changes
  void _onAuthStatusChanged() {
    if (_authService?.isAuthenticated == true) {
      _refreshSubscriptionStatus();
    }
  }
  
  /// Initialize Appwrite client
  void _initializeAppwrite() {
    _client = Client()
      ..setEndpoint(_endpoint)
      ..setProject(_projectId);
    
    _databases = Databases(_client);
    
    _initializePlatformService();
    _initializeService();
  }
  
  /// Initialize platform-specific IAP service
  void _initializePlatformService() {
    if (Platform.isWindows) {
      _platformService = WindowsStoreService();
    } else if (Platform.isMacOS) {
      _platformService = MacOSStoreService();
    } else if (Platform.isIOS) {
      _platformService = IOSStoreService();
    } else if (Platform.isAndroid) {
      _platformService = AndroidStoreService();
    } else {
      _platformService = MockStoreService();
    }
    
    // Initialize in_app_purchase for supported platforms
    // Note: Currently using platform-specific services instead of in_app_purchase
    // This can be enabled later when needed for iOS/Android
  }
  
  /// Initialize the subscription service
  Future<void> _initializeService() async {
    try {
      // Load stored data first
      await _loadStoredData();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      LoggingService.error('Error initializing Appwrite subscription service: $e', e, StackTrace.current);
      // Fallback to stored data
      await _loadStoredData();
      _isInitialized = true;
      notifyListeners();
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
      LoggingService.error('Error loading IAP data: $e', e, StackTrace.current);
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
  
  /// Purchase premium subscription using platform-specific IAP
  Future<bool> purchasePremium() async {
    try {
      // Use platform-specific service for purchase
      final success = await _platformService.purchaseProduct(_premiumProductId);
      
      if (success) {
        _subscriptionStatus = SubscriptionStatus.premium;
        
        // Save to Appwrite if user is authenticated
        if (_authService?.isAuthenticated == true) {
          await _saveUserToAppwrite();
          await _logSubscriptionEvent('purchase', null, 'premium');
        }
        
        await _saveSubscriptionStatus();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      LoggingService.error('Error purchasing premium: $e', e, StackTrace.current);
      return false;
    }
  }
  
  /// Restore purchases using platform-specific IAP
  Future<bool> restorePurchases() async {
    try {
      // Use platform-specific service for restore
      final success = await _platformService.restorePurchases();
      
      if (success) {
        // Refresh subscription status from platform
        await _refreshSubscriptionStatus();
        return _subscriptionStatus == SubscriptionStatus.premium;
      }
      
      return false;
    } catch (e) {
      LoggingService.error('Error restoring purchases: $e', e, StackTrace.current);
      return false;
    }
  }
  
  /// Check subscription status with Appwrite
  Future<void> _refreshSubscriptionStatus() async {
    try {
      if (_authService?.isAuthenticated == true) {
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
      LoggingService.error('Error refreshing subscription status: $e', e, StackTrace.current);
    }
  }
  
  /// Get user data from Appwrite
  Future<Map<String, dynamic>?> _getUserFromAppwrite() async {
    try {
      if (_authService?.currentUserId == null) return null;
      
      final userData = await _authService!.getCurrentUserData();
      return userData;
    } catch (e) {
      LoggingService.error('Error getting user from Appwrite: $e', e, StackTrace.current);
      return null;
    }
  }
  
  /// Save user to Appwrite
  Future<void> _saveUserToAppwrite() async {
    try {
      if (_authService?.currentUserId == null) return;
      
      await _authService!.updateSubscriptionStatus(_subscriptionStatus.toString());
      
      LoggingService.success('User subscription updated in Appwrite successfully');
    } catch (e) {
      LoggingService.error('Error saving user to Appwrite: $e', e, StackTrace.current);
    }
  }
  
  /// Log subscription event to Appwrite
  Future<void> _logSubscriptionEvent(String eventType, String? oldStatus, String newStatus) async {
    try {
      if (_authService?.currentUserId == null) return;
      
      final eventData = {
        'userId': _authService!.currentUserId,
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
      
      LoggingService.success('Subscription event logged to Appwrite');
    } catch (e) {
      LoggingService.error('Error logging subscription event: $e', e, StackTrace.current);
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
      LoggingService.error('Error saving subscription status: $e', e, StackTrace.current);
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
  
  /// Get product details from platform service
  Future<ProductDetails?> getProductDetails() async {
    try {
      return await _platformService.getProductDetails(_premiumProductId);
    } catch (e) {
      LoggingService.error('Error getting product details: $e', e, StackTrace.current);
      return null;
    }
  }
  
  /// Get localized price for display
  String _getLocalizedPrice() {
    // This would come from platform-specific service
    // For now, return a placeholder
    return '\$9.99/year';
  }
  
  @override
  void dispose() {
    if (_authService != null) {
      _authService!.removeListener(_onAuthStatusChanged);
    }
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
