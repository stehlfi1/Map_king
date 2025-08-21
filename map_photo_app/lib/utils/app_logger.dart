import 'package:flutter/foundation.dart';

class AppLogger {
  /// Log debug messages - only shows in debug mode
  static void debug(String tag, String message) {
    if (kDebugMode) {
      print('[$tag] $message');
    }
  }
  
  /// Log info messages - shows in debug and profile mode
  static void info(String tag, String message) {
    if (kDebugMode || kProfileMode) {
      print('[$tag] INFO: $message');
    }
  }
  
  /// Log warning messages - always shows
  static void warning(String tag, String message) {
    print('[$tag] WARNING: $message');
  }
  
  /// Log error messages - always shows
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    print('[$tag] ERROR: $message');
    if (error != null) {
      print('[$tag] ERROR Details: $error');
    }
    if (stackTrace != null && kDebugMode) {
      print('[$tag] Stack trace: $stackTrace');
    }
  }
}