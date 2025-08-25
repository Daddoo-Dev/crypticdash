import 'package:flutter/foundation.dart';
import 'appwrite_setup_service.dart';

/// Example of how to integrate AppwriteSetupService with your app
/// This shows the complete setup flow
class AppwriteIntegrationExample {
  
  /// Initialize Appwrite and show setup instructions
  static void initializeAppwrite() {
    try {
      debugPrint('Initializing Appwrite setup...');
      
      final setupService = AppwriteSetupService();
      
      // Print detailed setup instructions
      setupService.printSetupInstructions();
      
      // You can also get the schema programmatically
      final schemas = setupService.getCollectionSchemas();
      debugPrint('Collection schemas available: ${schemas.length}');
      
      debugPrint('✅ Appwrite setup instructions printed successfully!');
      
    } catch (e) {
      debugPrint('❌ Error initializing Appwrite setup: $e');
    }
  }
  
  /// Example of how to call this from your main.dart or app initialization
  static void exampleUsage() {
    debugPrint('=== APWRITE INTEGRATION EXAMPLE ===');
    
    // Call this during app startup
    initializeAppwrite();
    
    debugPrint('Appwrite initialization complete');
  }
}

/// Alternative: Integration with your existing services
class AppwriteServiceManager {
  static AppwriteSetupService? _setupService;
  
  /// Initialize the Appwrite setup service
  static void initialize() {
    _setupService = AppwriteSetupService();
  }
  
  /// Get the setup service instance
  static AppwriteSetupService? get setupService => _setupService;
  
  /// Check if Appwrite setup service is ready
  static bool isReady() {
    return _setupService != null;
  }
  
  /// Print setup instructions
  static void printSetupInstructions() {
    if (_setupService == null) {
      debugPrint('AppwriteSetupService not initialized');
      return;
    }
    
    _setupService!.printSetupInstructions();
  }
  
  /// Get setup guide as string
  static String? getSetupGuide() {
    if (_setupService == null) {
      debugPrint('AppwriteSetupService not initialized');
      return null;
    }
    
    return _setupService!.getSetupGuide();
  }
}
