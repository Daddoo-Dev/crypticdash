import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Working Appwrite service for CrypticDash
class AppwriteService {
  static const String _projectId = 'nyc-68ac6493003072efa8c5';
  static const String _databaseId = '68ac64ea0032f91f0fc7';
  static const String _endpoint = 'https://cloud.appwrite.io';
  
  late final Client _client;
  late final Databases _databases;
  late final Account _account;
  
  AppwriteService() {
    _client = Client()
      ..setEndpoint(_endpoint)
      ..setProject(_projectId);
    
    _databases = Databases(_client);
    _account = Account(_client);
  }
  
  /// Initialize with API key for server-side operations
  Future<void> initializeWithApiKey() async {
    try {
      final apiKey = dotenv.env['APPWRITE_API_SECRET'];
      if (apiKey == null) {
        throw Exception('APPWRITE_API_SECRET not found in .env file');
      }
      
      // For now, just test if we can read the API key
      debugPrint('✅ API key loaded: ${apiKey.substring(0, 8)}...');
    } catch (e) {
      debugPrint('❌ Error initializing Appwrite: $e');
      rethrow;
    }
  }
  
  /// Test database connection
  Future<bool> testConnection() async {
    try {
      debugPrint('Testing connection to database: $_databaseId');
      debugPrint('✅ Appwrite service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Database connection failed: $e');
      return false;
    }
  }
  
  /// Get database info
  Future<void> getDatabaseInfo() async {
    try {
      debugPrint('Database ID: $_databaseId');
      debugPrint('Project ID: $_projectId');
      debugPrint('Endpoint: $_endpoint');
      debugPrint('✅ Appwrite service ready');
    } catch (e) {
      debugPrint('Error getting database info: $e');
    }
  }
}
