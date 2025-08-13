import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/github_repository.dart';

class GitHubService extends ChangeNotifier {
  static const String _tokenKey = 'github_access_token';
  String? _accessToken;
  final String _baseUrl = 'https://api.github.com';

  String? get accessToken => _accessToken;

  GitHubService() {
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_tokenKey);
      if (storedToken != null && storedToken.isNotEmpty) {
        _accessToken = storedToken;
        debugPrint('Loaded stored GitHub token');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading stored token: $e');
    }
  }

  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    
    // Save token to persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      debugPrint('Saved GitHub token to persistent storage');
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
    
    notifyListeners();
  }

  Future<void> clearAccessToken() async {
    _accessToken = null;
    
    // Remove token from persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      debugPrint('Cleared GitHub token from persistent storage');
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
    
    notifyListeners();
  }

  Future<bool> hasValidToken() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      return false;
    }
    
    // Test if the stored token is still valid
    return await testConnection();
  }

  Future<bool> testConnection() async {
    if (_accessToken == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  Future<List<GitHubRepository>> getUserRepositories() async {
    if (_accessToken == null) {
      throw Exception('No access token provided');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/repos?sort=updated&per_page=100'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> reposJson = json.decode(response.body);
        return reposJson.map((repo) => GitHubRepository.fromJson(repo)).toList();
      } else {
        throw Exception('Failed to fetch repositories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching repositories: $e');
      rethrow;
    }
  }

  Future<String?> getFileContent(String owner, String repo, String path) async {
    if (_accessToken == null) {
      throw Exception('No access token provided');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$repo/contents/$path'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> fileJson = json.decode(response.body);
        debugPrint('GitHub API response for $path: ${fileJson.keys}');
        
        if (fileJson['type'] == 'file' && fileJson['content'] != null) {
          final encodedContent = fileJson['content'] as String;
          debugPrint('Content length: ${encodedContent.length}');
          
          try {
            // Clean the base64 string by removing newlines and spaces
            final cleanContent = encodedContent.replaceAll(RegExp(r'[\n\r\s]'), '');
            debugPrint('Cleaned content length: ${cleanContent.length}');
            
            // Decode base64 content
            final content = utf8.decode(base64.decode(cleanContent));
            debugPrint('Successfully decoded content, length: ${content.length}');
            return content;
          } catch (decodeError) {
            debugPrint('Base64 decode error: $decodeError');
            debugPrint('Raw content: ${encodedContent.substring(0, 100)}...');
            return null;
          }
        }
      } else if (response.statusCode == 404) {
        // File not found
        debugPrint('File $path not found (404)');
        return null;
      } else {
        debugPrint('Failed to fetch file $path: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching file $path: $e');
      return null;
    }
    
    return null;
  }

  Future<String?> getFileSha(String owner, String repo, String path) async {
    if (_accessToken == null) {
      throw Exception('No access token provided');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$repo/contents/$path'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> content = json.decode(response.body);
        return content['sha'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching file SHA: $e');
      return null;
    }
  }

  Future<bool> createOrUpdateFile(
    String owner,
    String repo,
    String path,
    String content,
    String message, {
    String? sha,
  }) async {
    if (_accessToken == null) {
      throw Exception('No access token provided');
    }

    try {
      final Map<String, dynamic> body = {
        'message': message,
        'content': base64.encode(utf8.encode(content)),
      };

      if (sha != null) {
        body['sha'] = sha;
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/repos/$owner/$repo/contents/$path'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating/updating file: $e');
      return false;
    }
  }
}
