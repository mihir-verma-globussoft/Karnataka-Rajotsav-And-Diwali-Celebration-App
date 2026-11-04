import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';
import '../../domain/content/guess_objects.dart';
import '../../domain/deepavali_scores.dart';
import '../../domain/quiz_session.dart';

/// The current Guess-the-object game; null until the player starts one.
/// Reuses the quiz's session logic (lock answers, score, tiers).
class GuessNotifier extends Notifier<QuizSession?> {
  String _roundId = '';
  DateTime _startedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// The finished game being sent to the leaderboard, once there is one.
  Future<ScoreSaveOutcome>? get saving => _saving;
  Future<ScoreSaveOutcome>? _saving;

  @override
  QuizSession? build() => null;

  void start() {
    // Games that could not be sent last time go now.
    unawaited(ref.read(deepavaliScoreboardProvider).sendPending());
    _saving = null;
    _roundId = newRoundId(Random.secure());
    _startedAt = ref.read(deepavaliNowProvider)();
    final seed = ref.read(quizSeedProvider)();
    state = QuizSession.start(
      buildGuessQuestions(seed),
      seed: seed,
      count: guessRounds,
    );
  }

  void answer(int option) => state = state?.answer(option);

  void next() {
    final s = state;
    if (s == null) return;
    final moved = s.next();
    state = moved;
    if (moved.finished && !s.finished) {
      final took = ref.read(deepavaliNowProvider)().difference(_startedAt);
      _saving ??= ref
          .read(deepavaliScoreboardProvider)
          .save(
            GameRound(
              id: _roundId,
              game: DeepavaliGame.guess,
              points: DeepavaliPoints.forAnswers(
                correct: moved.score,
                total: moved.total,
                duration: took,
              ),
              duration: took,
              startedAt: _startedAt,
            ),
          );
    }
  }

  void quit() => state = null;
}

final guessProvider = NotifierProvider<GuessNotifier, QuizSession?>(
  GuessNotifier.new,
);
