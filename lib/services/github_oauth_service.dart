import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Conditional import for mobile platforms only
import 'package:flutter/foundation.dart' show kIsWeb;

class GitHubOAuthService {
  static String get _clientId => dotenv.env['GITHUB_CLIENT_ID'] ?? '';
  static String get _clientSecret => dotenv.env['GITHUB_CLIENT_SECRET'] ?? '';
  static String _redirectUri = 'http://localhost:8080/oauth/callback';
  static const String _scope = 'repo';
  
  static const String _authorizationUrl = 'https://github.com/login/oauth/authorize';
  static const String _tokenUrl = 'https://github.com/login/oauth/access_token';

  /// Initiates the OAuth flow and returns an access token
  static Future<String?> authenticate() async {
    try {
      // Validate environment variables
      if (_clientId.isEmpty || _clientSecret.isEmpty) {
        throw Exception('GitHub OAuth credentials not configured. Please check your .env file.');
      }
      
      // Start local server to capture OAuth callback
      final server = await _startCallbackServer();
      if (server == null) {
        throw Exception('Failed to start local callback server');
      }

      try {
        // Build authorization URL
        final authUrl = Uri.parse(_authorizationUrl).replace(
          queryParameters: {
            'client_id': _clientId,
            'scope': _scope,
            'redirect_uri': _redirectUri,
          },
        );

        // Open browser for OAuth
        if (await canLaunchUrl(authUrl)) {
          await launchUrl(authUrl, mode: LaunchMode.externalApplication);
          
          // Wait for OAuth callback
          final authCode = await _waitForCallback(server);
          if (authCode != null) {
            // Exchange authorization code for access token
            return await _exchangeCodeForToken(authCode);
          }
        } else {
          throw Exception('Could not open browser for OAuth');
        }
      } finally {
        // Always close the server
        await server.close();
      }
      
      return null;
    } catch (e) {
      if (e.toString().contains('User cancelled')) {
        return null; // User cancelled the OAuth flow
      }
      rethrow;
    }
  }

  /// Starts a local HTTP server to capture OAuth callback
  static Future<HttpServer?> _startCallbackServer() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
      return server;
    } catch (e) {
      // Port 8080 might be in use, try alternative ports
      for (int port in [8081, 8082, 8083, 8084, 8085]) {
        try {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
          // Update redirect URI for this port
          _redirectUri = 'http://localhost:$port/oauth/callback';
          return server;
        } catch (e) {
          continue;
        }
      }
      return null;
    }
  }

  /// Waits for OAuth callback and returns authorization code
  static Future<String?> _waitForCallback(HttpServer server) async {
    final completer = Completer<String?>();
    
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/oauth/callback') {
        final queryParams = request.uri.queryParameters;
        final code = queryParams['code'];
        final error = queryParams['error'];
        
        if (error != null) {
          // OAuth error occurred
          final response = request.response;
          response.statusCode = 200;
          response.headers.contentType = ContentType.html;
          response.write('''
            <html>
              <head><title>OAuth Error</title></head>
              <body>
                <h1>OAuth Error</h1>
                <p>Error: $error</p>
                <p>You can close this window and try again.</p>
              </body>
            </html>
          ''');
          response.close();
          completer.complete(null);
        } else if (code != null) {
          // Success! Return the authorization code
          final response = request.response;
          response.statusCode = 200;
          response.headers.contentType = ContentType.html;
          response.write('''
            <html>
              <head><title>OAuth Success</title></head>
              <body>
                <h1>Authentication Successful!</h1>
                <p>You have been successfully authenticated with GitHub.</p>
                <p>You can close this window and return to the app.</p>
              </body>
            </html>
          ''');
          response.close();
          completer.complete(code);
        } else {
          // Invalid callback
          final response = request.response;
          response.statusCode = 400;
          response.write('Invalid OAuth callback');
          response.close();
          completer.complete(null);
        }
      } else {
        // Handle other requests
        final response = request.response;
        response.statusCode = 404;
        response.write('Not found');
        response.close();
      }
    });

    // Set a timeout for the OAuth flow
    Timer(const Duration(minutes: 5), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// Exchanges authorization code for access token
  static Future<String> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'redirect_uri': _redirectUri,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to exchange code for token: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    
    if (data['error'] != null) {
      throw Exception('OAuth error: ${data['error_description'] ?? data['error']}');
    }

    final accessToken = data['access_token'];
    if (accessToken == null) {
      throw Exception('No access token received');
    }

    return accessToken;
  }

  /// Generates a random string for state parameter
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    
    for (int i = 0; i < length; i++) {
      buffer.write(chars[random % chars.length]);
    }
    
    return buffer.toString();
  }
}
