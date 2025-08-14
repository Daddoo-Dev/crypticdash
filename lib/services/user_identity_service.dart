import 'package:shared_preferences/shared_preferences.dart';

class UserIdentityService {
  static const String _usernameKey = 'github_username';
  static const String _userIdKey = 'github_user_id';
  static const String _userNameKey = 'github_user_name';
  static const String _userEmailKey = 'github_user_email';

  /// Store the authenticated user's GitHub identity
  static Future<void> storeUserIdentity({
    required String username,
    required int userId,
    String? name,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setInt(_userIdKey, userId);
    if (name != null) await prefs.setString(_userNameKey, name);
    if (email != null) await prefs.setString(_userEmailKey, email);
  }

  /// Get the stored GitHub username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// Get the stored GitHub user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  /// Get the stored GitHub user's display name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Get the stored GitHub user's email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Check if user identity is stored
  static Future<bool> hasStoredIdentity() async {
    final username = await getUsername();
    final userId = await getUserId();
    return username != null && userId != null;
  }

  /// Clear stored user identity (for logout)
  static Future<void> clearUserIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }

  /// Get all stored user identity data
  static Future<Map<String, dynamic>> getAllUserData() async {
    return {
      'username': await getUsername(),
      'userId': await getUserId(),
      'name': await getUserName(),
      'email': await getUserEmail(),
    };
  }
}
