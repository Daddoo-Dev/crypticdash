import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../config/revenuecat_config.dart';


/// Service for managing Stripe user authentication and account creation
/// Replaces Appwrite with Stripe Customer management
class StripeUserService extends ChangeNotifier {
  static final Logger _logger = Logger();
  static const Uuid _uuid = Uuid();
  
  // Base URLs
  static const String _stripeApiUrl = 'https://api.stripe.com/v1';
  
  // Stripe service reference
  dynamic _stripeService;
  
  // Current user state
  String? _currentUserId;
  String? _currentCustomerId;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  
  // Getters
  String? get currentUserId => _currentUserId;
  String? get currentCustomerId => _currentCustomerId;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  
  StripeUserService() {
    _initializeStripe();
  }
  
  /// Set the Stripe service reference
  void setStripeService(dynamic stripeService) {
    _stripeService = stripeService;
    _logger.d('StripeUserService: Stripe service connected');
  }
  
  /// Initialize Stripe client
  void _initializeStripe() {
    _checkExistingSession();
    _isInitialized = true;
    _logger.d('StripeUserService: Initialized successfully');
    notifyListeners();
  }
  
  /// Check if there's an existing Stripe customer session
  Future<void> _checkExistingSession() async {
    try {
      // For Stripe, we don't have sessions like Appwrite
      // We'll check authentication status when needed
      _isAuthenticated = false;
      _currentUserId = null;
      _currentCustomerId = null;
    } catch (e) {
      _logger.d('No existing Stripe session: $e');
      _isAuthenticated = false;
      _currentUserId = null;
      _currentCustomerId = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Ensure user has Stripe customer data - called for existing users
  Future<void> ensureUserDataExists({
    required String githubUsername,
    required int githubUserId,
    String? email,
    String? displayName,
  }) async {
    try {
      // First, try to create or get Stripe customer account
      final stripeCustomerId = await createOrGetUserAccount(
        githubUsername: githubUsername,
        githubUserId: githubUserId,
        email: email,
        displayName: displayName,
      );
      
      if (stripeCustomerId != null) {
        // Now we have a Stripe customer, we can access the customer data
        _currentUserId = githubUserId.toString();
        _currentCustomerId = stripeCustomerId;
        _isAuthenticated = true;
        _logger.i('Ensured Stripe user data exists: $_currentUserId (Customer: $_currentCustomerId)');
        
        // Set the current user in Stripe service for subscription checking
        _setStripeUser(_currentUserId!);
        
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error ensuring user data exists: $e', error: e, stackTrace: StackTrace.current);
    }
  }
  
  /// Create or get Stripe customer account for GitHub user
  Future<String?> createOrGetUserAccount({
    required String githubUsername,
    required int githubUserId,
    String? email,
    String? displayName,
  }) async {
    try {
      // Check if customer already exists in Stripe
      final existingCustomer = await _getCustomerByGitHubId(githubUserId.toString());
      
      if (existingCustomer != null) {
        // Customer exists, check if we need to update the email
        final currentEmail = existingCustomer['email'];
        if (email != null && email != currentEmail) {
          // Update the email if it's different
          try {
            await _updateCustomerEmail(
              existingCustomer['id'],
              email,
            );
            _logger.i('Updated email for existing customer: $email');
          } catch (e) {
            _logger.e('Error updating email: $e', error: e, stackTrace: StackTrace.current);
          }
        }
        
        _currentUserId = githubUserId.toString();
        _currentCustomerId = existingCustomer['id'];
        _isAuthenticated = true;
        _logger.d('Found existing Stripe customer: $_currentCustomerId');
        notifyListeners();
        return _currentCustomerId;
      }
      
      // Create new customer in Stripe
      final customerData = {
        'email': email ?? 'no-email@placeholder.com',
        'name': displayName ?? githubUsername,
        'metadata[github_id]': githubUserId.toString(),
        'metadata[github_username]': githubUsername,
        'metadata[user_id]': _uuid.v4(),
      };
      
      final response = await http.post(
        Uri.parse('$_stripeApiUrl/customers'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: customerData,
      );
      
      if (response.statusCode == 200) {
        final customer = jsonDecode(response.body);
        _currentUserId = githubUserId.toString();
        _currentCustomerId = customer['id'];
        _isAuthenticated = true;
        _logger.i('Created new Stripe customer: $_currentCustomerId');
        notifyListeners();
        return _currentCustomerId;
      } else {
        _logger.e('Failed to create Stripe customer: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error creating/getting user account: $e', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }
  
  /// Get customer by GitHub ID from Stripe
  Future<Map<String, dynamic>?> _getCustomerByGitHubId(String githubId) async {
    try {
      final response = await http.get(
        Uri.parse('$_stripeApiUrl/customers?limit=100'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final customers = data['data'] as List;
        
        for (final customer in customers) {
          final metadata = customer['metadata'] as Map<String, dynamic>?;
          if (metadata != null && metadata['github_id'] == githubId) {
            return customer;
          }
        }
      }
      return null;
    } catch (e) {
      _logger.e('Error getting customer by GitHub ID: $e', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }
  
  /// Update customer email in Stripe
  Future<void> _updateCustomerEmail(String customerId, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_stripeApiUrl/customers/$customerId'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'email': email},
      );
      
      if (response.statusCode != 200) {
        _logger.e('Failed to update customer email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.e('Error updating customer email: $e', error: e, stackTrace: StackTrace.current);
    }
  }
  
  /// Set current user in Stripe service
  void _setStripeUser(String userId) {
    if (_stripeService != null) {
      try {
        _stripeService.setCurrentUser(userId);
        _logger.d('Set current user in Stripe service: $userId');
      } catch (e) {
        _logger.e('Error setting current user in Stripe service: $e');
      }
    }
  }
  
  /// Update last login timestamp
  Future<void> updateLastLogin() async {
    try {
      if (_currentCustomerId == null) return;
      
      final response = await http.post(
        Uri.parse('$_stripeApiUrl/customers/$_currentCustomerId'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'metadata[last_login]': DateTime.now().toIso8601String(),
        },
      );
      
      if (response.statusCode == 200) {
        _logger.d('Updated last login timestamp');
      } else {
        _logger.e('Failed to update last login: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error updating last login: $e', error: e, stackTrace: StackTrace.current);
    }
  }
  
  /// Get current user data from Stripe
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      if (_currentCustomerId == null) return null;
      
      final response = await http.get(
        Uri.parse('$_stripeApiUrl/customers/$_currentCustomerId'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
        },
      );
      
      if (response.statusCode == 200) {
        final customer = jsonDecode(response.body);
        return {
          'id': customer['id'],
          'email': customer['email'],
          'name': customer['name'],
          'metadata': customer['metadata'],
          'created': customer['created'],
        };
      }
      return null;
    } catch (e) {
      _logger.e('Error getting current user data: $e', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }
  
  /// Sign out user
  Future<void> signOut() async {
    _currentUserId = null;
    _currentCustomerId = null;
    _isAuthenticated = false;
    _logger.i('User signed out');
    notifyListeners();
  }
  
  /// Check if user has premium subscription
  Future<bool> hasPremiumSubscription() async {
    try {
      if (_currentCustomerId == null) return false;
      
      final response = await http.get(
        Uri.parse('$_stripeApiUrl/subscriptions?customer=$_currentCustomerId&limit=100'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subscriptions = data['data'] as List;
        
        for (final subscription in subscriptions) {
          if (subscription['status'] == 'active') {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      _logger.e('Error checking premium subscription: $e', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }
  
  /// Update subscription status in customer metadata
  Future<void> updateSubscriptionStatus(String status) async {
    try {
      if (_currentCustomerId == null) return;
      
      final response = await http.post(
        Uri.parse('$_stripeApiUrl/customers/$_currentCustomerId'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'metadata[subscription_status]': status,
        },
      );
      
      if (response.statusCode == 200) {
        _logger.d('Updated subscription status: $status');
      } else {
        _logger.e('Failed to update subscription status: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error updating subscription status: $e', error: e, stackTrace: StackTrace.current);
    }
  }
}
