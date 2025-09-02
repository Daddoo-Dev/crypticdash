import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../config/revenuecat_config.dart';
import 'iap_service.dart';
import 'github_service.dart';
import 'revenuecat_service.dart';

/// Windows Store Service using Microsoft Store Services
class WindowsStoreService implements PlatformIAPService {
  static const String _channelName = 'windows_store_service';
  static const MethodChannel _channel = MethodChannel(_channelName);
  
  /// Get the service instance using Provider
  static WindowsStoreService of(BuildContext context) {
    return Provider.of<WindowsStoreService>(context, listen: false);
  }
  
  /// Initialize the service with Provider
  static void initializeWithProvider(BuildContext context) {
    Provider.of<WindowsStoreService>(context, listen: false);
  }
  
  @override
  Future<bool> purchaseProduct(String productId) async {
    try {
      if (Platform.isWindows) {
        // Use Windows Store Services SDK
        final result = await _channel.invokeMethod('purchaseProduct', {
          'productId': productId,
        });
        
        // If purchase successful, sync to Stripe using the imported services
        if (result == true) {
          await _syncPurchaseToStripe(productId);
        }
        
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Windows Store purchase error: $e');
      return false;
    }
  }
  
  /// Sync successful purchase to Stripe
  Future<void> _syncPurchaseToStripe(String productId) async {
    try {
      // Get current user ID from GitHub service
      final githubService = GitHubService();
      final userData = await githubService.getAuthenticatedUser();
      
      if (userData != null) {
        final userId = userData['id'].toString();
        
        // Get purchase details from Windows Store
        final purchaseDetails = await _getPurchaseDetails(productId);
        
        // Create customer in Stripe with store purchase metadata
        final stripeService = StripeService();
        await stripeService.createCustomerFromStorePurchase(
          userId: userId,
          source: 'microsoft_store',
          storeTransactionId: purchaseDetails['transactionId'] ?? 'unknown',
          storeReceipt: purchaseDetails['receipt'] ?? '',
          subscriptionData: {
            'status': 'active',
            'expires_at': purchaseDetails['expiresAt'] ?? '',
          },
        );
      }
    } catch (e) {
      debugPrint('Error syncing purchase to Stripe: $e');
    }
  }
  
  /// Get purchase details from Windows Store
  Future<Map<String, dynamic>> _getPurchaseDetails(String productId) async {
    try {
      final result = await _channel.invokeMethod('getProductDetails', {
        'productId': productId,
      });
      
      if (result != null) {
        return {
          'transactionId': 'ms_${DateTime.now().millisecondsSinceEpoch}',
          'receipt': result.toString(),
          'expiresAt': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        };
      }
      
      return {};
    } catch (e) {
      debugPrint('Error getting purchase details: $e');
      return {};
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

/// macOS App Store Service using Stripe
class MacOSStoreService implements PlatformIAPService {
  final _logger = Logger();
  static const String _stripeApiUrl = 'https://api.stripe.com/v1';
  
  @override
  Future<bool> purchaseProduct(String productId) async {
    try {
      if (Platform.isMacOS) {
        // Create Stripe Checkout Session for macOS
        final response = await http.post(
          Uri.parse('$_stripeApiUrl/checkout/sessions'),
          headers: {
            'Authorization': 'Bearer ${StripeConfig.secretKey}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'payment_method_types[]': 'card',
            'line_items[0][price]': StripeConfig.premiumPriceId,
            'mode': 'subscription',
            'success_url': 'https://crypticdash.com/success',
            'cancel_url': 'https://crypticdash.com/cancel',
          },
        );
        
        if (response.statusCode == 200) {
          final sessionData = jsonDecode(response.body);
          final checkoutUrl = sessionData['url'];
          
          if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
            await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      _logger.e('macOS Stripe purchase error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> restorePurchases() async {
    try {
      if (Platform.isMacOS) {
        // For Stripe, we check subscription status via API
        // This would typically be done through the main Stripe service
        _logger.i('macOS Stripe restore - check subscription status via main service');
        return false; // Let main service handle this
      }
      return false;
    } catch (e) {
      _logger.e('macOS Stripe restore error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> hasActiveSubscription(String productId) async {
    try {
      if (Platform.isMacOS) {
        // Check subscription status via Stripe API
        // This would typically be done through the main Stripe service
        _logger.i('macOS Stripe subscription check - use main service');
        return false; // Let main service handle this
      }
      return false;
    } catch (e) {
      _logger.e('macOS Stripe subscription check error: $e');
      return false;
    }
  }
  
  @override
  Future<ProductDetails?> getProductDetails(String productId) async {
    try {
      if (Platform.isMacOS) {
        return ProductDetails(
          id: StripeConfig.premiumProductId,
          title: StripeConfig.productName,
          description: StripeConfig.productDescription,
          price: StripeConfig.productPrice,
          currencyCode: 'USD',
        );
      }
      return null;
    } catch (e) {
      _logger.e('macOS Stripe product details error: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    // No cleanup needed for Stripe
  }
}

/// iOS App Store Service using Stripe
class IOSStoreService implements PlatformIAPService {
  final _logger = Logger();
  static const String _stripeApiUrl = 'https://api.stripe.com/v1';
  
  @override
  Future<bool> purchaseProduct(String productId) async {
    try {
      if (Platform.isIOS) {
        // Create Stripe Checkout Session for iOS
        final response = await http.post(
          Uri.parse('$_stripeApiUrl/checkout/sessions'),
          headers: {
            'Authorization': 'Bearer ${StripeConfig.secretKey}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'payment_method_types[]': 'card',
            'line_items[0][price]': StripeConfig.premiumPriceId,
            'mode': 'subscription',
            'success_url': 'https://crypticdash.com/success',
            'cancel_url': 'https://crypticdash.com/cancel',
          },
        );
        
        if (response.statusCode == 200) {
          final sessionData = jsonDecode(response.body);
          final checkoutUrl = sessionData['url'];
          
          if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
            await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      _logger.e('iOS Stripe purchase error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> restorePurchases() async {
    try {
      if (Platform.isIOS) {
        // For Stripe, we check subscription status via API
        _logger.i('iOS Stripe restore - check subscription status via main service');
        return false; // Let main service handle this
      }
      return false;
    } catch (e) {
      _logger.e('iOS Stripe restore error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> hasActiveSubscription(String productId) async {
    try {
      if (Platform.isIOS) {
        // Check subscription status via Stripe API
        _logger.i('iOS Stripe subscription check - use main service');
        return false; // Let main service handle this
      }
      return false;
    } catch (e) {
      _logger.e('iOS Stripe subscription check error: $e');
      return false;
    }
  }
  
  @override
  Future<ProductDetails?> getProductDetails(String productId) async {
    try {
      if (Platform.isIOS) {
        return ProductDetails(
          id: StripeConfig.premiumProductId,
          title: StripeConfig.productName,
          description: StripeConfig.productDescription,
          price: StripeConfig.productPrice,
          currencyCode: 'USD',
        );
      }
      return null;
    } catch (e) {
      _logger.e('iOS Stripe product details error: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    // No cleanup needed for Stripe
  }
}

/// Android Google Play Store Service using Stripe
class AndroidStoreService implements PlatformIAPService {
  final _logger = Logger();
  static const String _stripeApiUrl = 'https://api.stripe.com/v1';
  
  @override
  Future<bool> purchaseProduct(String productId) async {
    try {
      if (Platform.isAndroid) {
        // Create Stripe Checkout Session for Android
        final response = await http.post(
          Uri.parse('$_stripeApiUrl/checkout/sessions'),
          headers: {
            'Authorization': 'Bearer ${StripeConfig.secretKey}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'payment_method_types[]': 'card',
            'line_items[0][price]': StripeConfig.premiumPriceId,
            'mode': 'subscription',
            'success_url': 'https://crypticdash.com/success',
            'cancel_url': 'https://crypticdash.com/cancel',
          },
        );
        
        if (response.statusCode == 200) {
          final sessionData = jsonDecode(response.body);
          final checkoutUrl = sessionData['url'];
          
          if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
            await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      _logger.e('Android Stripe purchase error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> restorePurchases() async {
    try {
      if (Platform.isAndroid) {
        // For Stripe, we check subscription status via API
        _logger.i('Android Stripe restore - check subscription status via main service');
        return false; // Let main service handle this
      }
      return false;
    } catch (e) {
      _logger.e('Android Stripe restore error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> hasActiveSubscription(String productId) async {
    try {
      if (Platform.isAndroid) {
        // Check subscription status via Stripe API
        _logger.i('Android Stripe subscription check - use main service');
        return false; // Let main service handle this
      }
      return false;
    } catch (e) {
      _logger.e('Android Stripe subscription check error: $e');
      return false;
    }
  }
  
  @override
  Future<ProductDetails?> getProductDetails(String productId) async {
    try {
      if (Platform.isAndroid) {
        return ProductDetails(
          id: StripeConfig.premiumProductId,
          title: StripeConfig.productName,
          description: StripeConfig.productDescription,
          price: StripeConfig.productPrice,
          currencyCode: 'USD',
        );
      }
      return null;
    } catch (e) {
      _logger.e('Android Stripe product details error: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    // No cleanup needed for Stripe
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
    // Return Stripe-based product details for testing
    return ProductDetails(
      id: StripeConfig.premiumProductId,
      title: StripeConfig.productName,
      description: StripeConfig.productDescription,
      price: StripeConfig.productPrice,
      currencyCode: 'USD',
    );
  }
  
  @override
  void dispose() {
    // No cleanup needed for mock service
  }
}
