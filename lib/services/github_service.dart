import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/github_repository.dart';
import 'logging_service.dart';

class GitHubService extends ChangeNotifier {
  static const String _tokenKey = 'github_access_token';
  String? _accessToken;
  final String _baseUrl = 'https://api.github.com';

  String? get accessToken => _accessToken;

  GitHubService() {
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    LoggingService.debug('GitHubService: _loadStoredToken called');
    try {
      final prefs = await SharedPreferences.getInstance();
      LoggingService.debug('GitHubService: Got SharedPreferences instance');
      
      final storedToken = prefs.getString(_tokenKey);
      LoggingService.debug('GitHubService: Stored token from SharedPreferences: ${storedToken != null ? "exists" : "null"}');
      
      if (storedToken != null && storedToken.isNotEmpty) {
        _accessToken = storedToken;
        LoggingService.success('GitHubService: Loaded stored GitHub token, length: ${storedToken.length}');
        notifyListeners();
      } else {
        LoggingService.warning('GitHubService: No stored token found or token is empty');
      }
    } catch (e) {
      LoggingService.error('GitHubService: Error loading stored token: $e', e, StackTrace.current);
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
    LoggingService.debug('GitHubService: hasValidToken called');
    LoggingService.debug('GitHubService: _accessToken is null: ${_accessToken == null}');
    LoggingService.debug('GitHubService: _accessToken is empty: ${_accessToken?.isEmpty ?? true}');
    
    if (_accessToken == null || _accessToken!.isEmpty) {
      LoggingService.warning('GitHubService: No token available, returning false');
      return false;
    }
    
    LoggingService.debug('GitHubService: Token exists, testing connection...');
    // Test if the stored token is still valid
    final isValid = await testConnection();
    LoggingService.debug('GitHubService: Connection test result: $isValid');
    return isValid;
  }

    Future<bool> testConnection() async {
    LoggingService.debug('GitHubService: testConnection called');
    if (_accessToken == null) {
      LoggingService.warning('GitHubService: No access token for connection test');
      return false;
    }

    try {
      LoggingService.debug('GitHubService: Making HTTP request to $_baseUrl/user');
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      LoggingService.debug('GitHubService: Response status code: ${response.statusCode}');
      LoggingService.debug('GitHubService: Response body: ${response.body}');
      
      final isValid = response.statusCode == 200;
      LoggingService.debug('GitHubService: Connection test result: $isValid');
      return isValid;
    } catch (e) {
      LoggingService.error('GitHubService: Connection test failed: $e', e, StackTrace.current);
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
        
        // Debug: Log the first few repositories to see their structure
        debugPrint('=== GitHub Repositories Debug ===');
        for (int i = 0; i < reposJson.length && i < 3; i++) {
          final repo = reposJson[i];
          debugPrint('Repo $i:');
          debugPrint('  name: ${repo['name']}');
          debugPrint('  full_name: ${repo['full_name']}');
          debugPrint('  owner.login: ${repo['owner']?['login']}');
          debugPrint('  html_url: ${repo['html_url']}');
        }
        debugPrint('=== End Debug ===');
        
        return reposJson.map((repo) => GitHubRepository.fromJson(repo)).toList();
      } else {
        throw Exception('Failed to fetch repositories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching repositories: $e');
      rethrow;
    }
  }

  /// Fetch the authenticated user's information from GitHub
  Future<Map<String, dynamic>?> getAuthenticatedUser() async {
    if (_accessToken == null) {
      throw Exception('No access token provided');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        debugPrint('=== Authenticated User Debug ===');
        debugPrint('User ID: ${userData['id']}');
        debugPrint('Username: ${userData['login']}');
        debugPrint('Name: ${userData['name']}');
        debugPrint('Email: ${userData['email']}');
        debugPrint('=== End Debug ===');
        return userData;
      } else {
        debugPrint('Failed to fetch user info: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
      return null;
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

    debugPrint('Attempting to create/update file: $owner/$repo/$path');
    debugPrint('Message: $message');
    debugPrint('Content length: ${content.length}');
    debugPrint('SHA provided: ${sha ?? 'none'}');
    debugPrint('Token available: ${_accessToken != null}');

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

      debugPrint('GitHub API response status: ${response.statusCode}');
      debugPrint('GitHub API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('File successfully created/updated');
        return true;
      } else {
        debugPrint('GitHub API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception in createOrUpdateFile: $e');
      return false;
    }
  }


  Future<bool> createOrUpdateTODOMD(
    String owner,
    String repo,
    String content,
    String message,
  ) async {
    try {
      // First, try to get the current file to see if it exists
      String? currentSha;
      try {
        final currentFile = await getFileContent(owner, repo, 'TODO.md');
        if (currentFile != null) {
          // Extract SHA from the file info
          final fileInfo = json.decode(currentFile);
          currentSha = fileInfo['sha'];
        }
      } catch (e) {
        // File doesn't exist yet, that's okay for creation
        LoggingService.debug('TODO.md does not exist yet, will create new file');
      }

      final success = await createOrUpdateFile(
        owner,
        repo,
        'TODO.md',
        content,
        message,
        sha: currentSha,
      );

      if (success) {
        LoggingService.success('Successfully created/updated TODO.md in $owner/$repo');
      } else {
        LoggingService.error('Failed to create/update TODO.md in $owner/$repo');
      }

      return success;
    } catch (e) {
      LoggingService.error('Error creating/updating TODO.md: $e', e, StackTrace.current);
      return false;
    }
  }

  /// Get the contents of a directory (files and subdirectories)
  Future<List<Map<String, dynamic>>> getDirectoryContents(String owner, String repo, [String path = '']) async {
    try {
      final url = 'https://api.github.com/repos/$owner/$repo/contents/$path';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> contents = json.decode(response.body);
        return contents.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to get directory contents: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting directory contents: $e');
    }
  }

  /// Recursively explore repository structure and return all files and directories
  Future<Map<String, dynamic>> exploreRepositoryStructure(String owner, String repo) async {
    final structure = <String, dynamic>{
      'files': <String>[],
      'directories': <String>[],
      'fileTree': <String, dynamic>{},
    };
    
    try {
      await _exploreDirectory(owner, repo, '', structure['fileTree']);
      
      // Extract all files and directories from the tree
      _extractPathsFromTree(structure['fileTree'], structure['files'], structure['directories']);
      
      return structure;
    } catch (e) {
      throw Exception('Error exploring repository structure: $e');
    }
  }
  
  Future<void> _exploreDirectory(String owner, String repo, String path, Map<String, dynamic> tree) async {
    try {
      final contents = await getDirectoryContents(owner, repo, path);
      
      for (final item in contents) {
        final name = item['name'] as String;
        final type = item['type'] as String;
        final fullPath = path.isEmpty ? name : '$path/$name';
        
        if (type == 'file') {
          tree[name] = {
            'type': 'file',
            'path': fullPath,
            'size': item['size'],
            'sha': item['sha'],
          };
        } else if (type == 'dir') {
          tree[name] = {
            'type': 'directory',
            'path': fullPath,
            'contents': <String, dynamic>{},
          };
          
          // Recursively explore subdirectory
          await _exploreDirectory(owner, repo, fullPath, tree[name]['contents']);
        }
      }
    } catch (e) {
      // If we can't access a directory, mark it as inaccessible
      tree['_error'] = 'Could not access: $e';
    }
  }
  
  void _extractPathsFromTree(Map<String, dynamic> tree, List<String> files, List<String> directories) {
    tree.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        if (value['type'] == 'file') {
          files.add(value['path']);
        } else if (value['type'] == 'directory') {
          directories.add(value['path']);
          // Recursively explore subdirectories
          if (value['contents'] != null) {
            _extractPathsFromTree(value['contents'], files, directories);
          }
        }
      }
    });
  }
}
