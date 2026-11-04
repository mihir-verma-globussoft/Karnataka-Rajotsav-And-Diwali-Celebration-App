import 'dart:math';

import 'diya_game.dart';

/// The Deepavali games that send scores to the app's shared Supabase games
/// backend (see docs/GAMING_BACKEND.md). Each one is registered there by
/// supabase/migrations/202611040002_deepavali_games.sql.
enum DeepavaliGame {
  quiz('deepavali_quiz', 'Deepavali Quiz'),
  guess('deepavali_guess', 'Guess the Object'),
  diya('deepavali_diya', 'Light the Diyas');

  const DeepavaliGame(this.slug, this.title);

  /// The game's id in the backend's game registry. Never change it.
  final String slug;
  final String title;

  static DeepavaliGame? fromSlug(Object? slug) {
    for (final game in values) {
      if (game.slug == slug) return game;
    }
    return null;
  }
}

/// Points for a finished game. The backend ranks by one whole number where
/// more is better, so every game turns its result into points. Speed counts
/// too, so players do not all tie on a perfect score.
///
/// The limits in the migration are set from these numbers; change one and
/// change the other.
abstract final class DeepavaliPoints {
  /// A correct answer in the quiz or the guessing game.
  static const int perCorrect = 100;

  /// Most bonus one correct answer can add; it falls to nothing when the
  /// whole game takes [timePerQuestion] a question or longer.
  static const int maxSpeedBonus = 50;
  static const Duration timePerQuestion = Duration(seconds: 10);

  /// Diya game: points for winning, by level (the wind makes harder levels
  /// worth more), plus up to [diyaTimeBonus] for time left on the clock.
  static const int diyaGentle = 500;
  static const int diyaBreezy = 1000;
  static const int diyaStormy = 1500;
  static const int diyaTimeBonus = 500;

  /// Quiz or guessing game: [correct] answers out of [total], in [duration].
  static int forAnswers({
    required int correct,
    required int total,
    required Duration duration,
  }) {
    if (correct <= 0 || total <= 0) return 0;
    final allowed = timePerQuestion.inMilliseconds * total;
    final left = 1 - duration.inMilliseconds / allowed;
    final bonus = maxSpeedBonus * correct * left.clamp(0.0, 1.0);
    return perCorrect * correct + bonus.round();
  }

  /// A won diya game at [difficulty] that took [elapsed].
  static int forDiya({
    required DiyaDifficulty difficulty,
    required Duration elapsed,
  }) {
    final base = switch (difficulty) {
      DiyaDifficulty.gentle => diyaGentle,
      DiyaDifficulty.breezy => diyaBreezy,
      DiyaDifficulty.stormy => diyaStormy,
    };
    final limit = difficulty.limit.inMilliseconds;
    final left = 1 - elapsed.inMilliseconds / limit;
    return base + (diyaTimeBonus * left.clamp(0.0, 1.0)).round();
  }
}

/// A finished game, as sent to the leaderboard.
class GameRound {
  const GameRound({
    required this.id,
    required this.game,
    required this.points,
    required this.duration,
    required this.startedAt,
  });

  /// Made once when the game starts and kept for every retry, so a game is
  /// never counted twice.
  final String id;
  final DeepavaliGame game;
  final int points;
  final Duration duration;
  final DateTime startedAt;

  Map<String, Object> toJson() => {
    'id': id,
    'game': game.slug,
    'points': points,
    'durationMs': duration.inMilliseconds,
    'startedAt': startedAt.toUtc().toIso8601String(),
  };

  static GameRound? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final game = DeepavaliGame.fromSlug(json['game']);
    final points = json['points'];
    final durationMs = json['durationMs'];
    final startedAt = DateTime.tryParse('${json['startedAt']}');
    if (id is! String ||
        game == null ||
        points is! int ||
        durationMs is! int ||
        startedAt == null) {
      return null;
    }
    final took = Duration(milliseconds: durationMs);
    return GameRound(
      id: id,
      game: game,
      points: points,
      duration: took,
      startedAt: startedAt,
    );
  }
}

/// What happened to a game sent to the leaderboard.
sealed class ScoreSaveOutcome {
  const ScoreSaveOutcome();
}

/// Saved online.
class ScoreSaved extends ScoreSaveOutcome {
  const ScoreSaved({
    required this.best,
    required this.isNewBest,
    required this.rounds,
  });

  /// The player's best game, including this one.
  final int best;
  final bool isNewBest;

  /// Games the player has saved in all.
  final int rounds;
}

/// Could not be sent now (no network, server busy); kept on the phone and
/// sent later.
class ScoreQueued extends ScoreSaveOutcome {
  const ScoreQueued();
}

/// Not saved: this build has no leaderboard, or nobody is signed in.
class ScoreNotSaved extends ScoreSaveOutcome {
  const ScoreNotSaved();
}

/// The player's place on a game's leaderboard.
class ScoreStanding {
  const ScoreStanding({required this.best, required this.rounds, this.rank});

  final int best;
  final int rounds;

  /// Null until the player has a saved game.
  final int? rank;
}

/// One row of a leaderboard.
class ScoreLeader {
  const ScoreLeader({
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

/// The online leaderboards for the Deepavali games, shared with the app's
/// other games.
abstract interface class DeepavaliScoreboard {
  /// False when this build has no leaderboard or nobody is signed in; the
  /// games then work as before, without online scores.
  bool get isAvailable;

  /// Sends a finished game. Never throws: a game that cannot be sent is kept
  /// on the phone ([ScoreQueued]) and sent by [sendPending].
  Future<ScoreSaveOutcome> save(GameRound round);

  /// Sends games kept on the phone. Never throws.
  Future<void> sendPending();

  /// The player's best, games and rank in [game], or null when unavailable.
  Future<ScoreStanding?> standing(DeepavaliGame game);

  /// The top of [game]'s leaderboard; empty when unavailable.
  Future<List<ScoreLeader>> leaders(DeepavaliGame game, {int limit = 10});
}

/// The games without a leaderboard (no backend in this build).
class NoDeepavaliScoreboard implements DeepavaliScoreboard {
  const NoDeepavaliScoreboard();

  @override
  bool get isAvailable => false;

  @override
  Future<ScoreSaveOutcome> save(GameRound round) async => const ScoreNotSaved();

  @override
  Future<void> sendPending() async {}

  @override
  Future<ScoreStanding?> standing(DeepavaliGame game) async => null;

  @override
  Future<List<ScoreLeader>> leaders(
    DeepavaliGame game, {
    int limit = 10,
  }) async => const [];
}

/// A random version 4 UUID, used as a game's id.
String newRoundId(Random random) {
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
