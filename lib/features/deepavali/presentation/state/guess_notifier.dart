import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';
import '../../domain/content/guess_objects.dart';
import '../../domain/quiz_session.dart';

/// The current Guess-the-object game; null until the player starts one.
/// Reuses the quiz's session logic (lock answers, score, tiers).
class GuessNotifier extends Notifier<QuizSession?> {
  @override
  QuizSession? build() => null;

  void start() {
    final seed = ref.read(quizSeedProvider)();
    state = QuizSession.start(
      buildGuessQuestions(seed),
      seed: seed,
      count: guessRounds,
    );
  }

  void answer(int option) => state = state?.answer(option);
  void next() => state = state?.next();
  void quit() => state = null;
}

final guessProvider = NotifierProvider<GuessNotifier, QuizSession?>(
  GuessNotifier.new,
);
