import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/revenuecat_config.dart';

import 'dart:async';

/// Stripe service that works on all platforms including Windows
/// Replaces RevenueCat with Stripe subscription management
class StripeService extends ChangeNotifier {
  static final Logger _logger = Logger();
  
  // Base URLs
  static const String _stripeApiUrl = 'https://api.stripe.com/v1';
  
  // Current user state
  String? _currentUserId;
  String? _currentCustomerId;
  bool _hasPremiumAccess = false;
  bool _isInitialized = false;
  String? _lastCheckoutSessionId;
  
  // Getters
  String? get currentUserId => _currentUserId;
  String? get currentCustomerId => _currentCustomerId;
  bool get hasPremiumAccess => _hasPremiumAccess;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Check if we have the necessary API keys
      final apiKey = StripeConfig.secretKey;
      _logger.d('Stripe service: Secret key length: ${apiKey.length}');
      
      if (apiKey.isEmpty) {
        _logger.w('Stripe secret key not configured');
        _isInitialized = false;
        return;
      }
      
      _isInitialized = true;
      _logger.i('Stripe service initialized successfully');
      _logger.d('Stripe service: Product ID: ${StripeConfig.premiumProductId}');
      _logger.d('Stripe service: Price ID: ${StripeConfig.premiumPriceId}');
      
      // Test the API connection with a simple call to verify it's working
      _logger.i('Stripe service: Testing API connection...');
      try {
        final testResult = await getUserSubscriptionStatus('test_user_123');
        _logger.i('Stripe service: API test successful. Test user status: $testResult');
      } catch (e) {
        _logger.w('Stripe service: API test failed: $e');
      }
      
      // Automatically check subscription status for the current user if we have one
      if (_currentUserId != null) {
        await _checkSubscriptionStatus();
      }
      
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to initialize Stripe service: $e', error: e, stackTrace: StackTrace.current);
      _isInitialized = false;
    }
  }
  
  /// Set the current user ID for subscription checking
  void setCurrentUser(String userId) {
    _currentUserId = userId;
    _logger.d('Stripe service: Set current user: $userId');
    _checkSubscriptionStatus();
  }
  
  /// Check the current user's subscription status
  Future<void> _checkSubscriptionStatus() async {
    if (_currentUserId == null || !_isInitialized) return;
    
    try {
      final status = await getUserSubscriptionStatus(_currentUserId!);
      _hasPremiumAccess = status == 'premium';
      _logger.d('Stripe service: User subscription status: $_hasPremiumAccess');
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to check subscription status: $e', error: e, stackTrace: StackTrace.current);
      _hasPremiumAccess = false;
      notifyListeners();
    }
  }
  
  /// Get user's subscription status from Stripe
  Future<String> getUserSubscriptionStatus(String userId) async {
    try {
      _logger.d('Stripe service: Checking subscription status for user: $userId');
      
      // First, try to find or create customer for this user
      final customerResult = await _findOrCreateCustomer(userId);
      if (!customerResult['success']) {
        _logger.w('Stripe service: Could not find or create customer');
        return 'free';
      }
      
      _currentCustomerId = customerResult['customerId'];
      
      // Get customer's subscriptions
      final response = await http.get(
        Uri.parse('$_stripeApiUrl/subscriptions?customer=$_currentCustomerId&limit=100'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      
      _logger.d('Stripe service: API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.d('Stripe service: API response data: $data');
        
        final subscriptions = data['data'] as List;
        
        if (subscriptions.isNotEmpty) {
          final subscription = subscriptions.first;
          final status = subscription['status'];
          final isActive = status == 'active' || status == 'trialing';
          
          _logger.d('Stripe service: Subscription found, active: $isActive');
          return isActive ? 'premium' : 'expired';
        }
        
        _logger.d('Stripe service: No active subscriptions found');
        return 'free';
      } else {
        _logger.w('Stripe API error: ${response.statusCode} - ${response.body}');
        return 'free';
      }
    } catch (e) {
      _logger.e('Failed to get subscription status: $e', error: e, stackTrace: StackTrace.current);
      return 'free';
    }
  }
  
  /// Find or create customer for user
  Future<Map<String, dynamic>> _findOrCreateCustomer(String userId) async {
    try {
      // Try to find existing customer by metadata
      final response = await http.get(
        Uri.parse('$_stripeApiUrl/customers?limit=100'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final customers = data['data'] as List;
        
        // Find customer with matching user_id metadata
        for (final customer in customers) {
          if (customer['metadata']?['user_id'] == userId) {
            return {
              'success': true,
              'customerId': customer['id'],
              'isNew': false,
            };
          }
        }
      }
      
      // Use fallback email and name for customer creation
      final email = 'user_$userId@crypticdash.com';
      final name = 'User $userId';
      
      // Create new customer if not found
      final createResponse = await http.post(
        Uri.parse('$_stripeApiUrl/customers'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          'name': name,
          'metadata[user_id]': userId,
        },
      );
      
      if (createResponse.statusCode == 200) {
        final customerData = json.decode(createResponse.body);
        _logger.i('Stripe service: Created new customer: ${customerData['id']}');
        return {
          'success': true,
          'customerId': customerData['id'],
          'isNew': true,
        };
      } else {
        _logger.e('Stripe service: Failed to create customer: ${createResponse.statusCode}');
        _logger.e('Stripe service: Error response: ${createResponse.body}');
        return {'success': false, 'error': 'Failed to create customer'};
      }
    } catch (e) {
      _logger.e('Error finding/creating customer: $e', error: e, stackTrace: StackTrace.current);
      return {'success': false, 'error': 'Customer operation failed'};
    }
  }
  
  /// Purchase premium subscription using Stripe Checkout
  Future<bool> purchasePremium() async {
    if (_currentUserId == null || !_isInitialized) return false;
    
    try {
      _logger.i('Stripe service: Using Stripe Checkout for subscription purchase');
      
      // Ensure we have a customer
      final customerResult = await _findOrCreateCustomer(_currentUserId!);
      if (!customerResult['success']) {
        _logger.e('Stripe service: Could not find or create customer');
        return false;
      }
      
      _currentCustomerId = customerResult['customerId'];
      
      // Get available products and prices dynamically
      final productsResult = await _getProductsAndPrices();
      if (!productsResult['success']) {
        _logger.e('Stripe service: Could not get products and prices');
        return false;
      }
      
      final prices = productsResult['prices'] as List;
      if (prices.isEmpty) {
        _logger.e('Stripe service: No prices available');
        return false;
      }
      
      // Use the first available price
      final priceId = prices.first['id'];
      _logger.i('Stripe service: Using price ID: $priceId');
      
      // Create checkout session
      final response = await http.post(
        Uri.parse('$_stripeApiUrl/checkout/sessions'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': _currentCustomerId!,
          'line_items[0][price]': priceId,
          'line_items[0][quantity]': '1',
          'mode': 'subscription',
          'success_url': 'https://crypticdash.com/success?session_id={CHECKOUT_SESSION_ID}',
          'cancel_url': 'https://crypticdash.com/cancel',
          'allow_promotion_codes': 'true',
        },
      );
      
      if (response.statusCode == 200) {
        final sessionData = json.decode(response.body);
        final checkoutUrl = sessionData['url'];
        _lastCheckoutSessionId = sessionData['id'];
        
        _logger.i('Stripe service: Checkout session created successfully: $_lastCheckoutSessionId');
        
        // Launch checkout in browser
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          // Start polling for subscription status confirmation
          _startSubscriptionPolling();
          
          return true;
        } else {
          _logger.e('Stripe service: Cannot launch checkout URL');
          return false;
        }
      } else {
        _logger.e('Stripe service: Failed to create checkout session: ${response.statusCode}');
        _logger.e('Stripe service: Error response body: ${response.body}');
        return false;
      }
      
    } catch (e) {
      _logger.e('Failed to purchase premium: $e', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }
  
  /// Get available products and prices from Stripe
  Future<Map<String, dynamic>> _getProductsAndPrices() async {
    try {
      _logger.i('Stripe service: Fetching products and prices...');
      
      // Get products
      final productsResponse = await http.get(
        Uri.parse('$_stripeApiUrl/products?limit=100'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      
      if (productsResponse.statusCode != 200) {
        _logger.e('Stripe service: Failed to fetch products: ${productsResponse.statusCode}');
        return {'success': false, 'error': 'Failed to fetch products'};
      }
      
      // Get prices
      final pricesResponse = await http.get(
        Uri.parse('$_stripeApiUrl/prices?limit=100'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      
      if (pricesResponse.statusCode != 200) {
        _logger.e('Stripe service: Failed to fetch prices: ${pricesResponse.statusCode}');
        return {'success': false, 'error': 'Failed to fetch prices'};
      }
      
      final products = json.decode(productsResponse.body);
      final prices = json.decode(pricesResponse.body);
      
      _logger.i('Stripe service: Found ${products['data'].length} products and ${prices['data'].length} prices');
      
      // If no products exist, create a test product
      if (products['data'].isEmpty) {
        _logger.i('Stripe service: No products found, creating test product...');
        final testProduct = await _createTestProduct();
        if (testProduct['success']) {
          products['data'] = [testProduct['data']];
          _logger.i('Stripe service: Test product created: ${testProduct['data']['id']}');
        }
      }
      
      // If no prices exist, create a test price
      if (prices['data'].isEmpty && products['data'].isNotEmpty) {
        _logger.i('Stripe service: No prices found, creating test price...');
        final testPrice = await _createTestPrice(products['data'].first['id']);
        if (testPrice['success']) {
          prices['data'] = [testPrice['data']];
          _logger.i('Stripe service: Test price created: ${testPrice['data']['id']}');
        }
      }
      
      return {
        'success': true,
        'products': products['data'],
        'prices': prices['data'],
      };
    } catch (e) {
      _logger.e('Stripe service: Error fetching products and prices: $e');
      return {'success': false, 'error': 'Failed to fetch products and prices'};
    }
  }
  
  /// Create a test product if none exist
  Future<Map<String, dynamic>> _createTestProduct() async {
    try {
      _logger.i('Stripe service: Creating test product...');
      
      final response = await http.post(
        Uri.parse('$_stripeApiUrl/products'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': 'CrypticDash Premium',
          'description': 'Premium subscription for CrypticDash',
          'metadata[test_product]': 'true',
        },
      );
      
      if (response.statusCode == 200) {
        final productData = json.decode(response.body);
        _logger.i('Stripe service: Test product created: ${productData['id']}');
        return {
          'success': true,
          'data': productData,
        };
      } else {
        _logger.e('Stripe service: Failed to create test product: ${response.statusCode}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      _logger.e('Stripe service: Error creating test product: $e');
      return {'success': false, 'error': 'Failed to create test product'};
    }
  }
  
  /// Create a test price for the given product
  Future<Map<String, dynamic>> _createTestPrice(String productId) async {
    try {
      _logger.i('Stripe service: Creating test price for product: $productId...');
      
      final response = await http.post(
        Uri.parse('$_stripeApiUrl/prices'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'product': productId,
          'unit_amount': '999', // $9.99 in cents
          'currency': 'usd',
          'recurring[interval]': 'year',
          'metadata[test_price]': 'true',
        },
      );
      
      if (response.statusCode == 200) {
        final priceData = json.decode(response.body);
        _logger.i('Stripe service: Test price created: ${priceData['id']}');
        return {
          'success': true,
          'data': priceData,
        };
      } else {
        _logger.e('Stripe service: Failed to create test price: ${response.statusCode}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      _logger.e('Stripe service: Error creating test price: $e');
      return {'success': false, 'error': 'Failed to create test price'};
    }
  }
  
  /// Start polling for subscription status after user completes payment
  void _startSubscriptionPolling() {
    _logger.i('Stripe service: Starting subscription status polling...');
    
    // Poll every 3 seconds for up to 10 minutes (more aggressive polling)
    int attempts = 0;
    const maxAttempts = 200; // 10 minutes
    
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      
      if (attempts > maxAttempts) {
        timer.cancel();
        _logger.w('Stripe service: Subscription polling timed out after $maxAttempts attempts');
        return;
      }
      
      _logger.i('Stripe service: Polling attempt $attempts - checking subscription status for user: $_currentUserId');
      
      try {
        // First check checkout session status if we have one
        if (_lastCheckoutSessionId != null) {
          final sessionResult = await checkCheckoutSessionStatus(_lastCheckoutSessionId!);
          if (sessionResult['success'] && sessionResult['status'] == 'complete') {
            _logger.i('Stripe service: Checkout session completed, checking subscription...');
          }
        }
        
        // Force a fresh check by clearing any cached customer ID
        _currentCustomerId = null;
        
        final status = await getUserSubscriptionStatus(_currentUserId!);
        _logger.i('Stripe service: Current subscription status: $status');
        
        if (status == 'premium') {
          _logger.i('Stripe service: Payment confirmed! User now has premium access');
          _hasPremiumAccess = true;
          notifyListeners();
          timer.cancel();
          
          // Show success message to user
          _logger.i('Stripe service: Subscription status updated successfully');
        } else {
          _logger.i('Stripe service: Payment not yet confirmed, status: $status (attempt $attempts/$maxAttempts)');
        }
      } catch (e) {
        _logger.e('Stripe service: Error during subscription polling: $e');
      }
    });
  }
  
  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (_currentUserId == null || !_isInitialized) return false;
    
    try {
      _logger.i('Stripe service: Restoring purchases for user: $_currentUserId');
      
      // Check current subscription status
      await _checkSubscriptionStatus();
      
      _logger.i('Stripe service: Purchases restored');
      return true;
    } catch (e) {
      _logger.e('Failed to restore purchases: $e', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }
  
  /// Manually refresh subscription status
  Future<bool> refreshSubscriptionStatus() async {
    if (_currentUserId == null || !_isInitialized) return false;
    
    try {
      _logger.i('Stripe service: Manually refreshing subscription status for user: $_currentUserId');
      
      // Check current subscription status
      await _checkSubscriptionStatus();
      
      _logger.i('Stripe service: Subscription status refreshed');
      return _hasPremiumAccess;
    } catch (e) {
      _logger.e('Failed to refresh subscription status: $e', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }
  
  /// Check checkout session status
  Future<Map<String, dynamic>> checkCheckoutSessionStatus(String sessionId) async {
    try {
      _logger.i('Stripe service: Checking checkout session status: $sessionId');
      
      final response = await http.get(
        Uri.parse('$_stripeApiUrl/checkout/sessions/$sessionId'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      
      if (response.statusCode == 200) {
        final sessionData = json.decode(response.body);
        _logger.i('Stripe service: Checkout session status: ${sessionData['status']}');
        return {
          'success': true,
          'status': sessionData['status'],
          'data': sessionData,
        };
      } else {
        _logger.e('Stripe service: Failed to get checkout session: ${response.statusCode}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      _logger.e('Stripe service: Error checking checkout session: $e');
      return {'success': false, 'error': 'Failed to check checkout session'};
    }
  }
  
  /// Check if user has access to premium features
  bool hasAccessToFeature(String feature) {
    if (!_isInitialized) return false;
    
    switch (feature) {
      case 'unlimited_repos':
      case 'advanced_analytics':
      case 'priority_support':
        return _hasPremiumAccess;
      default:
        return true; // Free features
    }
  }
  
  /// Get subscription details
  Map<String, dynamic> getSubscriptionDetails() {
    return {
      'hasPremiumAccess': _hasPremiumAccess,
      'currentUserId': _currentUserId,
      'currentCustomerId': _currentCustomerId,
      'isInitialized': _isInitialized,
      'productId': StripeConfig.premiumProductId,
      'priceId': StripeConfig.premiumPriceId,
    };
  }
  
  /// Get user-friendly subscription status
  String getSubscriptionStatusText() {
    if (!_isInitialized) return 'Checking...';
    if (_currentUserId == null) return 'Not logged in';
    return _hasPremiumAccess ? 'Premium' : 'Free';
  }
  
  /// Get subscription status color for UI
  Color getSubscriptionStatusColor() {
    if (!_isInitialized || _currentUserId == null) return Colors.grey;
    return _hasPremiumAccess ? Colors.green : Colors.orange;
  }
}
