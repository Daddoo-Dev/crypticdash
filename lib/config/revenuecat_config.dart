/// RevenueCat API Keys Configuration
/// 
/// Replace these placeholder values with your actual RevenueCat API keys
/// You can find these in your RevenueCat dashboard under Project Settings > API Keys
class RevenueCatConfig {
  // iOS App Store API Key
  static const String iosApiKey = 'YOUR_IOS_API_KEY_HERE';
  
  // Android Google Play API Key  
  static const String androidApiKey = 'YOUR_ANDROID_API_KEY_HERE';
  
  // macOS App Store API Key
  static const String macosApiKey = 'YOUR_MACOS_API_KEY_HERE';
  
  // Web Billing API Keys (for Windows)
  static const String webSandboxApiKey = 'rcb_sb_tnraznTUArQJrjOzfBwvLIjLx';
  static const String webPublicApiKey = 'rcb_lMfKkTmAMfKsgveMVNSpNThwgCAV';
  
  // Product IDs - these should match what you configure in RevenueCat
  static const String premiumProductId = 'crypticdash_premium_yearly';
  
  // Entitlement ID - this should match what you configure in RevenueCat
  static const String premiumEntitlementId = 'premium';
  
  /// Get the appropriate API key for the current platform
  static String getApiKeyForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios':
        return iosApiKey;
      case 'android':
        return androidApiKey;
      case 'macos':
        return macosApiKey;
      default:
        throw ArgumentError('Unsupported platform: $platform');
    }
  }
  
  /// Check if all API keys are configured
  static bool get isConfigured {
    return iosApiKey != 'YOUR_IOS_API_KEY_HERE' &&
           androidApiKey != 'YOUR_ANDROID_API_KEY_HERE' &&
           macosApiKey != 'YOUR_MACOS_API_KEY_HERE';
  }
}
