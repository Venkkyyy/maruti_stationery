import 'package:flutter/foundation.dart';

/// Dev-only logger — prints nothing in release builds.
class AppLogger {
  AppLogger._();

  static void d(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
      if (error != null) debugPrint('[ERROR] $error');
      if (stack != null) debugPrint('[STACK] $stack');
    }
  }

  static void i(String message) {
    if (kDebugMode) {
      debugPrint('[INFO ] $message');
    }
  }

  static void w(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[WARN ] $message');
      if (error != null) debugPrint('[ERROR] $error');
    }
  }

  static void e(String message, Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      debugPrint('[ERROR] $error');
      debugPrint('[STACK] $stack');
    }
    // In production, send to Crashlytics:
    // FirebaseCrashlytics.instance.recordError(error, stack);
  }
}
