import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/content/quiz_questions.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/quiz_session.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/quiz_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/quiz_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_theme.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/diwali_motion.dart';

import '../../helpers.dart';

class _Store implements QuizStore {
  int? best;
  @override
  Future<int?> bestScore() async => best;
  @override
  Future<void> saveBestScore(int score) async => best = score;
}

QuizSession _run([int seed = 1]) =>
    QuizSession.start(quizQuestions, seed: seed);

/// Answers every question; [correct] decides which ones are right.
QuizSession _play(QuizSession s, bool Function(int index) correct) {
  var session = s;
  for (var i = 0; i < session.total; i++) {
    final item = session.current;
    final right = item.correctIndex;
    final wrong = (right + 1) % item.options.length;
    session = session.answer(correct(i) ? right : wrong).next();
  }
  return session;
}

void main() {
  reduceMotionForAllTests();

  group('quiz content', () {
    test('the pool is large enough and ids are unique', () {
      expect(quizQuestions.length, greaterThanOrEqualTo(20));
      expect(quizQuestions.length, greaterThan(quizLength));
      expect(
        quizQuestions.map((q) => q.id).toSet().length,
        quizQuestions.length,
      );
    });

    test('every question is well formed', () {
      for (final q in quizQuestions) {
        expect(q.prompt.trim(), isNotEmpty, reason: q.id);
        expect(q.options.length, 4, reason: q.id);
        expect(q.options.toSet().length, 4, reason: '${q.id} duplicate option');
        expect(q.options.every((o) => o.trim().isNotEmpty), isTrue);
        expect(q.correctIndex, inInclusiveRange(0, 3), reason: q.id);
        expect(q.explanation.trim(), isNotEmpty, reason: q.id);
      }
    });

    test('all five categories are covered', () {
      expect(
        quizQuestions.map((q) => q.category).toSet(),
        QuizCategory.values.toSet(),
      );
    });
  });

  group('QuizSession', () {
    test('draws ten distinct questions', () {
      final s = _run();
      expect(s.total, quizLength);
      expect(s.items.map((i) => i.question.id).toSet().length, quizLength);
      expect(s.index, 0);
      expect(s.finished, isFalse);
      expect(s.score, 0);
    });

    test('the same seed gives the same run; another seed differs', () {
      List<String> ids(QuizSession s) => [
        for (final i in s.items) '${i.question.id}:${i.options.join('|')}',
      ];
      expect(ids(_run(7)), ids(_run(7)));
      expect(ids(_run(7)), isNot(ids(_run(8))));
    });

    test('shuffling keeps the correct answer correct', () {
      for (var seed = 0; seed < 25; seed++) {
        for (final item in _run(seed).items) {
          final q = item.question;
          expect(item.options.toSet(), q.options.toSet());
          expect(item.correctOption, q.options[q.correctIndex]);
        }
      }
    });

    test('options are not always left in authored order', () {
      final positions = {
        for (var seed = 0; seed < 25; seed++)
          for (final item in _run(seed).items) item.correctIndex,
      };
      expect(positions.length, 4, reason: 'correct answer lands in every slot');
    });

    test('an answer locks and cannot be changed', () {
      final s = _run();
      final right = s.current.correctIndex;
      final wrong = (right + 1) % 4;
      final first = s.answer(wrong);
      expect(first.currentAnswer, wrong);
      expect(identical(first.answer(right), first), isTrue);
      expect(first.score, 0);
    });

    test('bad option numbers are ignored', () {
      final s = _run();
      expect(identical(s.answer(-1), s), isTrue);
      expect(identical(s.answer(4), s), isTrue);
    });

    test('next needs an answer, then advances', () {
      final s = _run();
      expect(identical(s.next(), s), isTrue);
      final n = s.answer(0).next();
      expect(n.index, 1);
      expect(n.currentAnswer, isNull);
      expect(n.finished, isFalse);
    });

    test('the last next finishes; nothing changes afterwards', () {
      final done = _play(_run(), (_) => true);
      expect(done.finished, isTrue);
      expect(identical(done.answer(0), done), isTrue);
      expect(identical(done.next(), done), isTrue);
    });

    test('scores: all right, all wrong, mixed', () {
      expect(_play(_run(), (_) => true).score, 10);
      expect(_play(_run(), (_) => false).score, 0);
      expect(_play(_run(), (i) => i.isEven).score, 5);
      expect(_play(_run(), (i) => i < 8).score, 8);
    });

    test('review matches the choices', () {
      final done = _play(_run(), (i) => i != 3);
      for (var i = 0; i < done.total; i++) {
        expect(done.isCorrect(i), i != 3);
      }
    });

    test('tiers by score', () {
      expect(QuizTier.forScore(0, 10), QuizTier.keepExploring);
      expect(QuizTier.forScore(4, 10), QuizTier.keepExploring);
      expect(QuizTier.forScore(5, 10), QuizTier.brightSpark);
      expect(QuizTier.forScore(7, 10), QuizTier.brightSpark);
      expect(QuizTier.forScore(8, 10), QuizTier.dazzler);
      expect(QuizTier.forScore(10, 10), QuizTier.dazzler);
      expect(QuizTier.forScore(0, 0), QuizTier.keepExploring);
    });
  });

  group('QuizSection', () {
    late _Store store;

    Widget app({double scale = 1, Size size = const Size(360, 800)}) =>
        ProviderScope(
          overrides: [
            quizStoreProvider.overrideWithValue(store),
            quizSeedProvider.overrideWithValue(() => 3),
          ],
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              disableAnimations: true,
              textScaler: TextScaler.linear(scale),
            ),
            child: MaterialApp(
              theme: DiwaliTheme.data,
              home: const Scaffold(
                body: DiwaliMotionScope(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: QuizSection(),
                  ),
                ),
              ),
            ),
          ),
        );

    setUp(() => store = _Store());

    void quizTest(
      String name,
      Future<void> Function(WidgetTester tester) body, {
      Size size = const Size(360, 800),
      double scale = 1,
      int? best,
    }) => testWidgets(name, (tester) async {
      store.best = best;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(scale: scale, size: size));
      await tester.pumpAndSettle();
      await body(tester);
    });

    final expected = QuizSession.start(quizQuestions, seed: 3);

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    Future<void> answer(
      WidgetTester tester,
      int q, {
      required bool right,
    }) async {
      final item = expected.items[q];
      final pick = right ? item.correctIndex : (item.correctIndex + 1) % 4;
      await tapText(tester, item.options[pick]);
    }

    quizTest('poster shows the best score and a Start button', best: 8, (
      tester,
    ) async {
      expect(find.text('Deepavali Quiz'), findsOneWidget);
      expect(find.text('Best: 8 / 10'), findsOneWidget);
      expect(find.text('Start quiz'), findsOneWidget);
    });

    quizTest('a perfect run reaches the results and saves the best', (
      tester,
    ) async {
      await tapText(tester, 'Start quiz');
      for (var q = 0; q < 10; q++) {
        expect(find.text('Question ${q + 1} of 10'), findsOneWidget);
        expect(find.text(expected.items[q].question.prompt), findsOneWidget);
        await answer(tester, q, right: true);
        expect(find.text('Correct!'), findsOneWidget);
        await tapText(tester, q == 9 ? 'See results' : 'Next');
      }
      expect(find.text('You scored 10 / 10'), findsOneWidget);
      expect(find.textContaining('Diwali Dazzler'), findsOneWidget);
      expect(find.text('Play again'), findsOneWidget);
      expect(store.best, 10);
    });

    quizTest('wrong answers show the right one and the explanation', (
      tester,
    ) async {
      await tapText(tester, 'Start quiz');
      await answer(tester, 0, right: false);
      final item = expected.items[0];
      expect(
        find.text('Not quite. The answer is ${item.correctOption}.'),
        findsOneWidget,
      );
      expect(find.text(item.question.explanation), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    quizTest('a locked answer cannot be changed by tapping another option', (
      tester,
    ) async {
      await tapText(tester, 'Start quiz');
      await answer(tester, 0, right: false);
      final item = expected.items[0];
      await tapText(tester, item.correctOption);
      expect(
        find.text('Not quite. The answer is ${item.correctOption}.'),
        findsOneWidget,
      );
    });

    quizTest('Next is disabled until an answer is chosen', (tester) async {
      await tapText(tester, 'Start quiz');
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Question 1 of 10'), findsOneWidget);
      await answer(tester, 0, right: true);
      await tapText(tester, 'Next');
      expect(find.text('Question 2 of 10'), findsOneWidget);
    });

    quizTest(
      'a low score lists the misses and keeps a lower best out',
      best: 9,
      (tester) async {
        await tapText(tester, 'Start quiz');
        for (var q = 0; q < 10; q++) {
          await answer(tester, q, right: q < 4);
          await tapText(tester, q == 9 ? 'See results' : 'Next');
        }
        expect(find.text('You scored 4 / 10'), findsOneWidget);
        expect(find.textContaining('Keep exploring'), findsOneWidget);
        expect(find.textContaining('Your answer:'), findsNWidgets(6));
        expect(store.best, 9);
      },
    );

    quizTest('quitting asks first and can be cancelled', (tester) async {
      await tapText(tester, 'Start quiz');
      await answer(tester, 0, right: true);
      await tapText(tester, 'Quit');
      expect(find.text('Leave the quiz?'), findsOneWidget);
      await tapText(tester, 'Keep playing');
      expect(find.text('Question 1 of 10'), findsOneWidget);

      await tapText(tester, 'Quit');
      await tapText(tester, 'Leave');
      expect(find.text('Start quiz'), findsOneWidget);
    });

    quizTest('Play again starts a fresh run', (tester) async {
      await tapText(tester, 'Start quiz');
      for (var q = 0; q < 10; q++) {
        await answer(tester, q, right: true);
        await tapText(tester, q == 9 ? 'See results' : 'Next');
      }
      await tapText(tester, 'Play again');
      expect(find.text('Question 1 of 10'), findsOneWidget);
    });

    for (final (name, size, scale) in [
      ('320x568 at 2x text', const Size(320, 568), 2.0),
      ('600x900', const Size(600, 900), 1.0),
    ]) {
      quizTest('every state fits at $name', size: size, scale: scale, (
        tester,
      ) async {
        await tapText(tester, 'Start quiz');
        expect(tester.takeException(), isNull);
        for (var q = 0; q < 10; q++) {
          await answer(tester, q, right: q.isEven);
          expect(tester.takeException(), isNull);
          await tapText(tester, q == 9 ? 'See results' : 'Next');
        }
        expect(find.textContaining('You scored'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
