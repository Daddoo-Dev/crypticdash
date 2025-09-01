import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'platform_iap_services.dart';
import 'stripe_user_service.dart';

import 'revenuecat_service.dart';


/// Stripe-based subscription service for CrypticDash
class IAPService extends ChangeNotifier {
  static const String _premiumProductId = 'prod_SxsF2cOTVz2LUQ';

  static const String _trialKey = 'trial_start_date';
  static const String _subscriptionKey = 'subscription_status';
  
  // Subscription state
  SubscriptionStatus _subscriptionStatus = SubscriptionStatus.free;
  DateTime? _trialStartDate;
  bool _isInitialized = false;
  
  // Platform-specific IAP services
  late final PlatformIAPService _platformService;
  
  // Stripe user service reference
  StripeUserService? _userService;
  
  final _logger = Logger();
  
  // Stripe service
  late final StripeService _stripeService;
  
  // Current state
  bool _hasPremiumAccess = false;
  String? _currentUserId;
  
  // Getters
  SubscriptionStatus get subscriptionStatus => _subscriptionStatus;
  DateTime? get trialStartDate => _trialStartDate;
  bool get isInitialized => _isInitialized;
  bool get isPremiumActive => _subscriptionStatus == SubscriptionStatus.premium;
  bool get isInTrialPeriod => _isInTrialPeriod();
  bool get hasPremiumAccess => _hasPremiumAccess;
  String? get currentUserId => _currentUserId;
  
  IAPService() {
    _initializeStripe();
  }
  
  /// Set the Stripe user service reference
  void setAuthService(StripeUserService userService) {
    _userService = userService;
    _userService!.addListener(_onAuthStatusChanged);
    _refreshSubscriptionStatus();
  }
  
  /// Handle auth status changes
  void _onAuthStatusChanged() {
    if (_userService?.isAuthenticated == true) {
      _refreshSubscriptionStatus();
    }
  }
  
  /// Initialize Stripe client
  void _initializeStripe() {
    _stripeService = StripeService();
    
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
      _logger.e('Error initializing Stripe subscription service: $e', error: e, stackTrace: StackTrace.current);
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
      _logger.e('Error loading IAP data: $e', error: e, stackTrace: StackTrace.current);
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
        
                 // Save to Stripe if user is authenticated
         if (_userService?.isAuthenticated == true) {
           await _saveUserToStripe();
           await _logSubscriptionEvent('purchase');
         }
        
        await _saveSubscriptionStatus();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.e('Error purchasing premium: $e', error: e, stackTrace: StackTrace.current);
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
      _logger.e('Error restoring purchases: $e', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }
  
  /// Refresh subscription status
  Future<void> _refreshSubscriptionStatus() async {
    try {
      if (_currentUserId == null) return;
      
      // Check Stripe service for subscription status
      final status = await _stripeService.getUserSubscriptionStatus(_currentUserId!);
      _hasPremiumAccess = status == 'premium';
      _logger.d('Subscription status updated: $_hasPremiumAccess');
      
      notifyListeners();
    } catch (e) {
      _logger.e('Error refreshing subscription status: $e', error: e, stackTrace: StackTrace.current);
    }
  }
  

  
  /// Save user subscription data to Stripe
  Future<void> _saveUserToStripe() async {
    try {
      if (_currentUserId == null) return;
      
      // Update subscription status in Stripe
      await _userService!.updateSubscriptionStatus(_hasPremiumAccess ? 'premium' : 'free');
      _logger.i('User subscription status updated in Stripe: ${_hasPremiumAccess ? 'premium' : 'free'}');
      notifyListeners();
    } catch (e) {
      _logger.e('Error saving user to Stripe: $e', error: e, stackTrace: StackTrace.current);
    }
  }
  
  /// Log subscription event to Stripe
  Future<void> _logSubscriptionEvent(String eventType) async {
    try {
      if (_currentUserId == null) return;
      
             // Event data for logging
       final eventData = {
         'userId': _currentUserId,
         'eventType': eventType,
         'timestamp': DateTime.now().toIso8601String(),
         'subscriptionStatus': _hasPremiumAccess ? 'premium' : 'free',
       };
      
             // For now, just log locally since Stripe service handles events differently
       _logger.i('Subscription event: $eventType for user $_currentUserId - Data: $eventData');
    } catch (e) {
      _logger.e('Error logging subscription event: $e', error: e, stackTrace: StackTrace.current);
    }
  }
  

  
  /// Save subscription status to local storage
  Future<void> _saveSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subscriptionKey, _subscriptionStatus.toString());
    } catch (e) {
      _logger.e('Error saving subscription status: $e', error: e, stackTrace: StackTrace.current);
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
      _logger.e('Error getting product details: $e', error: e, stackTrace: StackTrace.current);
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
    if (_userService != null) {
      _userService!.removeListener(_onAuthStatusChanged);
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
