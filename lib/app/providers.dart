import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';

/// Build-time configuration. Override in tests.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

/// Shared logger. Override in tests with a fake.
final loggerProvider = Provider<AppLogger>((ref) => const AppLogger());

/// App-wide theme mode (the only global UI state in the foundation).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  // The festival tabs are designed dark, so the whole app (including the
  // shared bottom bar) is dark regardless of the phone's setting.
  ThemeMode build() => ThemeMode.dark;

  // Persisting the choice is left to a future task; add storage behind a
  // repository when it is needed.
  void set(ThemeMode mode) => state = mode;
}
