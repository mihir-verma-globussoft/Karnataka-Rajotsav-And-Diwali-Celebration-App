import 'diya_game.dart';

/// Persists the best (fastest) winning time per difficulty. Implementations
/// must not throw; a failure just means "no best time stored".
abstract interface class DiyaGameStore {
  Future<Duration?> bestTime(DiyaDifficulty difficulty);
  Future<void> saveBestTime(DiyaDifficulty difficulty, Duration time);
}
