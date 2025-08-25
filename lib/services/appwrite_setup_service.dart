import 'package:flutter/foundation.dart';

/// Service to provide Appwrite collection setup instructions for CrypticDash
/// Since the Appwrite Flutter SDK doesn't support collection creation,
/// this service provides detailed instructions for manual setup
class AppwriteSetupService {
  static const String _databaseId = 'dashbase';
  
  // Collection IDs
  static const String _usersCollectionId = 'users';
  static const String _repoTrackingCollectionId = 'repository_tracking';
  static const String _subscriptionEventsCollectionId = 'subscription_events';
  
  /// Get collection schema information for manual setup
  Map<String, Map<String, dynamic>> getCollectionSchemas() {
    return {
      _usersCollectionId: {
        'name': 'Users',
        'description': 'User profiles and subscription data',
        'fields': {
          'userId': {'type': 'string', 'size': 255, 'required': true},
          'email': {'type': 'string', 'size': 255, 'required': true},
          'subscriptionStatus': {'type': 'string', 'size': 50, 'required': true, 'default': 'free'},
          'trialStartDate': {'type': 'datetime', 'required': false},
          'subscriptionExpiryDate': {'type': 'datetime', 'required': false},
          'createdAt': {'type': 'datetime', 'required': true},
        },
        'indexes': [
          {'key': 'userId_unique', 'type': 'key', 'attributes': ['userId']},
          {'key': 'email_unique', 'type': 'key', 'attributes': ['email']},
        ],
        'permissions': ['read("user:{{user.id}}")', 'write("user:{{user.id}}")'],
      },
      _repoTrackingCollectionId: {
        'name': 'Repository Tracking',
        'description': 'Track repositories across devices',
        'fields': {
          'userId': {'type': 'string', 'size': 255, 'required': true},
          'repoId': {'type': 'string', 'size': 255, 'required': true},
          'repoName': {'type': 'string', 'size': 255, 'required': true},
          'addedAt': {'type': 'datetime', 'required': true},
          'isActive': {'type': 'boolean', 'required': true, 'default': true},
        },
        'indexes': [
          {'key': 'userId_repoId_unique', 'type': 'key', 'attributes': ['userId', 'repoId']},
          {'key': 'userId_index', 'type': 'key', 'attributes': ['userId']},
        ],
        'permissions': ['read("user:{{user.id}}")', 'write("user:{{user.id}}")'],
      },
      _subscriptionEventsCollectionId: {
        'name': 'Subscription Events',
        'description': 'Audit trail for subscription changes',
        'fields': {
          'userId': {'type': 'string', 'size': 255, 'required': true},
          'eventType': {'type': 'string', 'size': 100, 'required': true},
          'oldStatus': {'type': 'string', 'size': 50, 'required': false},
          'newStatus': {'type': 'string', 'size': 50, 'required': true},
          'timestamp': {'type': 'datetime', 'required': true},
          'platform': {'type': 'string', 'size': 50, 'required': false},
        },
        'indexes': [
          {'key': 'userId_index', 'type': 'key', 'attributes': ['userId']},
          {'key': 'timestamp_index', 'type': 'key', 'attributes': ['timestamp']},
        ],
        'permissions': ['read("user:{{user.id}}")', 'write("user:{{user.id}}")'],
      },
    };
  }
  
  /// Print setup instructions for manual collection creation
  void printSetupInstructions() {
    debugPrint('=== APWRITE COLLECTION SETUP INSTRUCTIONS ===');
    debugPrint('1. Go to your Appwrite Console');
    debugPrint('2. Navigate to Databases > dashbase');
    debugPrint('3. Create the following collections:');
    
    final schemas = getCollectionSchemas();
    for (final entry in schemas.entries) {
      final collectionId = entry.key;
      final schema = entry.value;
      
      debugPrint('\n--- $collectionId ---');
      debugPrint('Name: ${schema['name']}');
      debugPrint('Description: ${schema['description']}');
      debugPrint('Permissions: ${schema['permissions']}');
      
      debugPrint('\nFields:');
      for (final field in schema['fields'].entries) {
        final fieldName = field.key;
        final fieldConfig = field.value;
        debugPrint('  - $fieldName: ${fieldConfig['type']} (required: ${fieldConfig['required']})');
      }
      
      debugPrint('\nIndexes:');
      for (final index in schema['indexes']) {
        debugPrint('  - ${index['key']}: ${index['type']} on ${index['attributes'].join(', ')}');
      }
    }
    
    debugPrint('\n=== END SETUP INSTRUCTIONS ===');
  }
  
  /// Get a formatted setup guide for console use
  String getSetupGuide() {
    final buffer = StringBuffer();
    buffer.writeln('=== APWRITE COLLECTION SETUP GUIDE ===');
    buffer.writeln('Database ID: $_databaseId');
    buffer.writeln('');
    
    final schemas = getCollectionSchemas();
    for (final entry in schemas.entries) {
      final collectionId = entry.key;
      final schema = entry.value;
      
      buffer.writeln('Collection: $collectionId');
      buffer.writeln('Name: ${schema['name']}');
      buffer.writeln('Description: ${schema['description']}');
      buffer.writeln('Permissions: ${schema['permissions']}');
      buffer.writeln('');
      
      buffer.writeln('Fields:');
      for (final field in schema['fields'].entries) {
        final fieldName = field.key;
        final fieldConfig = field.value;
        buffer.writeln('  - $fieldName: ${fieldConfig['type']} (required: ${fieldConfig['required']})');
      }
      buffer.writeln('');
      
      buffer.writeln('Indexes:');
      for (final index in schema['indexes']) {
        buffer.writeln('  - ${index['key']}: ${index['type']} on ${index['attributes'].join(', ')}');
      }
      buffer.writeln('---');
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
}
