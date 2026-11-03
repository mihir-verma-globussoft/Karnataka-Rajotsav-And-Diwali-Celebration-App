import 'package:shared_preferences/shared_preferences.dart';

import '../domain/diya_game.dart';
import '../domain/diya_game_store.dart';

/// [DiyaGameStore] backed by `shared_preferences`.
class PrefsDiyaGameStore implements DiyaGameStore {
  const PrefsDiyaGameStore();

  /// Gentle is the original game, so it keeps the original key and any best
  /// time saved before difficulties existed still counts.
  static String _key(DiyaDifficulty d) => d == DiyaDifficulty.gentle
      ? 'deepavali.diya_game.best_ms'
      : 'deepavali.diya_game.best_ms.${d.name}';

  @override
  Future<Duration?> bestTime(DiyaDifficulty difficulty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_key(difficulty));
      return ms == null || ms <= 0 ? null : Duration(milliseconds: ms);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveBestTime(DiyaDifficulty difficulty, Duration time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(difficulty), time.inMilliseconds);
    } on Object {
      // Losing a best time is harmless.
    }
  }
}
