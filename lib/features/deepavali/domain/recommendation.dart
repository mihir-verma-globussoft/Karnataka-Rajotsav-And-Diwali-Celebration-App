import 'content/destinations.dart';

/// One answer to a recommendation question and the cities it points to.
class RecommendOption {
  const RecommendOption(this.label, this.points);

  final String label;

  /// Destination id to points (2 = a strong match, 1 = a good one).
  final Map<String, int> points;
}

class RecommendQuestion {
  const RecommendQuestion(this.prompt, this.options);

  final String prompt;
  final List<RecommendOption> options;
}

/// Four questions, four answers each. Every city can win; ties go to the city
/// that comes first in the gallery, so a result is always the same for the
/// same answers.
const List<RecommendQuestion> recommendQuestions = [
  RecommendQuestion('What would you love most this Diwali?', [
    RecommendOption('Floating lamps on a holy river', {
      'varanasi': 2,
      'ayodhya': 1,
    }),
    RecommendOption('Palaces and bazaars glittering with lights', {
      'jaipur': 2,
      'mumbai': 1,
    }),
    RecommendOption('Walking where an ancient story began', {
      'ayodhya': 2,
      'varanasi': 1,
    }),
    RecommendOption('Glowing streets and festive crowds', {
      'mumbai': 2,
      'kolkata': 1,
    }),
  ]),
  RecommendQuestion('How would you spend a perfect evening?', [
    RecommendOption('A quiet prayer beside still water', {
      'amritsar': 2,
      'varanasi': 1,
    }),
    RecommendOption('Shopping for lanterns and sweets', {
      'jaipur': 2,
      'mumbai': 1,
    }),
    RecommendOption('Watching artists dress grand clay idols', {
      'kolkata': 2,
      'jaipur': 1,
    }),
    RecommendOption('Joining a huge public lamp-lighting', {
      'ayodhya': 2,
      'varanasi': 1,
    }),
  ]),
  RecommendQuestion('Which feeling matters most to you?', [
    RecommendOption('Devotion and ancient stories', {
      'ayodhya': 2,
      'varanasi': 1,
    }),
    RecommendOption('Colour, craft and art', {'kolkata': 2, 'jaipur': 1}),
    RecommendOption('Community and a shared meal', {
      'amritsar': 2,
      'kolkata': 1,
    }),
    RecommendOption('Energy, music and fireworks', {'mumbai': 2, 'jaipur': 1}),
  ]),
  RecommendQuestion('Pick a Diwali moment', [
    RecommendOption('Lighting a diya at a golden temple', {
      'amritsar': 2,
      'ayodhya': 1,
    }),
    RecommendOption('Arranging diyas into a pattern', {
      'varanasi': 2,
      'kolkata': 1,
    }),
    RecommendOption('A palace shining against the night sky', {
      'jaipur': 2,
      'amritsar': 1,
    }),
    RecommendOption('Trading hour in a big business city', {
      'mumbai': 2,
      'jaipur': 1,
    }),
  ]),
];

/// A finished recommendation.
class Recommendation {
  const Recommendation(this.destinationId, this.reasons);

  final String destinationId;

  /// The answers that pointed to this city.
  final List<String> reasons;
}

/// Where you are in the questions. Immutable; illegal moves return `this`.
class RecommendFlow {
  const RecommendFlow([this.answers = const []]);

  /// Chosen option per question answered so far.
  final List<int> answers;

  int get total => recommendQuestions.length;
  bool get isDone => answers.length == total;
  int get index => answers.length;
  RecommendQuestion get current => recommendQuestions[index];

  RecommendFlow answer(int option) {
    if (isDone || option < 0 || option >= current.options.length) return this;
    return RecommendFlow([...answers, option]);
  }

  /// Takes back the last answer.
  RecommendFlow back() => answers.isEmpty
      ? this
      : RecommendFlow(answers.sublist(0, answers.length - 1));

  /// The result once every question is answered, otherwise null.
  Recommendation? get result => isDone ? recommend(answers) : null;
}

/// Scores every city for [answers] and picks the best.
Recommendation recommend(List<int> answers) {
  assert(answers.length == recommendQuestions.length);
  final scores = {for (final d in destinations) d.id: 0};
  for (var q = 0; q < answers.length; q++) {
    final option = recommendQuestions[q].options[answers[q]];
    option.points.forEach((id, p) => scores[id] = (scores[id] ?? 0) + p);
  }
  var best = destinations.first.id;
  for (final d in destinations) {
    if (scores[d.id]! > scores[best]!) best = d.id;
  }
  final reasons = [
    for (var q = 0; q < answers.length; q++)
      if ((recommendQuestions[q].options[answers[q]].points[best] ?? 0) > 0)
        recommendQuestions[q].options[answers[q]].label,
  ];
  return Recommendation(best, reasons);
}
