import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class Log {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      // printTime: true // Optional
    ),
  );

  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void e(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    bool fatal = false,
  ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    // Record to Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error ?? message,
      stackTrace,
      reason: message,
      fatal: fatal,
    );
  }
}
