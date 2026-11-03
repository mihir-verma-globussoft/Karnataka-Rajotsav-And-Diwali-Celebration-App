import 'dart:math';

import 'models.dart';

/// Deals quiz rounds. Each round has at most [maxHard] hard questions; the
/// rest are easy and medium. A question is not dealt again until every
/// question of its group (hard, or easy and medium) has been dealt, then
/// that group is reshuffled.
class QuizDeck {
  QuizDeck(List<QuizQuestion> questions, this._random)
    : _hardPool = [
        for (final q in questions)
          if (q.difficulty == QuizDifficulty.hard) q,
      ],
      _otherPool = [
        for (final q in questions)
          if (q.difficulty != QuizDifficulty.hard) q,
      ];

  /// Most hard questions in one round.
  static const int maxHard = 4;

  /// Fewest hard questions in one round, when there are enough.
  static const int minHard = 2;

  final List<QuizQuestion> _hardPool;
  final List<QuizQuestion> _otherPool;
  final Random _random;
  final List<QuizQuestion> _hardLeft = [];
  final List<QuizQuestion> _otherLeft = [];

  /// A round of up to [count] different questions, easiest first.
  List<QuizQuestion> deal(int count) {
    final total = min(count, _hardPool.length + _otherPool.length);
    final hardMax = min(maxHard, min(_hardPool.length, total));
    final hardMin = min(minHard, hardMax);
    // A varying number of hard questions, but never more than maxHard, and
    // enough of them when there are too few easy and medium questions.
    var hard = hardMin + _random.nextInt(hardMax - hardMin + 1);
    hard = max(hard, total - _otherPool.length);
    final round = [
      ..._take(_otherLeft, _otherPool, total - hard),
      ..._take(_hardLeft, _hardPool, hard),
    ];
    // Easy, then medium, then hard; random order within each.
    round.shuffle(_random);
    round.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
    return round;
  }

  List<QuizQuestion> _take(
    List<QuizQuestion> left,
    List<QuizQuestion> pool,
    int count,
  ) {
    final taken = <QuizQuestion>[];
    while (taken.length < count) {
      if (left.isEmpty) {
        left.addAll(
          [
            for (final q in pool)
              if (!taken.contains(q)) q,
          ]..shuffle(_random),
        );
      }
      taken.add(left.removeAt(0));
    }
    return taken;
  }
}
