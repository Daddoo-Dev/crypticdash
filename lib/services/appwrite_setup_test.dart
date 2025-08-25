import 'package:flutter/foundation.dart';
import 'appwrite_setup_service.dart';

/// Simple test to demonstrate the Appwrite setup service
class AppwriteSetupTest {
  
  /// Test the setup service
  static void testSetupService() {
    debugPrint('=== TESTING APWRITE SETUP SERVICE ===');
    
    final setupService = AppwriteSetupService();
    
    // Print setup instructions to console
    setupService.printSetupInstructions();
    
    // Get the setup guide as a string
    final setupGuide = setupService.getSetupGuide();
    debugPrint('\n=== SETUP GUIDE STRING ===');
    debugPrint(setupGuide);
    
    // Get collection schemas
    final schemas = setupService.getCollectionSchemas();
    debugPrint('\n=== COLLECTION SCHEMAS ===');
    debugPrint('Total collections: ${schemas.length}');
    
    for (final entry in schemas.entries) {
      final collectionId = entry.key;
      final schema = entry.value;
      debugPrint('Collection: $collectionId');
      debugPrint('  Fields: ${schema['fields'].length}');
      debugPrint('  Indexes: ${schema['indexes'].length}');
    }
    
    debugPrint('\n=== TEST COMPLETE ===');
  }
}

/// Example usage in your app
class AppwriteSetupExample {
  
  /// Initialize Appwrite setup during app startup
  static void initializeAppwriteSetup() {
    debugPrint('Initializing Appwrite setup...');
    
    final setupService = AppwriteSetupService();
    
    // Print setup instructions if collections need to be created
    setupService.printSetupInstructions();
    
    debugPrint('Appwrite setup instructions printed to console');
    debugPrint('Please follow the instructions above to create collections in Appwrite Console');
  }
}
