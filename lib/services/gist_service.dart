import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GistService {
  static const String _gistFileName = 'crypticdash-preferences.json';
  static const String _gistDescription = 'CrypticDash app preferences and repository selections';
  
  final String _githubToken;
  
  GistService(this._githubToken);
  
  /// Creates or updates the preferences Gist
  Future<bool> createOrUpdatePreferencesGist(Map<String, dynamic> preferences) async {
    try {
      debugPrint('GistService: Creating/updating preferences Gist');
      final gistId = await _findExistingPreferencesGist();
      
      if (gistId != null) {
        debugPrint('GistService: Found existing Gist, updating: $gistId');
        return await _updateExistingGist(gistId, preferences);
      } else {
        debugPrint('GistService: No existing Gist found, creating new one');
        return await _createNewGist(preferences);
      }
    } catch (e) {
      debugPrint('Error in createOrUpdatePreferencesGist: $e');
      return false;
    }
  }
  
  /// Retrieves preferences from the Gist
  Future<Map<String, dynamic>?> getPreferences() async {
    try {
      debugPrint('GistService: Retrieving preferences from Gist');
      final gistId = await _findExistingPreferencesGist();
      
      if (gistId == null) {
        debugPrint('GistService: No preferences Gist found');
        return null;
      }
      
      debugPrint('GistService: Found preferences Gist: $gistId');
      final response = await http.get(
        Uri.parse('https://api.github.com/gists/$gistId'),
        headers: {
          'Authorization': 'token $_githubToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      if (response.statusCode == 200) {
        final gistData = json.decode(response.body);
        final files = gistData['files'] as Map<String, dynamic>;
        final preferencesFile = files[_gistFileName];
        
        if (preferencesFile != null) {
          final content = preferencesFile['content'] as String;
          debugPrint('GistService: Successfully retrieved preferences');
          return json.decode(content) as Map<String, dynamic>;
        }
      }
      
      debugPrint('GistService: Failed to retrieve preferences, status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error in getPreferences: $e');
      return null;
    }
  }
  
  /// Finds existing preferences Gist by description
  Future<String?> _findExistingPreferencesGist() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/gists'),
        headers: {
          'Authorization': 'token $_githubToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      if (response.statusCode == 200) {
        final gists = json.decode(response.body) as List<dynamic>;
        
        for (final gist in gists) {
          if (gist['description'] == _gistDescription) {
            return gist['id'] as String;
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error in _findExistingPreferencesGist: $e');
      return null;
    }
  }
  
  /// Creates a new preferences Gist
  Future<bool> _createNewGist(Map<String, dynamic> preferences) async {
    try {
      final gistData = {
        'description': _gistDescription,
        'public': false,
        'files': {
          _gistFileName: {
            'content': json.encode(preferences),
          },
        },
      };
      
      final response = await http.post(
        Uri.parse('https://api.github.com/gists'),
        headers: {
          'Authorization': 'token $_githubToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: json.encode(gistData),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error in _createNewGist: $e');
      return false;
    }
  }
  
  /// Updates existing preferences Gist
  Future<bool> _updateExistingGist(String gistId, Map<String, dynamic> preferences) async {
    try {
      final gistData = {
        'description': _gistDescription,
        'files': {
          _gistFileName: {
            'content': json.encode(preferences),
          },
        },
      };
      
      final response = await http.patch(
        Uri.parse('https://api.github.com/gists/$gistId'),
        headers: {
          'Authorization': 'token $_githubToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: json.encode(gistData),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error in _updateExistingGist: $e');
      return false;
    }
  }
  
  /// Deletes the preferences Gist
  Future<bool> deletePreferencesGist() async {
    try {
      final gistId = await _findExistingPreferencesGist();
      
      if (gistId == null) {
        return true; // Already doesn't exist
      }
      
      final response = await http.delete(
        Uri.parse('https://api.github.com/gists/$gistId'),
        headers: {
          'Authorization': 'token $_githubToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Error in deletePreferencesGist: $e');
      return false;
    }
  }
}
