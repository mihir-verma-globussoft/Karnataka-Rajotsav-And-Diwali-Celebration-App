import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';
import '../../domain/content/quiz_questions.dart';
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
  @override
  QuizSession? build() => null;

  void start() => state = QuizSession.start(
    quizQuestions,
    seed: ref.read(quizSeedProvider)(),
  );

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
    }
  }

  /// Back to the start screen, discarding the run.
  void quit() => state = null;
}

final quizProvider = NotifierProvider<QuizNotifier, QuizSession?>(
  QuizNotifier.new,
);
