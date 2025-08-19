# GitHub Gist Sync for CrypticDash

## Overview

CrypticDash now supports cross-device synchronization of repository selections using GitHub Gist. This feature allows you to maintain the same repository selections across multiple devices (Windows, macOS, etc.) without manually re-selecting repositories on each device.

## How It Works

### 1. **Gist Creation**
- When you enable cross-device sync, CrypticDash creates a private GitHub Gist
- The Gist contains your repository selection preferences in JSON format
- The Gist is private and only visible to you

### 2. **Data Structure**
The Gist stores the following information:
```json
{
  "selectedRepos": [123, 456, 789],
  "lastUpdated": "2025-01-17T15:30:00Z",
  "version": "1.0"
}
```

### 3. **Synchronization Process**
- **On App Startup**: Automatically syncs from Gist if newer data exists
- **On Selection Change**: Automatically syncs to Gist when you select/deselect repositories
- **Manual Sync**: Force sync option available in Settings

## Setup

### 1. **Enable Cross-Device Sync**
1. Go to **Settings** → **GitHub Integration**
2. Toggle **Cross-Device Sync** to ON
3. Confirm the dialog to enable sync

### 2. **Automatic Initialization**
- The Gist service automatically initializes when you first enable sync
- Uses your existing GitHub authentication token
- Creates the preferences Gist on first use

## Features

### ✅ **Automatic Sync**
- Syncs on app startup
- Syncs when repository selections change
- Handles conflicts by using the most recent data

### ✅ **Privacy & Security**
- Private Gist (only visible to you)
- Uses existing GitHub authentication
- No additional permissions required

### ✅ **Error Handling**
- Graceful fallback to local storage if Gist unavailable
- Automatic retry on network issues
- Detailed logging for debugging

### ✅ **User Control**
- Enable/disable sync anytime
- Force manual sync when needed
- View last sync timestamp

## Settings

### **Cross-Device Sync Toggle**
- Enable/disable the feature
- Shows current sync status

### **Last Gist Sync**
- Displays when data was last synced
- Manual refresh button available

### **Sync Status**
- Visual indicator of sync health
- Green checkmark when working properly

## Troubleshooting

### **Sync Not Working**
1. Check your GitHub authentication
2. Verify internet connection
3. Check the debug logs for error messages
4. Try forcing a manual sync

### **Data Not Syncing**
1. Ensure cross-device sync is enabled
2. Check if you're logged into the same GitHub account
3. Verify the Gist was created successfully
4. Check the last sync timestamp

### **Conflicts**
- The app automatically resolves conflicts by using the most recent data
- Local changes take precedence if there are issues

## Technical Details

### **Gist Location**
- **Filename**: `crypticdash-preferences.json`
- **Description**: "CrypticDash app preferences and repository selections"
- **Visibility**: Private
- **Access**: Via GitHub API using your personal access token

### **API Endpoints Used**
- `GET /gists` - Find existing preferences Gist
- `POST /gists` - Create new preferences Gist
- `PATCH /gists/{gist_id}` - Update existing preferences Gist
- `GET /gists/{gist_id}` - Retrieve preferences

### **Data Flow**
```
Local Selection Change → Save to Local Storage → Sync to Gist → Update Timestamp
                                                                    ↓
App Startup → Check Gist → Compare Timestamps → Load Newer Data → Update Local Storage
```

## Benefits

1. **Seamless Experience**: Same repository selections across all devices
2. **No Manual Setup**: Automatic sync without user intervention
3. **Privacy First**: Private Gist, no data shared with third parties
4. **Reliable**: Built on GitHub's robust infrastructure
5. **Fast**: Lightweight JSON data, quick sync operations

## Future Enhancements

- **Conflict Resolution UI**: Better handling of sync conflicts
- **Sync History**: Track all sync operations
- **Selective Sync**: Choose which preferences to sync
- **Backup/Restore**: Export/import preferences manually
