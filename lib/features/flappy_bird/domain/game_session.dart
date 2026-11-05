import 'dart:math';

import 'game_result.dart';

enum GamePhase { ready, playing, lifeLost, gameOver, paused }

class PipePair {
  PipePair({required this.x, required this.gapCenter, this.scored = false});

  double x;
  final double gapCenter;
  bool scored;
}

/// Pure-Dart game model. Coordinates are normalized from 0 to 1, so gameplay
/// behaves consistently across phone and tablet sizes.
class GameSession {
  GameSession({Random? random}) : _random = random ?? Random();

  static const int maxLives = 3;
  static const double birdX = 0.24;
  static const double birdWidth = 0.085;
  static const double birdHeight = 0.06;
  static const double pipeWidth = 0.14;
  static const double pipeGap = 0.29;
  static const double groundY = 0.91;

  final Random _random;
  final List<PipePair> pipes = [];

  GamePhase phase = GamePhase.ready;
  int lives = maxLives;
  int score = 0;
  double birdY = 0.43;
  double birdVelocity = 0;
  Duration elapsed = Duration.zero;
  DateTime startedAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  String gameId = '';

  int get livesUsed => maxLives - lives;
  bool get canFlap => phase == GamePhase.playing;

  void startNewGame({DateTime? now, String? id}) {
    lives = maxLives;
    score = 0;
    elapsed = Duration.zero;
    startedAt = (now ?? DateTime.now()).toUtc();
    gameId = id ?? _newUuid();
    _resetAttempt(GamePhase.ready);
  }

  void tap() {
    if (phase == GamePhase.gameOver || phase == GamePhase.paused) return;
    if (phase == GamePhase.ready || phase == GamePhase.lifeLost) {
      phase = GamePhase.playing;
    }
    birdVelocity = -0.72;
  }

  void update(double seconds) {
    if (phase != GamePhase.playing || seconds <= 0) return;
    final dt = seconds.clamp(0.0, 0.05).toDouble();
    elapsed += Duration(
      microseconds: (dt * Duration.microsecondsPerSecond).round(),
    );
    birdVelocity += 2.15 * dt;
    birdY += birdVelocity * dt;

    for (final pipe in pipes) {
      pipe.x -= 0.285 * dt;
      if (!pipe.scored && pipe.x + pipeWidth < birdX) {
        pipe.scored = true;
        score++;
      }
    }
    if (pipes.isNotEmpty && pipes.first.x + pipeWidth < -0.05) {
      pipes.removeAt(0);
      final lastX = pipes.isEmpty ? 1.15 : pipes.last.x;
      pipes.add(_pipe(lastX + 0.66));
    }

    if (_hasCollision()) registerCollision();
  }

  /// Returns true only for the first collision in an active attempt.
  bool registerCollision() {
    if (phase != GamePhase.playing) return false;
    lives = max(0, lives - 1);
    if (lives == 0) {
      phase = GamePhase.gameOver;
      birdVelocity = 0;
    } else {
      _resetAttempt(GamePhase.lifeLost);
    }
    return true;
  }

  void pauseForLifecycle() {
    if (phase == GamePhase.playing) {
      _resetAttempt(GamePhase.paused);
    }
  }

  /// Pauses an active attempt without resetting its bird, pipes, or score.
  void pause() {
    if (phase == GamePhase.playing) phase = GamePhase.paused;
  }

  /// Resumes only an explicitly paused active attempt.
  void resume() {
    if (phase == GamePhase.paused) phase = GamePhase.playing;
  }

  void resumeAfterLifecycle() {
    if (phase == GamePhase.paused) phase = GamePhase.ready;
  }

  GameResult get result {
    if (phase != GamePhase.gameOver) {
      throw StateError('A game result is available only after game over.');
    }
    return GameResult(
      gameId: gameId,
      score: score,
      duration: elapsed,
      startedAt: startedAt,
    );
  }

  void _resetAttempt(GamePhase nextPhase) {
    phase = nextPhase;
    birdY = 0.43;
    birdVelocity = 0;
    pipes
      ..clear()
      ..addAll([_pipe(1.05), _pipe(1.71), _pipe(2.37)]);
  }

  PipePair _pipe(double x) =>
      PipePair(x: x, gapCenter: 0.28 + _random.nextDouble() * 0.34);

  bool _hasCollision() {
    if (birdY <= 0 || birdY + birdHeight >= groundY) return true;
    const birdRight = birdX + birdWidth;
    final birdBottom = birdY + birdHeight;
    for (final pipe in pipes) {
      final overlapsX = birdRight > pipe.x && birdX < pipe.x + pipeWidth;
      if (!overlapsX) continue;
      final gapTop = pipe.gapCenter - pipeGap / 2;
      final gapBottom = pipe.gapCenter + pipeGap / 2;
      if (birdY < gapTop || birdBottom > gapBottom) return true;
    }
    return false;
  }
}

String _newUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
