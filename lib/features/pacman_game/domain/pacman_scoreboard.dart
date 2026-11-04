import 'dart:math';

/// One finished Pac-Man game, as sent to the shared games backend.
class PacmanRound {
  const PacmanRound({
    required this.id,
    required this.score,
    required this.duration,
    required this.startedAt,
  });

  factory PacmanRound.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Not a Pac-Man round');
    final played = Duration(microseconds: json['us'] as int);
    return PacmanRound(
      id: json['id'] as String,
      score: json['score'] as int,
      duration: played,
      startedAt: DateTime.parse(json['at'] as String),
    );
  }

  /// A new round with a random id. The server counts a round once per id, so
  /// sending it again after a failure is safe.
  factory PacmanRound.finished({
    required int score,
    required Duration duration,
    required DateTime startedAt,
  }) => PacmanRound(
    id: _newUuid(),
    score: score,
    duration: duration,
    startedAt: startedAt,
  );

  final String id;

  /// Diyas lit.
  final int score;
  final Duration duration;
  final DateTime startedAt;

  Map<String, Object> toJson() => {
    'id': id,
    'score': score,
    'us': duration.inMicroseconds,
    'at': startedAt.toUtc().toIso8601String(),
  };
}

sealed class PacmanSaveOutcome {
  const PacmanSaveOutcome();
}

/// The server has the round.
class PacmanSaved extends PacmanSaveOutcome {
  const PacmanSaved({
    required this.best,
    required this.isNewBest,
    required this.rounds,
  });

  final int best;
  final bool isNewBest;
  final int rounds;
}

/// No connection or not registered yet: kept on the phone, sent later.
class PacmanQueued extends PacmanSaveOutcome {
  const PacmanQueued();
}

/// Nobody is signed in, or the round is not one the server accepts.
class PacmanNotSaved extends PacmanSaveOutcome {
  const PacmanNotSaved();
}

/// The player's own numbers. [rank] is null until a first game is saved.
class PacmanStanding {
  const PacmanStanding({
    required this.best,
    required this.rounds,
    required this.total,
    this.rank,
  });

  static const empty = PacmanStanding(best: 0, rounds: 0, total: 0);

  final int best;
  final int rounds;
  final int total;
  final int? rank;
}

class PacmanLeader {
  const PacmanLeader({
    required this.rank,
    required this.name,
    required this.points,
    this.avatarUrl,
    this.isYou = false,
  });

  final int rank;
  final String name;
  final int points;
  final String? avatarUrl;
  final bool isYou;
}

/// Pac-Man's scores on the app's shared games backend.
abstract interface class PacmanScoreboard {
  /// Whether a signed-in player exists to save scores for.
  bool get isAvailable;

  /// Saves [round]; the latest score is remembered even when sending fails.
  Future<PacmanSaveOutcome> save(PacmanRound round);

  /// Sends rounds that could not be sent earlier.
  Future<void> sendPending();

  /// The player's numbers, or null when they cannot be loaded.
  Future<PacmanStanding?> standing();

  /// The player's latest score on this phone; null before the first game.
  Future<int?> lastScore();

  /// Best players first. Throws when the board cannot be loaded.
  Future<List<PacmanLeader>> leaders({int limit = 50});
}

/// Used when the build has no backend: the game works, scores are not kept.
class NoPacmanScoreboard implements PacmanScoreboard {
  const NoPacmanScoreboard();

  @override
  bool get isAvailable => false;

  @override
  Future<PacmanSaveOutcome> save(PacmanRound round) async =>
      const PacmanNotSaved();

  @override
  Future<void> sendPending() async {}

  @override
  Future<PacmanStanding?> standing() async => null;

  @override
  Future<int?> lastScore() async => null;

  @override
  Future<List<PacmanLeader>> leaders({int limit = 50}) async => const [];
}

String _newUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10).join()}';
}
