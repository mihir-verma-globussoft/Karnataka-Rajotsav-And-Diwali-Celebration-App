class GameResult {
  const GameResult({
    required this.gameId,
    required this.score,
    required this.duration,
    required this.startedAt,
    this.gameSlug = 'flappy_bird',
  });

  final String gameId;
  final String gameSlug;
  final int score;
  final Duration duration;
  final DateTime startedAt;
}

class GameSubmission {
  const GameSubmission({
    required this.highScore,
    required this.totalGames,
    required this.totalScore,
    required this.isNewHighScore,
    required this.wasAlreadySubmitted,
  });

  final int highScore;
  final int totalGames;
  final int totalScore;
  final bool isNewHighScore;
  final bool wasAlreadySubmitted;
}
