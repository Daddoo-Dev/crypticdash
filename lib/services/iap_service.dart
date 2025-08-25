import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Unified In-App Purchase service that automatically detects platform
/// and uses the appropriate store APIs (iOS App Store, Google Play, Microsoft Store)
class IAPService extends ChangeNotifier {
  static const String _premiumProductId = 'crypticdash_premium_yearly';
  static const String _trialKey = 'trial_start_date';
  static const String _subscriptionKey = 'subscription_status';
  
  // Subscription state
  SubscriptionStatus _subscriptionStatus = SubscriptionStatus.free;
  DateTime? _trialStartDate;
  bool _isInitialized = false;
  
  // Getters
  SubscriptionStatus get subscriptionStatus => _subscriptionStatus;
  DateTime? get trialStartDate => _trialStartDate;
  bool get isInitialized => _isInitialized;
  bool get isPremiumActive => _subscriptionStatus == SubscriptionStatus.premium;
  bool get isInTrialPeriod => _isInTrialPeriod();
  
  IAPService() {
    _initializeRevenueCat();
  }
  
  /// Initialize RevenueCat for the current platform
  Future<void> _initializeRevenueCat() async {
    try {
      // Initialize RevenueCat with your API key
      // RevenueCat automatically detects the platform and uses the appropriate store
      await Purchases.configure(
        PurchasesConfiguration("your_revenuecat_api_key")
      );
      
      // Load stored data
      await _loadStoredData();
      
      // Check current subscription status
      await _refreshSubscriptionStatus();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing RevenueCat: $e');
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
  
  /// Purchase premium subscription
  Future<bool> purchasePremium() async {
    try {
      // Use RevenueCat to purchase the product
      final customerInfo = await Purchases.purchaseProduct(_premiumProductId);
      
      // Check if purchase was successful
      if (customerInfo.entitlements.active.containsKey('premium')) {
        _subscriptionStatus = SubscriptionStatus.premium;
        await _saveSubscriptionStatus();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error purchasing premium: $e');
      return false;
    }
  }
  
  /// Restore purchases using RevenueCat
  Future<bool> restorePurchases() async {
    try {
      // Use RevenueCat to restore purchases
      final customerInfo = await Purchases.restorePurchases();
      
      // Check if user has active subscription
      if (customerInfo.entitlements.active.containsKey('premium')) {
        _subscriptionStatus = SubscriptionStatus.premium;
        await _saveSubscriptionStatus();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }
  
  /// Check subscription status with RevenueCat
  Future<void> _refreshSubscriptionStatus() async {
    try {
      // Get current customer info from RevenueCat
      final customerInfo = await Purchases.getCustomerInfo();
      
      if (customerInfo.entitlements.active.containsKey('premium')) {
        _subscriptionStatus = SubscriptionStatus.premium;
      } else {
        _subscriptionStatus = SubscriptionStatus.free;
      }
      
      await _saveSubscriptionStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing subscription status: $e');
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
    // RevenueCat automatically handles platform-specific pricing
    // For now, return a standard price
    return '\$9.99/year';
  }
  
  /// Dispose resources
  @override
  void dispose() {
    // RevenueCat handles its own cleanup
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
