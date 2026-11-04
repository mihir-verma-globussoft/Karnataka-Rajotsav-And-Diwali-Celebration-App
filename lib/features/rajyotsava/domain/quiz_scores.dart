import 'dart:math';

import 'models.dart';

/// Points for quiz answers. Harder questions are worth more, and a quick
/// answer earns a bonus, so leaderboard scores spread out instead of
/// everyone tying on 10 of 10.
abstract final class QuizPoints {
  static const int easy = 100;
  static const int medium = 150;
  static const int hard = 200;

  /// Most bonus points for answering at once; it falls to nothing over
  /// [bonusWindow].
  static const int maxSpeedBonus = 50;
  static const Duration bonusWindow = Duration(seconds: 10);

  /// Points for one answer: none when wrong.
  static int forAnswer({
    required QuizDifficulty difficulty,
    required bool correct,
    required Duration took,
  }) {
    if (!correct) return 0;
    final base = switch (difficulty) {
      QuizDifficulty.easy => easy,
      QuizDifficulty.medium => medium,
      QuizDifficulty.hard => hard,
    };
    final left = 1 - took.inMilliseconds / bonusWindow.inMilliseconds;
    return base + (maxSpeedBonus * left.clamp(0.0, 1.0)).round();
  }
}

/// A finished quiz round, as sent to the leaderboard.
class QuizRoundResult {
  const QuizRoundResult({
    required this.id,
    required this.points,
    required this.correct,
    required this.total,
    required this.duration,
    required this.startedAt,
  });

  /// Made once when the round starts and kept for every retry, so a round
  /// is never counted twice.
  final String id;
  final int points;
  final int correct;
  final int total;
  final Duration duration;
  final DateTime startedAt;

  Map<String, Object> toJson() => {
    'id': id,
    'points': points,
    'correct': correct,
    'total': total,
    'durationMs': duration.inMilliseconds,
    'startedAt': startedAt.toUtc().toIso8601String(),
  };

  static QuizRoundResult? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final points = json['points'];
    final correct = json['correct'];
    final total = json['total'];
    final durationMs = json['durationMs'];
    final startedAt = DateTime.tryParse('${json['startedAt']}');
    if (id is! String ||
        points is! int ||
        correct is! int ||
        total is! int ||
        durationMs is! int ||
        startedAt == null) {
      return null;
    }
    final took = Duration(milliseconds: durationMs);
    return QuizRoundResult(
      id: id,
      points: points,
      correct: correct,
      total: total,
      duration: took,
      startedAt: startedAt,
    );
  }
}

/// What happened to a round sent to the leaderboard.
sealed class QuizSaveOutcome {
  const QuizSaveOutcome();
}

/// Saved online.
class QuizSaved extends QuizSaveOutcome {
  const QuizSaved({
    required this.best,
    required this.isNewBest,
    required this.rounds,
  });

  /// The player's best round, including this one.
  final int best;
  final bool isNewBest;

  /// Rounds the player has saved in all.
  final int rounds;
}

/// Could not be sent now (no network, server busy); kept on the phone and
/// sent later.
class QuizQueued extends QuizSaveOutcome {
  const QuizQueued();
}

/// Not saved: this build has no leaderboard, or nobody is signed in.
class QuizNotSaved extends QuizSaveOutcome {
  const QuizNotSaved();
}

/// The player's place on the leaderboard.
class QuizStanding {
  const QuizStanding({required this.best, required this.rounds, this.rank});

  final int best;
  final int rounds;

  /// Null until the player has a saved round.
  final int? rank;
}

/// One row of the leaderboard.
class QuizLeader {
  const QuizLeader({
    required this.rank,
    required this.name,
    required this.points,
    required this.isYou,
    this.avatarUrl,
  });

  final int rank;
  final String name;
  final int points;
  final bool isYou;
  final String? avatarUrl;
}

/// The online quiz leaderboard, shared with the app's other games.
abstract interface class QuizScoreboard {
  /// False when this build has no leaderboard or nobody is signed in; the
  /// quiz then works as before, without online scores.
  bool get isAvailable;

  /// Sends a finished round. Never throws: a round that cannot be sent is
  /// kept on the phone ([QuizQueued]) and sent by [sendPending].
  Future<QuizSaveOutcome> save(QuizRoundResult result);

  /// Sends rounds kept on the phone. Never throws.
  Future<void> sendPending();

  /// The player's best, rounds and rank, or null when unavailable.
  Future<QuizStanding?> standing();

  /// The top of the leaderboard; empty when unavailable.
  Future<List<QuizLeader>> leaders({int limit = 10});
}

/// The quiz without a leaderboard (no backend in this build).
class NoQuizScoreboard implements QuizScoreboard {
  const NoQuizScoreboard();

  @override
  bool get isAvailable => false;

  @override
  Future<QuizSaveOutcome> save(QuizRoundResult result) async =>
      const QuizNotSaved();

  @override
  Future<void> sendPending() async {}

  @override
  Future<QuizStanding?> standing() async => null;

  @override
  Future<List<QuizLeader>> leaders({int limit = 10}) async => const [];
}

/// A random version 4 UUID, used as a round's id.
String newRoundId(Random random) {
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
