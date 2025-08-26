# CrypticDash Hybrid Subscription System

## Overview

CrypticDash implements a hybrid subscription management system that combines:
- **Appwrite** for subscription state management and user data
- **Platform-specific IAP services** for actual billing and purchase processing
- **Unified subscription logic** across all platforms

## Architecture

### Core Components

1. **IAPService** (`lib/services/iap_service.dart`)
   - Main subscription service that orchestrates all subscription operations
   - Manages Appwrite integration for user data and subscription state
   - Routes IAP operations to platform-specific services

2. **Platform IAP Services** (`lib/services/platform_iap_services.dart`)
   - `WindowsStoreService`: Windows Store integration via method channels
   - `MacOSStoreService`: macOS App Store integration (RevenueCat compatible)
   - `IOSStoreService`: iOS App Store integration (RevenueCat compatible)
   - `AndroidStoreService`: Google Play Store integration (RevenueCat compatible)
   - `MockStoreService`: Testing and development fallback

3. **Appwrite Backend**
   - Database: `dashbase` (ID: `68ac64ea0032f91f0fc7`)
   - Collections: `users`, `repository_tracking`, `subscription_events`
   - Project ID: `nyc-68ac6493003072efa8c5`

## Subscription Tiers

### Free Tier
- 1 repository limit
- 30-day trial period
- Basic AI features

### Premium Tier ($9.99/year)
- Unlimited repositories
- Full AI features
- Cross-device synchronization

## Platform Support

### Windows
- **Current**: Method channel integration with Windows Store APIs
- **Implementation**: `WindowsStoreService` in `platform_iap_services.dart`
- **Status**: Basic structure ready, needs native Windows Store SDK integration

### macOS
- **Current**: Method channel integration with App Store
- **Implementation**: `MacOSStoreService` in `platform_iap_services.dart`
- **Status**: Ready for RevenueCat integration

### iOS
- **Current**: Method channel integration with App Store
- **Implementation**: `IOSStoreService` in `platform_iap_services.dart`
- **Status**: Ready for RevenueCat integration

### Android
- **Current**: Method channel integration with Google Play
- **Implementation**: `AndroidStoreService` in `platform_iap_services.dart`
- **Status**: Ready for RevenueCat integration

## Implementation Details

### Method Channel Integration

Each platform service uses Flutter method channels to communicate with native code:

```dart
// Example: Windows Store Service
static const String _channelName = 'windows_store_service';
static const MethodChannel _channel = MethodChannel(_channelName);

Future<bool> purchaseProduct(String productId) async {
  try {
    if (Platform.isWindows) {
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
```

### Appwrite Integration

The system automatically syncs subscription data with Appwrite:

```dart
// Save user subscription to Appwrite
Future<void> _saveUserToAppwrite() async {
  try {
    final userData = {
      'userId': _currentUserId,
      'subscriptionStatus': _subscriptionStatus.toString(),
      'trialStartDate': _trialStartDate?.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // Create or update user document
    // ... implementation details
  } catch (e) {
    debugPrint('Error saving user to Appwrite: $e');
  }
}
```

## Setup Instructions

### 1. Appwrite Configuration

Ensure your `.env` file contains:
```
APPWRITE_API_SECRET=your_secret_here
```

### 2. Platform-Specific Setup

#### Windows
- Windows Store developer account required
- App must be published to Windows Store
- Implement native Windows Store SDK calls in method channel handlers

#### macOS/iOS
- Apple Developer account required
- App Store Connect setup
- RevenueCat integration (recommended)

#### Android
- Google Play Console account required
- App must be published to Google Play
- RevenueCat integration (recommended)

### 3. Testing

Use the `MockStoreService` for development and testing:
```dart
// Automatically selected for unsupported platforms
if (Platform.isWindows) {
  _platformService = WindowsStoreService();
} else if (Platform.isMacOS) {
  _platformService = MacOSStoreService();
} else if (Platform.isIOS) {
  _platformService = IOSStoreService();
} else if (Platform.isAndroid) {
  _platformService = AndroidStoreService();
} else {
  _platformService = MockStoreService(); // For testing
}
```

## RevenueCat Integration

For iOS, macOS, and Android, RevenueCat provides:
- Subscription management
- Receipt validation
- Analytics and insights
- Cross-platform subscription sync

### Implementation Steps

1. **Add RevenueCat SDK** to platform-specific projects
2. **Configure products** in App Store Connect/Google Play Console
3. **Update method channel handlers** to use RevenueCat APIs
4. **Test subscription flows** on each platform

## Windows Store Integration

### Current Status
- Basic method channel structure implemented
- Mock responses for testing
- Ready for native Windows Store SDK integration

### Next Steps
1. **Implement native Windows Store calls** in method channel handlers
2. **Add Windows Store product configuration**
3. **Test purchase and restore flows**
4. **Handle subscription status updates**

## Subscription Flow

### Purchase Flow
1. User initiates purchase
2. Platform-specific service handles payment
3. On success, subscription status updated in Appwrite
4. Local state synchronized
5. UI updated to reflect premium status

### Restore Flow
1. User requests purchase restoration
2. Platform-specific service checks for existing purchases
3. Subscription status restored from platform
4. Appwrite data synchronized
5. Local state updated

### Trial Management
1. Trial start date tracked in Appwrite
2. 30-day trial period enforced
3. Automatic fallback to free tier after trial
4. Repository limits applied based on subscription status

## Error Handling

The system includes comprehensive error handling:
- Platform-specific errors logged and handled gracefully
- Fallback to stored data when Appwrite unavailable
- Mock service for development and testing
- User-friendly error messages

## Future Enhancements

1. **Real-time subscription updates** via Appwrite webhooks
2. **Advanced analytics** and subscription metrics
3. **Family sharing** support for iOS/macOS
4. **Promotional offers** and discount codes
5. **Subscription management portal** for users

## Troubleshooting

### Common Issues

1. **Method channel not found**
   - Ensure platform-specific service is properly registered
   - Check method channel names match between Flutter and native code

2. **Appwrite connection failed**
   - Verify API keys and project configuration
   - Check network connectivity
   - Ensure Appwrite service is running

3. **Subscription not syncing**
   - Check user authentication status
   - Verify Appwrite database permissions
   - Review subscription event logging

### Debug Mode

Enable debug logging in `IAPService`:
```dart
debugPrint('Current user ID: $_currentUserId');
debugPrint('Subscription status: $_subscriptionStatus');
debugPrint('Trial days remaining: ${getTrialDaysRemaining()}');
```

## Support

For issues or questions:
1. Check this documentation
2. Review Appwrite logs
3. Test with MockStoreService
4. Verify platform-specific configurations
