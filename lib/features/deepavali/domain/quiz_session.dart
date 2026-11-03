import 'dart:math';

import 'content/quiz_questions.dart';

/// A question as shown in one run: options shuffled, [correctIndex] already
/// remapped to the shuffled order.
class QuizItem {
  const QuizItem({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final QuizQuestion question;
  final List<String> options;
  final int correctIndex;

  String get correctOption => options[correctIndex];
}

/// Result title for a finished run.
enum QuizTier {
  keepExploring('Keep exploring'),
  brightSpark('Bright spark'),
  dazzler('Diwali Dazzler');

  const QuizTier(this.title);
  final String title;

  static QuizTier forScore(int score, int total) {
    final ratio = total == 0 ? 0 : score / total;
    if (ratio >= 0.8) return dazzler;
    if (ratio >= 0.5) return brightSpark;
    return keepExploring;
  }
}

/// Immutable state of one quiz run. Illegal moves return `this`.
///
/// Flow: [answer] locks the current question; [next] moves on (or finishes
/// after the last). Answers cannot be changed once locked.
class QuizSession {
  const QuizSession._(
    this.items,
    this.answers,
    this.index, {
    required this.finished,
  });

  /// Draws [count] questions from [pool] (shuffled by [seed]) with shuffled
  /// options. The same seed always gives the same run.
  factory QuizSession.start(
    List<QuizQuestion> pool, {
    required int seed,
    int count = quizLength,
  }) {
    assert(pool.isNotEmpty, 'quiz pool must not be empty');
    final rng = Random(seed);
    final picked = List<QuizQuestion>.of(pool)..shuffle(rng);
    final items = <QuizItem>[
      for (final q in picked.take(count))
        () {
          final order = List<int>.generate(q.options.length, (i) => i)
            ..shuffle(rng);
          return QuizItem(
            question: q,
            options: [for (final i in order) q.options[i]],
            correctIndex: order.indexOf(q.correctIndex),
          );
        }(),
    ];
    return QuizSession._(
      List.unmodifiable(items),
      List<int?>.unmodifiable(List<int?>.filled(items.length, null)),
      0,
      finished: false,
    );
  }

  final List<QuizItem> items;

  /// Chosen option (shuffled position) per question; null if unanswered.
  final List<int?> answers;

  /// Index of the current question.
  final int index;
  final bool finished;

  int get total => items.length;
  QuizItem get current => items[index];
  int? get currentAnswer => answers[index];
  bool get answered => currentAnswer != null;
  bool get isLast => index == total - 1;

  bool isCorrect(int question) =>
      answers[question] == items[question].correctIndex;

  int get score => [
    for (var i = 0; i < total; i++)
      if (isCorrect(i)) 1,
  ].length;

  QuizTier get tier => QuizTier.forScore(score, total);

  /// Locks [option] as the answer. Ignored if finished, already answered or
  /// out of range.
  QuizSession answer(int option) {
    if (finished ||
        answered ||
        option < 0 ||
        option >= current.options.length) {
      return this;
    }
    final next = List<int?>.of(answers)..[index] = option;
    return QuizSession._(
      items,
      List.unmodifiable(next),
      index,
      finished: false,
    );
  }

  /// Moves to the next question, or finishes after the last. Only once the
  /// current question has been answered.
  QuizSession next() {
    if (finished || !answered) return this;
    if (isLast) {
      return QuizSession._(items, answers, index, finished: true);
    }
    return QuizSession._(items, answers, index + 1, finished: false);
  }
}
