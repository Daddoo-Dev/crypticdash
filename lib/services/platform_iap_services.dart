import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'iap_service.dart';

/// Windows Store Service using Microsoft Store Services
class WindowsStoreService implements PlatformIAPService {
  static const String _channelName = 'windows_store_service';
  static const MethodChannel _channel = MethodChannel(_channelName);
  
  @override
  Future<bool> purchaseProduct(String productId) async {
    try {
      if (Platform.isWindows) {
        // Use Windows Store Services SDK
        final result = await _channel.invokeMethod('purchaseProduct', {
          'productId': productId,
        });
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Windows Store purchase error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> restorePurchases() async {
    try {
      if (Platform.isWindows) {
        final result = await _channel.invokeMethod('restorePurchases');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Windows Store restore error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> hasActiveSubscription(String productId) async {
    try {
      if (Platform.isWindows) {
        final result = await _channel.invokeMethod('hasActiveSubscription', {
          'productId': productId,
        });
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Windows Store subscription check error: $e');
      return false;
    }
  }
  
  @override
  Future<ProductDetails?> getProductDetails(String productId) async {
    try {
      if (Platform.isWindows) {
        final result = await _channel.invokeMethod('getProductDetails', {
          'productId': productId,
        });
        
        if (result != null) {
          return ProductDetails(
            id: result['id'] ?? productId,
            title: result['title'] ?? 'Premium Subscription',
            description: result['description'] ?? 'Unlimited repositories with AI features',
            price: result['price'] ?? '\$9.99',
            currencyCode: result['currencyCode'] ?? 'USD',
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Windows Store product details error: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    // Cleanup Windows Store resources if needed
  }
}

/// macOS App Store Service using RevenueCat + StoreKit 2
class MacOSStoreService implements PlatformIAPService {
  static const String _channelName = 'macos_store_service';
  static const MethodChannel _channel = MethodChannel(_channelName);
  
  @override
  Future<bool> purchaseProduct(String productId) async {
    try {
      if (Platform.isMacOS) {
        // Use RevenueCat for macOS
        final result = await _channel.invokeMethod('purchaseProduct', {
          'productId': productId,
        });
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('macOS Store purchase error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> restorePurchases() async {
    try {
      if (Platform.isMacOS) {
        final result = await _channel.invokeMethod('restorePurchases');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('macOS Store restore error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> hasActiveSubscription(String productId) async {
    try {
      if (Platform.isMacOS) {
        final result = await _channel.invokeMethod('hasActiveSubscription', {
          'productId': productId,
        });
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('macOS Store subscription check error: $e');
      return false;
    }
  }
  
  @override
  Future<ProductDetails?> getProductDetails(String productId) async {
    try {
      if (Platform.isMacOS) {
        final result = await _channel.invokeMethod('getProductDetails', {
          'productId': productId,
        });
        
        if (result != null) {
          return ProductDetails(
            id: result['id'] ?? productId,
            title: result['title'] ?? 'Premium Subscription',
            description: result['description'] ?? 'Unlimited repositories with AI features',
            price: result['price'] ?? '\$9.99',
            currencyCode: result['currencyCode'] ?? 'USD',
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('macOS Store product details error: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    // Cleanup macOS Store resources if needed
  }
}

/// iOS App Store Service using RevenueCat + StoreKit 2
class IOSStoreService implements PlatformIAPService {
  static const String _channelName = 'ios_store_service';
  static const MethodChannel _channel = MethodChannel(_channelName);
  
  @override
  Future<bool> purchaseProduct(String productId) async {
    try {
      if (Platform.isIOS) {
        // Use RevenueCat for iOS
        final result = await _channel.invokeMethod('purchaseProduct', {
          'productId': productId,
        });
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('iOS Store purchase error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> restorePurchases() async {
    try {
      if (Platform.isIOS) {
        final result = await _channel.invokeMethod('restorePurchases');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('iOS Store restore error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> hasActiveSubscription(String productId) async {
    try {
      if (Platform.isIOS) {
        final result = await _channel.invokeMethod('hasActiveSubscription', {
          'productId': productId,
        });
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('iOS Store subscription check error: $e');
      return false;
    }
  }
  
  @override
  Future<ProductDetails?> getProductDetails(String productId) async {
    try {
      if (Platform.isIOS) {
        final result = await _channel.invokeMethod('getProductDetails', {
          'productId': productId,
        });
        
        if (result != null) {
          return ProductDetails(
            id: result['id'] ?? productId,
            title: result['title'] ?? 'Premium Subscription',
            description: result['description'] ?? 'Unlimited repositories with AI features',
            price: result['price'] ?? '\$9.99',
            currencyCode: result['currencyCode'] ?? 'USD',
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('iOS Store product details error: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    // Cleanup iOS Store resources if needed
  }
}

/// Android Google Play Store Service using RevenueCat
class AndroidStoreService implements PlatformIAPService {
  static const String _channelName = 'android_store_service';
  static const MethodChannel _channel = MethodChannel(_channelName);
  
  @override
  Future<bool> purchaseProduct(String productId) async {
    try {
      if (Platform.isAndroid) {
        // Use RevenueCat for Android
        final result = await _channel.invokeMethod('purchaseProduct', {
          'productId': productId,
        });
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Android Store purchase error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> restorePurchases() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('restorePurchases');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Android Store restore error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> hasActiveSubscription(String productId) async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('hasActiveSubscription', {
          'productId': productId,
        });
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Android Store subscription check error: $e');
      return false;
    }
  }
  
  @override
  Future<ProductDetails?> getProductDetails(String productId) async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('getProductDetails', {
          'productId': productId,
        });
        
        if (result != null) {
          return ProductDetails(
            id: result['id'] ?? productId,
            title: result['title'] ?? 'Premium Subscription',
            description: result['description'] ?? 'Unlimited repositories with AI features',
            price: result['price'] ?? '\$9.99',
            currencyCode: result['currencyCode'] ?? 'USD',
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Android Store product details error: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    // Cleanup Android Store resources if needed
  }
}

/// Mock Store Service for testing and unsupported platforms
class MockStoreService implements PlatformIAPService {
  @override
  Future<bool> purchaseProduct(String productId) async {
    debugPrint('Mock Store: Purchase requested for $productId');
    // Simulate successful purchase for testing
    return true;
  }
  
  @override
  Future<bool> restorePurchases() async {
    debugPrint('Mock Store: Restore purchases requested');
    // Simulate successful restore for testing
    return true;
  }
  
  @override
  Future<bool> hasActiveSubscription(String productId) async {
    debugPrint('Mock Store: Subscription check for $productId');
    // Simulate no active subscription for testing
    return false;
  }
  
  @override
  Future<ProductDetails?> getProductDetails(String productId) async {
    debugPrint('Mock Store: Product details for $productId');
    // Return mock product details for testing
    return const ProductDetails(
      id: 'crypticdash_premium_yearly',
      title: 'Premium Subscription (Mock)',
      description: 'Unlimited repositories with AI features - Mock Store',
      price: '\$9.99',
      currencyCode: 'USD',
    );
  }
  
  @override
  void dispose() {
    // No cleanup needed for mock service
  }
}
