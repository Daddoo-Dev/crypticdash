# Appwrite Setup for CrypticDash

This guide explains how to set up the required Appwrite collections for CrypticDash's subscription system.

## Overview

CrypticDash uses Appwrite for:
- **User management** and subscription status
- **Repository tracking** across devices
- **Subscription events** audit trail

## Prerequisites

1. **Appwrite Account**: You have an Appwrite account and project
2. **Database**: You have created a database named `dashbase`
3. **Flutter App**: Appwrite Flutter SDK is installed (`appwrite: ^17.1.0`)

## Required Collections

### 1. Users Collection (`users`)
**Purpose**: Store user profiles and subscription data

**Fields**:
- `userId` (string, 255 chars, required) - Unique user identifier
- `email` (string, 255 chars, required) - User's email address
- `subscriptionStatus` (string, 50 chars, required, default: "free") - Current subscription status
- `trialStartDate` (datetime, optional) - When the 30-day trial started
- `subscriptionExpiryDate` (datetime, optional) - When premium subscription expires
- `createdAt` (datetime, required) - Account creation timestamp

**Indexes**:
- `userId_unique` (key) on `userId`
- `email_unique` (key) on `email`

**Permissions**: `read("user:{{user.id}}")`, `write("user:{{user.id}}")`

### 2. Repository Tracking Collection (`repository_tracking`)
**Purpose**: Track repositories across devices for subscription limits

**Fields**:
- `userId` (string, 255 chars, required) - User identifier
- `repoId` (string, 255 chars, required) - GitHub repository ID
- `repoName` (string, 255 chars, required) - Repository name
- `addedAt` (datetime, required) - When repo was added
- `isActive` (boolean, required, default: true) - Whether repo is currently tracked

**Indexes**:
- `userId_repoId_unique` (key) on `userId`, `repoId`
- `userId_index` (key) on `userId`

**Permissions**: `read("user:{{user.id}}")`, `write("user:{{user.id}}")`

### 3. Subscription Events Collection (`subscription_events`)
**Purpose**: Audit trail for subscription changes

**Fields**:
- `userId` (string, 255 chars, required) - User identifier
- `eventType` (string, 100 chars, required) - Type of subscription event
- `oldStatus` (string, 50 chars, optional) - Previous subscription status
- `newStatus` (string, 50 chars, required) - New subscription status
- `timestamp` (datetime, required) - When event occurred
- `platform` (string, 50 chars, optional) - Platform where change occurred

**Indexes**:
- `userId_index` (key) on `userId`
- `timestamp_index` (key) on `timestamp`

**Permissions**: `read("user:{{user.id}}")`, `write("user:{{user.id}}")`

## Setup Instructions

### Option 1: Appwrite Console (Recommended)

1. **Go to Appwrite Console**
   - Navigate to your project
   - Go to "Databases" → "dashbase"

2. **Create Collections**
   - Click "Create Collection" for each collection
   - Use the field builder to add fields with proper types
   - Set permissions as specified above
   - Create indexes as specified above

### Option 2: Flutter Code

Use the provided `AppwriteSetupService` to get setup instructions:

```dart
import 'package:crypticdash/services/appwrite_setup_service.dart';

void main() {
  final setupService = AppwriteSetupService();
  
  // Print setup instructions to console
  setupService.printSetupInstructions();
  
  // Or get as formatted string
  final setupGuide = setupService.getSetupGuide();
  print(setupGuide);
}
```

## Testing the Setup

After creating collections, you can test them:

```dart
import 'package:crypticdash/services/appwrite_setup_test.dart';

void testSetup() {
  AppwriteSetupTest.testSetupService();
}
```

## Integration with Your App

The `AppwriteSetupService` provides:

- **Collection schemas** for reference
- **Setup instructions** for manual creation
- **Formatted guides** for console use

## Next Steps

Once collections are created:

1. **Initialize Appwrite client** in your app
2. **Set up authentication** (GitHub OAuth recommended)
3. **Create subscription service** using these collections
4. **Integrate with existing repo tracking** (keep Gist for cross-device sync)

## Notes

- **Keep Gist for repo tracking**: The existing GitHub Gist approach is still recommended for cross-device protection
- **Appwrite for business logic**: Use Appwrite for subscription management, user accounts, and analytics
- **Hybrid approach**: Best of both worlds - Gist for sync, Appwrite for business logic

## Support

If you encounter issues:
1. Check Appwrite documentation: https://appwrite.io/docs
2. Verify collection permissions and indexes
3. Ensure database ID matches `dashbase`
4. Check Flutter SDK version compatibility
