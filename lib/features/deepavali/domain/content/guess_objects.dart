import 'dart:math';

import 'quiz_questions.dart';

/// A Diwali object shown as a silhouette. The art for [id] is drawn in the
/// presentation layer.
class GuessObject {
  const GuessObject({required this.id, required this.name, required this.fact});

  final String id;

  /// The answer, as shown on the answer button.
  final String name;

  /// One line shown after the guess.
  final String fact;
}

/// Rounds in one game.
const int guessRounds = 8;

const List<GuessObject> guessObjects = [
  GuessObject(
    id: 'diya',
    name: 'Diya',
    fact:
        'Diyas are small oil lamps, usually of clay. Lighting them at dusk is '
        'the heart of Diwali.',
  ),
  GuessObject(
    id: 'rangoli',
    name: 'Rangoli',
    fact:
        'Rangoli is floor art made from coloured powder, rice or petals, made '
        'to welcome guests and, by tradition, good fortune.',
  ),
  GuessObject(
    id: 'lantern',
    name: 'Lantern',
    fact:
        'Paper lanterns, such as the star-shaped akash kandil, are hung '
        'outside homes during the Diwali nights.',
  ),
  GuessObject(
    id: 'laddu',
    name: 'Laddu',
    fact:
        'Laddus are sweet balls of flour, ghee and sugar, shared with family '
        'and neighbours at Diwali.',
  ),
  GuessObject(
    id: 'sparkler',
    name: 'Sparkler',
    fact:
        'Sparklers, called phuljhadi, burn very hot. Use them only with care, '
        'and keep young children well away.',
  ),
  GuessObject(
    id: 'garland',
    name: 'Marigold garland',
    fact:
        'Marigold garlands hang on doors and shrines, because marigolds are '
        'considered auspicious.',
  ),
  GuessObject(
    id: 'thali',
    name: 'Puja thali',
    fact:
        'A puja thali holds a diya, flowers, kumkum and sweets for Lakshmi '
        'Puja.',
  ),
  GuessObject(
    id: 'rocket',
    name: 'Firework rocket',
    fact:
        'Fireworks are part of Diwali in many places, though many cities now '
        'limit them for safety and cleaner air.',
  ),
];

GuessObject? guessObjectById(String id) {
  for (final o in guessObjects) {
    if (o.id == id) return o;
  }
  return null;
}

/// Builds the questions for one game: each object gets its own name plus
/// three other objects' names as wrong answers, picked from [seed]. Fed to
/// the same session logic as the quiz.
List<QuizQuestion> buildGuessQuestions(int seed) {
  return [
    for (var i = 0; i < guessObjects.length; i++)
      () {
        final object = guessObjects[i];
        final others = [
          for (final o in guessObjects)
            if (o.id != object.id) o.name,
        ]..shuffle(Random(seed + i * 31));
        return QuizQuestion(
          id: object.id,
          prompt: 'What is this Diwali object?',
          options: [object.name, ...others.take(3)],
          correctIndex: 0,
          explanation: object.fact,
          category: QuizCategory.traditions,
        );
      }(),
  ];
}
