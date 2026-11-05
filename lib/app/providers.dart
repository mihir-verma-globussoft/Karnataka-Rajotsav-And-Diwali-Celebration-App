import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/haptics/app_haptics.dart';
import '../core/logging/app_logger.dart';

/// Build-time configuration. Override in tests.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

/// App-wide haptic feedback (tap, selection, success, warning, error,
/// heavy). Any module may read it; override in tests with a recording fake.
final hapticsProvider = Provider<AppHaptics>((ref) => const SystemHaptics());

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

/// A lightweight, app-wide revision for aggregate arcade data.
///
/// Each game records its result through the shared Supabase score pipeline.
/// Bumping this revision makes the arcade dashboard and global leaderboard
/// refetch their aggregate totals without coupling individual games to the
/// Flappy Bird feature.
final arcadeScoreRevisionProvider =
    NotifierProvider<ArcadeScoreRevisionNotifier, int>(
      ArcadeScoreRevisionNotifier.new,
    );

class ArcadeScoreRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state++;
}
