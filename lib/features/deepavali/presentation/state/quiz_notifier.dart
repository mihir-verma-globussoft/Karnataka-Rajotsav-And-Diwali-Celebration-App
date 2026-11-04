import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';
import '../../domain/content/quiz_questions.dart';
import '../../domain/deepavali_scores.dart';
import '../../domain/quiz_session.dart';

/// Highest quiz score, or null if never played. Not autoDispose: the tab
/// stays mounted for the life of the app.
class QuizBestNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() => ref.read(quizStoreProvider).bestScore();

  /// Records [score] if it beats the best. Returns true for a new best.
  Future<bool> submit(int score) async {
    final current = await future;
    if (current != null && score <= current) return false;
    state = AsyncData(score);
    await ref.read(quizStoreProvider).saveBestScore(score);
    return true;
  }
}

final quizBestProvider = AsyncNotifierProvider<QuizBestNotifier, int?>(
  QuizBestNotifier.new,
);

/// The current quiz run; null until the player starts one.
class QuizNotifier extends Notifier<QuizSession?> {
  String _roundId = '';
  DateTime _startedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// The finished run being sent to the leaderboard, once there is one.
  Future<ScoreSaveOutcome>? get saving => _saving;
  Future<ScoreSaveOutcome>? _saving;

  @override
  QuizSession? build() => null;

  void start() {
    // Runs that could not be sent last time go now.
    unawaited(ref.read(deepavaliScoreboardProvider).sendPending());
    _saving = null;
    _roundId = newRoundId(Random.secure());
    _startedAt = ref.read(deepavaliNowProvider)();
    state = QuizSession.start(
      quizQuestions,
      seed: ref.read(quizSeedProvider)(),
    );
  }

  void answer(int option) {
    final s = state;
    if (s != null) state = s.answer(option);
  }

  void next() {
    final s = state;
    if (s == null) return;
    final moved = s.next();
    state = moved;
    if (moved.finished && !s.finished) {
      unawaited(ref.read(quizBestProvider.notifier).submit(moved.score));
      final took = ref.read(deepavaliNowProvider)().difference(_startedAt);
      _saving ??= ref
          .read(deepavaliScoreboardProvider)
          .save(
            GameRound(
              id: _roundId,
              game: DeepavaliGame.quiz,
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

  /// Back to the start screen, discarding the run.
  void quit() => state = null;
}

final quizProvider = NotifierProvider<QuizNotifier, QuizSession?>(
  QuizNotifier.new,
);
