/// One game's line on the player's scoreboard.
class GameScore {
  const GameScore({
    required this.slug,
    required this.name,
    required this.bestScore,
    required this.gamesPlayed,
    this.ceiling,
    this.points,
  });

  final String slug;
  final String name;

  /// The player's best raw score in this game.
  final int bestScore;
  final int gamesPlayed;

  /// The raw score at which the game contributes its full 1,000 points.
  final int? ceiling;

  /// What this game adds to the combined leaderboard (0 to 1,000). Null when
  /// the backend has not been upgraded to report it.
  final int? points;
}

/// Reads the player's per-game scoreboard, which adds up to their combined
/// leaderboard score.
abstract interface class GameScoresRepository {
  Future<List<GameScore>> load();
}
