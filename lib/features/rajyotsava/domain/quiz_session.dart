import 'models.dart';
import 'quiz_scores.dart';

/// Immutable state of one quiz run. Every change returns a new session, so
/// the logic is easy to test without Flutter.
///
/// Times are passed in (rather than read from the clock) so tests control
/// them. A session started without times scores every answer as instant.
class QuizSession {
  QuizSession(List<QuizQuestion> questions, {String id = '', DateTime? at})
    : this._(
        List.unmodifiable(questions),
        0,
        const [],
        const [],
        id,
        at ?? _noTime,
        at ?? _noTime,
        at ?? _noTime,
      );

  const QuizSession._(
    this.questions,
    this.index,
    this.answers,
    this.answerTimes,
    this.id,
    this.startedAt,
    this._shownAt,
    this._lastAnswerAt,
  );

  static final DateTime _noTime = DateTime.utc(2000);

  final List<QuizQuestion> questions;

  /// Index of the question being shown (equals [length] once finished).
  final int index;

  /// Option chosen for each answered question, in order.
  final List<int> answers;

  /// How long each answer took, from the question appearing.
  final List<Duration> answerTimes;

  /// The round's id for the leaderboard, made when it starts.
  final String id;
  final DateTime startedAt;
  final DateTime _shownAt;
  final DateTime _lastAnswerAt;

  int get length => questions.length;
  bool get isFinished => index >= length;
  QuizQuestion? get current => isFinished ? null : questions[index];

  /// The option chosen for the current question, or null if not answered.
  int? get currentAnswer => answers.length > index ? answers[index] : null;
  bool get isAnswered => currentAnswer != null;

  /// Correct answers so far.
  int get score {
    var correct = 0;
    for (var i = 0; i < answers.length; i++) {
      if (answers[i] == questions[i].answerIndex) correct++;
    }
    return correct;
  }

  /// Points earned by answer [i] (see [QuizPoints]).
  int pointsFor(int i) => i < answers.length
      ? QuizPoints.forAnswer(
          difficulty: questions[i].difficulty,
          correct: answers[i] == questions[i].answerIndex,
          took: answerTimes[i],
        )
      : 0;

  /// Points earned so far.
  int get points {
    var total = 0;
    for (var i = 0; i < answers.length; i++) {
      total += pointsFor(i);
    }
    return total;
  }

  /// The round for the leaderboard, once finished.
  QuizRoundResult? get result => isFinished
      ? QuizRoundResult(
          id: id,
          points: points,
          correct: score,
          total: length,
          duration: _lastAnswerAt.difference(startedAt),
          startedAt: startedAt,
        )
      : null;

  /// Records [option] for the current question, answered [at] (defaults to
  /// the moment it appeared). Ignored when the question is already answered
  /// or the quiz is finished.
  QuizSession answer(int option, {DateTime? at}) {
    final question = current;
    if (question == null || isAnswered) return this;
    if (option < 0 || option >= question.options.length) return this;
    final when = at ?? _shownAt;
    final took = when.difference(_shownAt);
    return QuizSession._(
      questions,
      index,
      List.unmodifiable([...answers, option]),
      List.unmodifiable([
        ...answerTimes,
        took.isNegative ? Duration.zero : took,
      ]),
      id,
      startedAt,
      _shownAt,
      when,
    );
  }

  /// Moves to the next question once the current one is answered; it
  /// appears [at] (defaults to the moment of the last answer).
  QuizSession next({DateTime? at}) {
    if (isFinished || !isAnswered) return this;
    return QuizSession._(
      questions,
      index + 1,
      answers,
      answerTimes,
      id,
      startedAt,
      at ?? _lastAnswerAt,
      _lastAnswerAt,
    );
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
