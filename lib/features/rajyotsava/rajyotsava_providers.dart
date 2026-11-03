import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/bundled_rajyotsava_content.dart';
import 'data/tts_kannada_speaker.dart';
import 'domain/kannada_speaker.dart';
import 'domain/models.dart';
import 'domain/quiz_session.dart';

/// All module content. Bundled in the app; override in tests.
final rajyotsavaContentProvider = Provider<RajyotsavaContent>(
  (ref) => bundledRajyotsavaContent,
);

/// Kannada text-to-speech. Kept alive by the Learn Kannada screen and
/// disposed (stopping any speech) when it closes. Override in tests.
final kannadaSpeakerProvider = Provider.autoDispose<KannadaSpeaker>((ref) {
  final speaker = TtsKannadaSpeaker();
  ref.onDispose(speaker.stop);
  return speaker;
});

/// Current time, for the Rajyotsava countdown. Override in tests.
final rajyotsavaClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Random source for shuffling quiz questions. Override with a seeded
/// [Random] in tests.
final quizRandomProvider = Provider<Random>((ref) => Random());

/// The quiz in progress. Disposed when the quiz screen closes, so each visit
/// starts a fresh round.
final quizControllerProvider =
    NotifierProvider.autoDispose<QuizController, QuizSession>(
      QuizController.new,
    );

class QuizController extends Notifier<QuizSession> {
  /// Questions asked per round, picked at random from the full set.
  static const int questionsPerRound = 10;

  @override
  QuizSession build() => _newRound();

  QuizSession _newRound() {
    final questions = [...ref.read(rajyotsavaContentProvider).quiz]
      ..shuffle(ref.read(quizRandomProvider));
    return QuizSession(questions.take(questionsPerRound).toList());
  }

  void answer(int option) => state = state.answer(option);

  void next() => state = state.next();

  void restart() => state = _newRound();
}
