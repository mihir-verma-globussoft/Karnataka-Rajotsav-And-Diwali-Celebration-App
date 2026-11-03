import 'models.dart';

/// Immutable state of one quiz run. Every change returns a new session, so
/// the logic is easy to test without Flutter.
class QuizSession {
  QuizSession(List<QuizQuestion> questions)
    : this._(List.unmodifiable(questions), 0, const []);

  const QuizSession._(this.questions, this.index, this.answers);

  final List<QuizQuestion> questions;

  /// Index of the question being shown (equals [length] once finished).
  final int index;

  /// Option chosen for each answered question, in order.
  final List<int> answers;

  int get length => questions.length;
  bool get isFinished => index >= length;
  QuizQuestion? get current => isFinished ? null : questions[index];

  /// The option chosen for the current question, or null if not answered.
  int? get currentAnswer => answers.length > index ? answers[index] : null;
  bool get isAnswered => currentAnswer != null;

  int get score {
    var correct = 0;
    for (var i = 0; i < answers.length; i++) {
      if (answers[i] == questions[i].answerIndex) correct++;
    }
    return correct;
  }

  /// Records [option] for the current question. Ignored when the question is
  /// already answered or the quiz is finished.
  QuizSession answer(int option) {
    final question = current;
    if (question == null || isAnswered) return this;
    if (option < 0 || option >= question.options.length) return this;
    return QuizSession._(
      questions,
      index,
      List.unmodifiable([...answers, option]),
    );
  }

  /// Moves to the next question once the current one is answered.
  QuizSession next() {
    if (isFinished || !isAnswered) return this;
    return QuizSession._(questions, index + 1, answers);
  }
}

/// Encouraging message for a final score.
String quizVerdict(int score, int total) {
  if (total == 0) return 'No questions this time.';
  final ratio = score / total;
  if (ratio == 1) return 'Perfect! You are a true Kannadiga at heart.';
  if (ratio >= 0.7) return 'Great score! You know Karnataka well.';
  if (ratio >= 0.4) return 'Good effort! A little more and you are there.';
  return 'Keep exploring Karnataka and try again!';
}
