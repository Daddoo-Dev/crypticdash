# CrypticDash Appwrite Database Schema

## Database Details
- **Project ID**: `nyc-68ac6493003072efa8c5`
- **Database ID**: `68ac64ea0032f91f0fc7`
- **Database Name**: `dashbase`
- **Endpoint**: `https://cloud.appwrite.io`

## Collections

### 1. users
**Collection ID**: `users`

**Attributes**:
- `userId` - String (255), Required: ✓ (GitHub user ID)
- `githubUsername` - String (255), Required: ✓
- `email` - String (255), Required: ✓
- `displayName` - String (255), Required: ✗
- `subscriptionStatus` - String (255), Required: ✓
- `trialStartDate` - Datetime, Required: ✗
- `subscriptionExpiryDate` - Datetime, Required: ✗
- `createdAt` - Datetime, Required: ✓
- `updatedAt` - Datetime, Required: ✗
- `lastLoginAt` - Datetime, Required: ✗

**Indexes**:
- `userId_unique` (key) on `userId`
- `githubUsername_unique` (key) on `githubUsername`
- `email_unique` (key) on `email`

**Permissions**: `read("user:{{user.id}}")`, `write("user:{{user.id}}")`

### 2. repository_tracking
**Collection ID**: `repository_tracking`

**Attributes**:
- `userId` - String (255), Required: ✓
- `repoId` - String (255), Required: ✓
- `repoName` - String (255), Required: ✓
- `addedAt` - Datetime, Required: ✓
- `isActive` - Boolean, Required: ✓

**Indexes**:
- `userId_repoId_unique` (key) on `userId`, `repoId`
- `userId_index` (key) on `userId`

**Permissions**: `read("user:{{user.id}}")`, `write("user:{{user.id}}")`

### 3. subscription_events
**Collection ID**: `subscription_events`

**Attributes**:
- `userId` - String (255), Required: ✓
- `eventType` - String (255), Required: ✓
- `oldStatus` - String (255), Required: ✗
- `newStatus` - String (255), Required: ✓
- `timestamp` - Datetime, Required: ✓
- `platform` - String (255), Required: ✗

**Indexes**:
- `userId_index` (key) on `userId`
- `timestamp_index` (key) on `timestamp`

**Permissions**: `read("user:{{user.id}}")`, `write("user:{{user.id}}")`

## Notes
- All collections use user-scoped permissions
- String fields use 255 character limit
- Datetime fields store ISO 8601 format
- Boolean fields default to false
- Required fields must be provided when creating documents
- The `userId` field stores the GitHub user ID as a string for consistency
