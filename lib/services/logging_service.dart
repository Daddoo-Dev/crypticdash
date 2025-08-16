import 'package:flutter/foundation.dart';

class LoggingService {
  static const String _tag = '[DevDash]';
  
  // Info level logging - always shown
  static void info(String message) {
    if (kDebugMode) {
      print('$_tag [INFO] $message');
    }
  }
  
  // Debug level logging - only in debug mode
  static void debug(String message) {
    if (kDebugMode) {
      print('$_tag [DEBUG] $message');
    }
  }
  
  // Warning level logging - always shown
  static void warning(String message) {
    if (kDebugMode) {
      print('$_tag [WARN] $message');
    }
  }
  
  // Error level logging - always shown
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_tag [ERROR] $message');
      if (error != null) {
        print('$_tag [ERROR] Error: $error');
      }
      if (stackTrace != null) {
        print('$_tag [ERROR] Stack trace: $stackTrace');
      }
    }
  }
  
  // Success level logging - always shown
  static void success(String message) {
    if (kDebugMode) {
      print('$_tag [SUCCESS] $message');
    }
  }
}
