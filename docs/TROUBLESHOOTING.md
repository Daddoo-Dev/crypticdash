# 🚨 CrypticDash Troubleshooting Guide

This guide helps you resolve common issues and get CrypticDash working properly.

## 🔐 Authentication Issues

### Can't Sign In with GitHub

**Symptoms:**
- OAuth flow fails
- Personal Access Token rejected
- "Authentication failed" error

**Solutions:**

#### 1. Check Internet Connection
```bash
# Test connectivity to GitHub
ping github.com
curl https://api.github.com
```

#### 2. Verify GitHub Status
- Check [GitHub Status](https://www.githubstatus.com/)
- Verify GitHub isn't experiencing outages

#### 3. OAuth Issues
- Clear browser cache and cookies
- Try incognito/private browsing mode
- Check if GitHub OAuth app is configured correctly

#### 4. Personal Access Token Issues
- **Generate new token**: https://github.com/settings/tokens
- **Required scopes**:
  - `repo` (full repository access)
  - `read:user` (read user profile)
- **Token expiration**: Check if token has expired
- **Repository access**: Ensure token has access to target repos

#### 5. Rate Limiting
- GitHub API has rate limits
- Wait 1 hour if you hit rate limits
- Check rate limit status in response headers

### Token Permission Errors

**Symptoms:**
- "Insufficient permissions" error
- Can't access private repositories
- Repository list is empty

**Solutions:**
1. **Check token scopes** in GitHub settings
2. **Verify repository access** - ensure you have access to repos
3. **Check organization permissions** if using org repos
4. **Regenerate token** with correct permissions

## 📱 App Functionality Issues

### Projects Not Loading

**Symptoms:**
- Dashboard shows "No projects found"
- Projects list is empty
- Loading spinner never stops

**Solutions:**

#### 1. Refresh Dashboard
- Pull down to refresh (mobile)
- Click refresh button
- Restart the app

#### 2. Check Project Selection
- Go to **Manage Projects**
- Ensure repositories are selected
- Toggle repositories off/on

#### 3. Verify Repository Access
- Check if repositories still exist
- Verify you still have access
- Check organization membership

#### 4. Re-authenticate
- Sign out and sign back in
- Generate new access token
- Clear app data and restart

### TODOs Not Syncing

**Symptoms:**
- Changes don't save to GitHub
- "Failed to update" errors
- Local changes don't persist

**Solutions:**

#### 1. Check Write Permissions
- Verify token has `repo` scope
- Check repository permissions
- Ensure you can push to the repo

#### 2. Check File Paths
- Verify TODO.md file exists
- Check file naming conventions
- Ensure correct repository path

#### 3. Check GitHub API Status
- Verify GitHub API is responding
- Check rate limiting
- Test API connectivity

#### 4. File Conflicts
- Check if file was modified elsewhere
- Pull latest changes from GitHub
- Resolve merge conflicts if any

### App Crashes

**Symptoms:**
- App closes unexpectedly
- White/black screen
- Unresponsive interface

**Solutions:**

#### 1. Basic Troubleshooting
- **Restart the app**
- **Clear app cache** (if available)
- **Check device storage** - ensure sufficient space
- **Update app** to latest version

#### 2. Platform-Specific Issues

**Android:**
```bash
# Clear app data
Settings > Apps > CrypticDash > Storage > Clear Data

# Check Android version compatibility
# Minimum: API 21 (Android 5.0)
```

**iOS:**
```bash
# Force close and restart
# Check iOS version compatibility
# Minimum: iOS 11.0
```

**Desktop:**
```bash
# Check system requirements
# Verify Flutter runtime
# Check graphics drivers
```

#### 3. Memory Issues
- Close other apps
- Restart device
- Check available RAM

## 🌐 Network Issues

### Connection Problems

**Symptoms:**
- "Network error" messages
- Slow loading times
- Intermittent failures

**Solutions:**

#### 1. Network Diagnostics
```bash
# Test basic connectivity
ping 8.8.8.8
nslookup github.com

# Test GitHub API
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
```

#### 2. Firewall/Proxy Issues
- Check corporate firewall settings
- Configure proxy if required
- Allow CrypticDash through firewall

#### 3. DNS Issues
- Try different DNS servers (8.8.8.8, 1.1.1.1)
- Flush DNS cache
- Check router DNS settings

### API Rate Limiting

**Symptoms:**
- "API rate limit exceeded" errors
- Slow response times
- Intermittent failures

**Solutions:**
1. **Wait for reset** - limits reset hourly
2. **Check current usage** in response headers
3. **Reduce API calls** - don't refresh constantly
4. **Use authenticated requests** - higher limits

## 🔧 Technical Issues

### Build Errors

**Symptoms:**
- App won't compile
- "Build failed" errors
- Missing dependencies

**Solutions:**

#### 1. Flutter Environment
```bash
# Check Flutter version
flutter --version

# Update Flutter
flutter upgrade

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### 2. Dependencies
```bash
# Update dependencies
flutter pub upgrade

# Check for conflicts
flutter pub deps

# Verify pubspec.yaml
flutter analyze
```

#### 3. Platform-Specific Build Issues

**Android:**
```bash
# Check Android SDK
flutter doctor --android-licenses

# Clean Android build
cd android
./gradlew clean
cd ..
flutter run
```

**iOS:**
```bash
# Check Xcode installation
flutter doctor

# Clean iOS build
cd ios
rm -rf build
cd ..
flutter run
```

### Performance Issues

**Symptoms:**
- Slow app response
- High memory usage
- Battery drain

**Solutions:**

#### 1. Optimize Usage
- Don't keep too many projects loaded
- Close unused project details
- Limit background sync frequency

#### 2. Check Device Resources
- Monitor memory usage
- Check CPU usage
- Verify storage space

#### 3. App Settings
- Disable unnecessary features
- Reduce sync frequency
- Use light theme if dark theme causes issues

## 📊 Data Issues

### Missing Projects

**Symptoms:**
- Projects disappeared from dashboard
- Can't find previously added repos
- Repository list incomplete

**Solutions:**

#### 1. Check Repository Status
- Verify repositories still exist
- Check if you still have access
- Verify organization membership

#### 2. Refresh Project List
- Go to **Manage Projects**
- Refresh repository list
- Re-select missing repositories

#### 3. Check GitHub Permissions
- Verify token has correct scopes
- Check repository permissions
- Ensure you can see the repos

### Corrupted Data

**Symptoms:**
- Invalid project information
- TODO items missing
- Progress calculations wrong

**Solutions:**

#### 1. Refresh from GitHub
- Pull latest data from repositories
- Regenerate TODO files if needed
- Check for file corruption

#### 2. Reset Local Data
- Remove and re-add projects
- Clear app cache
- Restart with fresh data

#### 3. Verify File Integrity
- Check TODO.md files on GitHub
- Verify markdown syntax
- Check for encoding issues

## 🆘 Getting Help

### Self-Help Resources
1. **This troubleshooting guide**
2. **User Guide** (`docs/USER_GUIDE.md`)
3. **Developer Guide** (`docs/DEVELOPER_GUIDE.md`)
4. **GitHub repository issues**

### Reporting Issues
When reporting issues, include:

#### Required Information
- **App version**: Check app info
- **Platform**: Android/iOS/Web/Desktop
- **Platform version**: OS version
- **Steps to reproduce**: Detailed steps
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Error messages**: Exact error text
- **Screenshots**: Visual evidence

#### Optional Information
- **Device model**: Hardware information
- **Network environment**: Home/work/mobile
- **Previous versions**: Did it work before?
- **Other apps**: Any conflicts?

### Contact Information
- **GitHub Issues**: [Repository Issues](https://github.com/yourusername/crypticdash/issues)
- **Documentation**: Check docs folder first
- **Community**: Join repository discussions

## 🔍 Diagnostic Tools

### Built-in Diagnostics
- **App logs**: Check console output
- **Error reporting**: Built-in error handling
- **Performance metrics**: Built-in monitoring

### External Tools
- **Flutter Inspector**: Widget debugging
- **GitHub API tester**: Test API calls
- **Network analyzer**: Monitor network traffic

### Log Collection
```bash
# Enable verbose logging
flutter run --verbose

# Check Flutter logs
flutter logs

# Platform-specific logs
# Android: adb logcat
# iOS: Xcode console
# Desktop: System logs
```

---

**Still having issues?** Check the GitHub repository for the latest troubleshooting information or create a new issue with detailed information.
