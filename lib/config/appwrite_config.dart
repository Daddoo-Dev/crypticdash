import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Stripe Configuration (Replacing Appwrite)
/// 
/// This class provides centralized access to Stripe configuration values
/// to avoid duplication across multiple services
class StripeConfig {
  // Stripe API Keys
  static String get _stripePublicKey => dotenv.env['STRIPE_SANDBOX_PUBLIC_KEY'] ?? '';
  static String get _stripeSecretKey => dotenv.env['STRIPE_SANDBOX_SECRET_KEY'] ?? '';
  
  // Product Configuration from your Stripe Dashboard
  static const String premiumProductId = 'prod_SxsF2cOTVz2LUQ';
  static const String premiumPriceId = 'price_1S1wVHBCL6n8GXMu7giE6zKO';
  
  // Product Details
  static const String productName = 'Annual Subscription';
  static const String productDescription = 'Annual subscription for Cryptic Dash. This will give you access to unlimited repos and AI analysis of your progress on those repos.';
  static const String productPrice = '\$9.99 USD';
  static const String productBillingPeriod = 'Per year';
  
  // Getters for API keys
  static String get publishableKey => _stripePublicKey;
  static String get secretKey => _stripeSecretKey;
  
  // Check if configuration is valid
  static bool get isConfigured {
    return _stripePublicKey.isNotEmpty && _stripeSecretKey.isNotEmpty;
  }
  
  // Validation methods
  static String validateConfiguration() {
    if (!isConfigured) {
      return '❌ Stripe configuration incomplete. Please check your .env file for STRIPE_SANDBOX_PUBLIC_KEY and STRIPE_SANDBOX_SECRET_KEY.';
    }
    
    if (_stripePublicKey.startsWith('pk_test_')) {
      return '✅ Using Stripe SANDBOX mode for testing.';
    }
    
    if (_stripePublicKey.startsWith('pk_live_')) {
      return '⚠️ Using Stripe PRODUCTION mode. Switch to sandbox keys for testing.';
    }
    
    return '✅ Stripe configuration appears valid.';
  }
  
  // Debug information
  static Map<String, dynamic> get debugInfo {
    return {
      'publishableKey': _stripePublicKey.isNotEmpty ? '${_stripePublicKey.substring(0, 8)}...' : 'Not set',
      'secretKey': _stripeSecretKey.isNotEmpty ? '${_stripeSecretKey.substring(0, 8)}...' : 'Not set',
      'productId': premiumProductId,
      'priceId': premiumPriceId,
      'isConfigured': isConfigured,
      'environment': _stripePublicKey.startsWith('pk_test_') ? 'SANDBOX' : 'PRODUCTION',
    };
  }
}
