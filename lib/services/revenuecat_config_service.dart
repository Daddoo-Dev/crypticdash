import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/revenuecat_config.dart';

/// RevenueCat configuration service for CrypticDash
class RevenueCatConfigService {
  
  /// Initialize RevenueCat for the current platform
  static Future<void> initialize() async {
    try {
      String apiKey;
      
      if (Platform.isIOS) {
        apiKey = RevenueCatConfig.iosApiKey;
      } else if (Platform.isAndroid) {
        apiKey = RevenueCatConfig.androidApiKey;
      } else if (Platform.isMacOS) {
        apiKey = RevenueCatConfig.macosApiKey;
      } else if (Platform.isWindows) {
        // Use environment variables for Web Billing
        final isDebug = kDebugMode;
        if (isDebug) {
          apiKey = dotenv.env['REVENUECAT_WEB_SANBOX_API'] ?? RevenueCatConfig.webSandboxApiKey;
        } else {
          apiKey = dotenv.env['REVENUECAT_WEB_PUBLIC_API'] ?? RevenueCatConfig.webPublicApiKey;
        }
      } else {
        debugPrint('RevenueCat not supported on this platform');
        return;
      }
      
      // Check if API key is configured
      if (apiKey == 'YOUR_IOS_API_KEY_HERE' || 
          apiKey == 'YOUR_ANDROID_API_KEY_HERE' || 
          apiKey == 'YOUR_MACOS_API_KEY_HERE') {
        debugPrint('RevenueCat API key not configured for ${Platform.operatingSystem}');
        return;
      }
      
      // Configure RevenueCat
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      
      // Set user ID if available (you can integrate this with your auth system)
      // await Purchases.logIn('user_id');
      
      debugPrint('RevenueCat initialized successfully for ${Platform.operatingSystem}');
    } catch (e) {
      debugPrint('Error initializing RevenueCat: $e');
    }
  }
  
  /// Get the current customer info
  static Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('Error getting customer info: $e');
      return null;
    }
  }
  
  /// Check if user has premium entitlement
  static Future<bool> hasPremiumEntitlement() async {
    try {
      final customerInfo = await getCustomerInfo();
      return customerInfo?.entitlements.active.containsKey('premium') ?? false;
    } catch (e) {
      debugPrint('Error checking premium entitlement: $e');
      return false;
    }
  }
  
  /// Get available offerings
  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error getting offerings: $e');
      return null;
    }
  }
  
  /// Purchase a package
  static Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      return await Purchases.purchasePackage(package);
    } catch (e) {
      debugPrint('Error purchasing package: $e');
      return null;
    }
  }
  
  /// Restore purchases
  static Future<CustomerInfo?> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return null;
    }
  }
}
