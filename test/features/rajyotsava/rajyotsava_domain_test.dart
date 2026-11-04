import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/bundled_rajyotsava_content.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/models.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/quiz_deck.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/quiz_session.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/rajyotsava_calendar.dart';

const _q1 = QuizQuestion(
  id: 'a',
  difficulty: QuizDifficulty.easy,
  question: 'Q1',
  options: ['x', 'y', 'z', 'w'],
  answerIndex: 1,
  explanation: '',
);
const _q2 = QuizQuestion(
  id: 'b',
  difficulty: QuizDifficulty.easy,
  question: 'Q2',
  options: ['x', 'y', 'z', 'w'],
  answerIndex: 3,
  explanation: '',
);

void main() {
  group('rajyotsavaCountdown', () {
    test('counts down to this year before 1 November', () {
      final c = rajyotsavaCountdown(DateTime(2026, 10, 30));
      expect(c.daysLeft, 2);
      expect(c.year, 2026);
      expect(c.isToday, isFalse);
    });

    test('is today on 1 November', () {
      final c = rajyotsavaCountdown(DateTime(2026, 11, 1, 23, 59));
      expect(c.isToday, isTrue);
      expect(c.year, 2026);
    });

    test('rolls over to next year after 1 November', () {
      final c = rajyotsavaCountdown(DateTime(2026, 11, 3));
      expect(c.daysLeft, 363);
      expect(c.year, 2027);
    });

    test('counts 1956 as the first Rajyotsava', () {
      expect(rajyotsavaCountdown(DateTime(1956, 11, 1)).edition, 1);
      expect(rajyotsavaCountdown(DateTime(2023, 11, 1)).edition, 68);
      expect(rajyotsavaCountdown(DateTime(2026, 11, 1)).editionLabel, '71st');
    });
  });

  test('ordinal', () {
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 71, 72, 111].map(ordinal), [
      '1st',
      '2nd',
      '3rd',
      '4th',
      '11th',
      '12th',
      '13th',
      '21st',
      '22nd',
      '23rd',
      '71st',
      '72nd',
      '111th',
    ]);
  });

  group('QuizSession', () {
    test('scores answers and finishes after the last question', () {
      var s = QuizSession([_q1, _q2]);
      expect(s.current, _q1);
      expect(s.isAnswered, isFalse);

      s = s.answer(1);
      expect(s.score, 1);
      expect(s.isAnswered, isTrue);

      s = s.next().answer(0);
      expect(s.score, 1);
      s = s.next();
      expect(s.isFinished, isTrue);
      expect(s.current, isNull);
      expect(s.answers, [1, 0]);
    });

    test('ignores a second answer and next before answering', () {
      final s = QuizSession([_q1]);
      expect(s.next().index, 0);
      final answered = s.answer(0);
      expect(answered.answer(1).answers, [0]);
    });

    test('ignores out-of-range options', () {
      final s = QuizSession([_q1]);
      expect(s.answer(4).isAnswered, isFalse);
      expect(s.answer(-1).isAnswered, isFalse);
    });

    test('verdict', () {
      expect(quizVerdict(10, 10), contains('Perfect'));
      expect(quizVerdict(7, 10), contains('Great'));
      expect(quizVerdict(4, 10), contains('Good'));
      expect(quizVerdict(1, 10), contains('try again'));
      expect(quizVerdict(0, 0), isNotEmpty);
    });
  });

  group('QuizDeck', () {
    final all = bundledRajyotsavaContent.quiz;

    test('each round has 10 different questions, at most 4 hard', () {
      for (var seed = 0; seed < 50; seed++) {
        final deck = QuizDeck(all, Random(seed));
        for (var round = 0; round < 8; round++) {
          final dealt = deck.deal(10);
          expect(dealt, hasLength(10));
          expect(dealt.toSet(), hasLength(10));
          final hard = dealt.where((q) => q.difficulty == QuizDifficulty.hard);
          expect(hard.length, inInclusiveRange(2, QuizDeck.maxHard));
        }
      }
    });

    test('rounds go from easy to hard', () {
      final dealt = QuizDeck(all, Random(3)).deal(10);
      final levels = [for (final q in dealt) q.difficulty.index];
      expect(levels, orderedEquals([...levels]..sort()));
    });

    test('no question repeats until its group has been used up', () {
      for (var seed = 0; seed < 20; seed++) {
        final deck = QuizDeck(all, Random(seed));
        // Four rounds need at most 16 hard (17 exist) and 32 others (46
        // exist), so all 40 questions must be different.
        final asked = [for (var r = 0; r < 4; r++) ...deck.deal(10)];
        expect(asked.toSet(), hasLength(40), reason: 'seed $seed');
      }
    });

    test('keeps dealing after the deck runs out', () {
      final deck = QuizDeck(all, Random(1));
      for (var r = 0; r < 20; r++) {
        final dealt = deck.deal(10);
        expect(dealt.toSet(), hasLength(10));
      }
    });

    test('shuffling options keeps the right answer', () {
      final q = all.first;
      final shuffled = q.withOptionOrder([3, 1, 0, 2]);
      expect(shuffled.answer, q.answer);
      expect(shuffled.options.toSet(), q.options.toSet());
    });
  });

  group('bundled content', () {
    const c = bundledRajyotsavaContent;

    test('quiz questions are well formed', () {
      expect(c.quiz.length, greaterThanOrEqualTo(60));
      expect(c.quiz.map((q) => q.id).toSet().length, c.quiz.length);
      expect(c.quiz.map((q) => q.question).toSet().length, c.quiz.length);
      for (final level in QuizDifficulty.values) {
        expect(
          c.quiz.where((q) => q.difficulty == level).length,
          greaterThanOrEqualTo(15),
          reason: level.name,
        );
      }
      for (final q in c.quiz) {
        expect(q.options, hasLength(4), reason: q.id);
        expect(q.options.toSet(), hasLength(4), reason: q.id);
        expect(q.answerIndex, inInclusiveRange(0, 3), reason: q.id);
        expect(q.explanation, isNotEmpty, reason: q.id);
      }
    });

    test('alphabet has 49 letters', () {
      expect(c.vowels.length + c.consonants.length, 49);
    });

    test('numbers run from 1 to 10', () {
      expect(c.numbers.map((n) => n.value), List.generate(10, (i) => i + 1));
    });

    test('every phrase category has phrases', () {
      for (final category in PhraseCategory.values) {
        expect(c.phrases.where((p) => p.category == category), isNotEmpty);
      }
    });

    test('discover items have unique, URL-safe ids in every category', () {
      expect(c.discover.map((i) => i.id).toSet().length, c.discover.length);
      for (final item in c.discover) {
        expect(item.id, matches(RegExp(r'^[a-z0-9_]+$')));
        expect(c.discoverItem(item.id), same(item));
      }
      for (final category in DiscoverCategory.values) {
        expect(c.discover.where((i) => i.category == category), isNotEmpty);
      }
      expect(c.discoverItem('missing'), isNull);
    });

    test('home content is present', () {
      expect(c.history, isNotEmpty);
      expect(c.facts, isNotEmpty);
      expect(c.wishes, isNotEmpty);
    });
  });
}
