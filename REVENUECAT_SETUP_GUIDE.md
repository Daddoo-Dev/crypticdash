# RevenueCat Integration Setup Guide for CrypticDash

## Overview

This guide will walk you through setting up RevenueCat for subscription management across iOS, macOS, and Android platforms.

## Prerequisites

✅ **RevenueCat Account**: You already have this  
✅ **Apple Developer Account**: You already have this  
✅ **Google Play Console**: You already have this  
✅ **CrypticDash Project**: Already created in RevenueCat  

## Step 1: Get RevenueCat API Keys

### 1.1 Login to RevenueCat Dashboard
- Go to [app.revenuecat.com](https://app.revenuecat.com)
- Select your **crypticdash** project

### 1.2 Navigate to API Keys
- Go to **Project Settings** → **API Keys**
- You'll see separate API keys for each platform

### 1.3 Copy API Keys
- **iOS API Key**: Copy the iOS App Store key
- **Android API Key**: Copy the Google Play key  
- **macOS API Key**: Copy the macOS App Store key

## Step 2: Update Configuration File

### 2.1 Open RevenueCat Config
Edit `lib/config/revenuecat_config.dart`:

```dart
class RevenueCatConfig {
  // Replace these with your actual API keys
  static const String iosApiKey = 'appl_YOUR_ACTUAL_IOS_KEY';
  static const String androidApiKey = 'goog_YOUR_ACTUAL_ANDROID_KEY';
  static const String macosApiKey = 'appl_YOUR_ACTUAL_MACOS_KEY';
  
  // These should match your RevenueCat configuration
  static const String premiumProductId = 'crypticdash_premium_yearly';
  static const String premiumEntitlementId = 'premium';
}
```

## Step 3: Configure Products in RevenueCat

### 3.1 Create Product
- Go to **Products** → **Add Product**
- **Product ID**: `crypticdash_premium_yearly`
- **Type**: Subscription
- **Duration**: 1 Year
- **Price**: $9.99

### 3.2 Create Entitlement
- Go to **Entitlements** → **Add Entitlement**
- **Entitlement ID**: `premium`
- **Product**: Link to `crypticdash_premium_yearly`

### 3.3 Create Offering
- Go to **Offerings** → **Add Offering**
- **Offering ID**: `default`
- **Products**: Add `crypticdash_premium_yearly`

## Step 4: Configure App Store Connect (iOS/macOS)

### 4.1 Create In-App Purchase
- Go to [App Store Connect](https://appstoreconnect.apple.com)
- Select your app
- **Features** → **In-App Purchases** → **+**
- **Product ID**: `crypticdash_premium_yearly`
- **Type**: Auto-Renewable Subscription
- **Duration**: 1 Year
- **Price**: $9.99

### 4.2 Configure Subscription Group
- Create a subscription group if you don't have one
- Add your product to the group
- Set subscription levels and pricing

## Step 5: Configure Google Play Console (Android)

### 5.1 Create Subscription Product
- Go to [Google Play Console](https://play.google.com/console)
- Select your app
- **Monetize** → **Products** → **Subscriptions** → **Create**
- **Product ID**: `crypticdash_premium_yearly`
- **Name**: Premium Subscription
- **Billing Period**: 1 Year
- **Price**: $9.99

### 5.2 Configure Subscription
- Set subscription details
- Configure grace period
- Set up trial period if desired

## Step 6: Test the Integration

### 6.1 Build and Run
```bash
flutter clean
flutter pub get
flutter run
```

### 6.2 Check RevenueCat Initialization
- Look for "RevenueCat initialized successfully" in debug console
- If you see "API key not configured", check your config file

### 6.3 Test Purchase Flow
- Navigate to subscription screen
- Try to purchase premium
- Check RevenueCat dashboard for events

## Step 7: Platform-Specific Setup

### 7.1 iOS Setup
- Ensure your app has in-app purchase capability
- Test with sandbox accounts
- Verify receipt validation

### 7.2 Android Setup
- Ensure billing permission is added
- Test with test accounts
- Verify purchase token validation

### 7.3 macOS Setup
- Ensure your app is properly signed
- Test with sandbox accounts
- Verify StoreKit integration

## Troubleshooting

### Common Issues

#### 1. "API key not configured"
- Check `revenuecat_config.dart` file
- Ensure API keys are copied correctly
- Restart the app after changes

#### 2. "RevenueCat initialization failed"
- Check API key format
- Verify internet connectivity
- Check RevenueCat dashboard for errors

#### 3. "Product not found"
- Verify product ID matches exactly
- Check RevenueCat offerings configuration
- Ensure product is active in store

#### 4. "Purchase failed"
- Check sandbox/test account setup
- Verify product configuration in stores
- Check RevenueCat logs

### Debug Mode

Enable detailed logging in `revenuecat_config_service.dart`:

```dart
await Purchases.setLogLevel(LogLevel.debug);
```

## Next Steps

### 1. Test on All Platforms
- iOS simulator/device
- Android emulator/device  
- macOS app

### 2. Implement Error Handling
- Add user-friendly error messages
- Handle network failures gracefully
- Add retry logic

### 3. Add Analytics
- Track conversion rates
- Monitor subscription metrics
- Analyze user behavior

### 4. Prepare for Production
- Switch to production API keys
- Test with real accounts
- Submit for store review

## Support Resources

- **RevenueCat Documentation**: [docs.revenuecat.com](https://docs.revenuecat.com)
- **RevenueCat Support**: [support.revenuecat.com](https://support.revenuecat.com)
- **Flutter In-App Purchase**: [pub.dev/packages/purchases_flutter](https://pub.dev/packages/purchases_flutter)

## Configuration Checklist

- [ ] RevenueCat API keys copied to config
- [ ] Product created in RevenueCat
- [ ] Entitlement configured
- [ ] Offering created
- [ ] App Store Connect product configured
- [ ] Google Play Console product configured
- [ ] App tested on all platforms
- [ ] Error handling implemented
- [ ] Ready for production

---

**Note**: Keep your API keys secure and never commit them to version control. Consider using environment variables or secure key management for production builds.
