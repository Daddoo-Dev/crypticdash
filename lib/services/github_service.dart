import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/github_repository.dart';
import 'package:logger/logger.dart';

class GitHubService extends ChangeNotifier {
  static const String _tokenKey = 'github_access_token';
  String? _accessToken;
  final String _baseUrl = 'https://api.github.com';
  final _logger = Logger();

  String? get accessToken => _accessToken;

  GitHubService() {
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    _logger.d('GitHubService: _loadStoredToken called');
    try {
      final prefs = await SharedPreferences.getInstance();
      _logger.d('GitHubService: Got SharedPreferences instance');
      
      final storedToken = prefs.getString(_tokenKey);
      _logger.d('GitHubService: Stored token from SharedPreferences: ${storedToken != null ? "exists" : "null"}');
      
      if (storedToken != null && storedToken.isNotEmpty) {
        _accessToken = storedToken;
        _logger.i('GitHubService: Loaded stored GitHub token, length: ${storedToken.length}');
        notifyListeners();
      } else {
        _logger.w('GitHubService: No stored token found or token is empty');
      }
    } catch (e) {
      _logger.e('GitHubService: Error loading stored token: $e', error: e, stackTrace: StackTrace.current);
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
    _logger.d('GitHubService: hasValidToken called');
    
    // Ensure token is loaded first
    if (_accessToken == null) {
      _logger.d('GitHubService: Token not loaded, loading now...');
      await _loadStoredToken();
    }
    
    _logger.d('GitHubService: _accessToken is null: ${_accessToken == null}');
    _logger.d('GitHubService: _accessToken is empty: ${_accessToken?.isEmpty ?? true}');
    
    if (_accessToken == null || _accessToken!.isEmpty) {
      _logger.w('GitHubService: No token available, returning false');
      return false;
    }
    
    _logger.d('GitHubService: Token exists, testing connection...');
    // Test if the stored token is still valid
    final isValid = await testConnection();
    _logger.d('GitHubService: Connection test result: $isValid');
    
    // If connection is valid, ensure Appwrite data exists
    if (isValid) {
      try {
        final userData = await getAuthenticatedUser();
        if (userData != null) {
          _logger.d('GitHubService: Got user data, ensuring Appwrite data exists');
          // This will be called from the auth flow with access to Appwrite service
          // For now, just log that we have the user data
          _logger.d('GitHubService: User ${userData['login']} (ID: ${userData['id']}) authenticated');
        }
      } catch (e) {
        _logger.d('GitHubService: Error getting user data: $e');
      }
    }
    
    return isValid;
  }

    Future<bool> testConnection() async {
    _logger.d('GitHubService: testConnection called');
    if (_accessToken == null) {
      _logger.w('GitHubService: No access token for connection test');
      return false;
    }

    try {
      _logger.d('GitHubService: Making HTTP request to $_baseUrl/user');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      _logger.d('GitHubService: Response status code: ${response.statusCode}');
      _logger.d('GitHubService: Response body: ${response.body}');
      
      final isValid = response.statusCode == 200;
      _logger.d('GitHubService: Connection test result: $isValid');
      return isValid;
    } catch (e) {
      _logger.e('GitHubService: Connection test failed: $e', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<List<GitHubRepository>> getUserRepositories() async {
    if (_accessToken == null) {
      throw Exception('No access token provided');
    }

    try {
      // Get authenticated user info to determine personal username
      final userData = await getAuthenticatedUser();
      final personalUsername = userData?['login'];
      
      // First try the standard user repos endpoint with type=all
      final response = await http.get(
        Uri.parse('$_baseUrl/user/repos?sort=updated&per_page=100&type=all'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> reposJson = json.decode(response.body);
        
        // Debug: Log the first few repositories to see their structure
        debugPrint('=== GitHub Repositories Debug ===');
        debugPrint('Personal username: $personalUsername');
        debugPrint('Total repos found: ${reposJson.length}');
        for (int i = 0; i < reposJson.length && i < 5; i++) {
          final repo = reposJson[i];
          final ownerLogin = repo['owner']['login'];
          final source = (ownerLogin == personalUsername) ? 'personal' : 'organization';
          debugPrint('Repo $i:');
          debugPrint('  name: ${repo['name']}');
          debugPrint('  full_name: ${repo['full_name']}');
          debugPrint('  owner.login: $ownerLogin');
          debugPrint('  source: $source');
          debugPrint('  private: ${repo['private']}');
          debugPrint('  html_url: ${repo['html_url']}');
        }
        debugPrint('=== End Debug ===');
        
        // Process repositories and determine source
        final repositories = reposJson.map((repo) {
          // Determine if this is a personal or organization repository
          final ownerLogin = repo['owner']['login'];
          final source = (ownerLogin == personalUsername) ? 'personal' : 'organization';
          
          // Add source information to the repo data
          final repoWithSource = Map<String, dynamic>.from(repo);
          repoWithSource['source'] = source;
          
          return GitHubRepository.fromJson(repoWithSource);
        }).toList();
        
        // If we found organization repos, return them
        if (repositories.any((repo) => repo.source == 'organization')) {
          debugPrint('Found organization repositories: ${repositories.where((repo) => repo.source == 'organization').length}');
          return repositories;
        }
        
        // If no organization repos found, try fetching organizations directly
        debugPrint('No organization repos found in user/repos, trying organizations endpoint...');
        final orgRepos = await _fetchOrganizationRepositories(personalUsername!);
        repositories.addAll(orgRepos);
        
        return repositories;
      } else {
        throw Exception('Failed to fetch repositories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching repositories: $e');
      rethrow;
    }
  }

  Future<List<GitHubRepository>> _fetchOrganizationRepositories(String personalUsername) async {
    try {
      // Get user's organizations
      final orgsResponse = await http.get(
        Uri.parse('$_baseUrl/user/orgs'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      debugPrint('=== Organization Debug ===');
      debugPrint('Organizations API response status: ${orgsResponse.statusCode}');
      debugPrint('Organizations API response body: ${orgsResponse.body}');
      
      if (orgsResponse.statusCode == 200) {
        final List<dynamic> orgsJson = json.decode(orgsResponse.body);
        debugPrint('Found ${orgsJson.length} organizations');
        
        if (orgsJson.isEmpty) {
          debugPrint('No organizations found. This could mean:');
          debugPrint('1. Token lacks read:org permission');
          debugPrint('2. User is not a member of any organizations');
          debugPrint('3. Organizations are private and token lacks access');
        }
        
        final List<GitHubRepository> allOrgRepos = [];
        
        for (final org in orgsJson) {
          final orgName = org['login'];
          debugPrint('Fetching repos for organization: $orgName');
          
          try {
            final orgReposResponse = await http.get(
              Uri.parse('$_baseUrl/orgs/$orgName/repos?sort=updated&per_page=100'),
              headers: {
                'Authorization': 'token $_accessToken',
                'Accept': 'application/vnd.github.v3+json',
              },
            );

            debugPrint('Organization $orgName repos API response status: ${orgReposResponse.statusCode}');
            
            if (orgReposResponse.statusCode == 200) {
              final List<dynamic> orgReposJson = json.decode(orgReposResponse.body);
              debugPrint('Found ${orgReposJson.length} repos in organization $orgName');
              
              final orgRepos = orgReposJson.map((repo) {
                final repoWithSource = Map<String, dynamic>.from(repo);
                repoWithSource['source'] = 'organization';
                return GitHubRepository.fromJson(repoWithSource);
              }).toList();
              
              allOrgRepos.addAll(orgRepos);
            } else {
              debugPrint('Failed to fetch repos for organization $orgName: ${orgReposResponse.statusCode}');
              debugPrint('Response body: ${orgReposResponse.body}');
            }
          } catch (e) {
            debugPrint('Error fetching repos for organization $orgName: $e');
          }
        }
        
        debugPrint('=== End Organization Debug ===');
        return allOrgRepos;
      } else {
        debugPrint('Failed to fetch organizations: ${orgsResponse.statusCode}');
        debugPrint('This suggests the token lacks read:org permission');
        debugPrint('=== End Organization Debug ===');
      }
    } catch (e) {
      debugPrint('Error fetching organizations: $e');
      debugPrint('=== End Organization Debug ===');
    }
    
    return [];
  }

  /// Fetch the authenticated user's information from GitHub
  Future<Map<String, dynamic>?> getAuthenticatedUser() async {
    if (_accessToken == null) {
      throw Exception('No access token provided');
    }

    try {
      // First, get the user profile data
      final userResponse = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Authorization': 'token $_accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        
        // Try to get email addresses separately
        try {
          final emailResponse = await http.get(
            Uri.parse('$_baseUrl/user/emails'),
            headers: {
              'Authorization': 'token $_accessToken',
              'Accept': 'application/vnd.github.v3+json',
            },
          );
          
          if (emailResponse.statusCode == 200) {
            final emails = json.decode(emailResponse.body) as List;
            if (emails.isNotEmpty) {
              // Find the primary email or use the first one
              final primaryEmail = emails.firstWhere(
                (email) => email['primary'] == true,
                orElse: () => emails.first,
              );
              userData['email'] = primaryEmail['email'];
            }
          }
        } catch (e) {
          // If email fetch fails, keep the original email (might be null)
          debugPrint('Could not fetch email addresses: $e');
        }
        
        debugPrint('=== Authenticated User Debug ===');
        debugPrint('User ID: ${userData['id']}');
        debugPrint('Username: ${userData['login']}');
        debugPrint('Name: ${userData['name']}');
        debugPrint('Email: ${userData['email']}');
        debugPrint('=== End Debug ===');
        return userData;
      } else {
        debugPrint('Failed to fetch user info: ${userResponse.statusCode}');
        debugPrint('Response body: ${userResponse.body}');
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
      // Use proper filename format: {reponame}-TODO.md
      final todoFileName = '$repo-TODO.md';
      
      // First, try to get the current file SHA to see if it exists
      String? currentSha;
      try {
        currentSha = await getFileSha(owner, repo, todoFileName);
        if (currentSha != null) {
          _logger.d('Found existing $todoFileName with SHA: $currentSha');
        }
      } catch (e) {
        // File doesn't exist yet, that's okay for creation
        _logger.d('$todoFileName does not exist yet, will create new file');
      }

      final success = await createOrUpdateFile(
        owner,
        repo,
        todoFileName,
        content,
        message,
        sha: currentSha,
      );

      if (success) {
        _logger.i('Successfully created/updated $todoFileName in $owner/$repo');
      } else {
        _logger.e('Failed to create/update $todoFileName in $owner/$repo');
      }

      return success;
    } catch (e) {
      _logger.e('Error creating/updating TODO file: $e', error: e, stackTrace: StackTrace.current);
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

  /// Ensure Appwrite data exists for the authenticated user
  Future<void> ensureAppwriteDataExists() async {
    try {
      if (_accessToken == null || _accessToken!.isEmpty) {
        _logger.d('GitHubService: No token available for Appwrite check');
        return;
      }
      
      final userData = await getAuthenticatedUser();
      if (userData != null) {
        _logger.d('GitHubService: Got user data, ensuring Appwrite data exists');
        // This will be called from the auth flow with access to Appwrite service
        // For now, just log that we have the user data
        _logger.d('GitHubService: User ${userData['login']} (ID: ${userData['id']}) authenticated');
      }
    } catch (e) {
      _logger.d('GitHubService: Error ensuring Appwrite data: $e');
    }
  }
}
