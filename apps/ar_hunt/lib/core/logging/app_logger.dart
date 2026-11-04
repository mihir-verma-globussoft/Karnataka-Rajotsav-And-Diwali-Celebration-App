import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Thin logger over `dart:developer`. Logs appear in DevTools and the IDE.
///
/// Debug and info output is suppressed in release builds. Never log tokens,
/// credentials or personal data.
class AppLogger {
  const AppLogger();

  void debug(String message) => _log(message, level: 500);

  void info(String message) => _log(message, level: 800);

  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(message, level: 900, error: error, stackTrace: stackTrace);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(message, level: 1000, error: error, stackTrace: stackTrace);

  void _log(
    String message, {
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode && level < 900) return;
    developer.log(
      message,
      name: 'app',
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
