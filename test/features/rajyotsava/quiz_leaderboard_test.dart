import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/models.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/quiz_scores.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/quiz_session.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/quiz_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_providers.dart';

import '../../helpers.dart';

QuizQuestion _q(String id, QuizDifficulty difficulty) => QuizQuestion(
  id: id,
  difficulty: difficulty,
  question: id,
  options: const ['a', 'b', 'c', 'd'],
  answerIndex: 2,
  explanation: '',
);

/// A leaderboard the test controls.
class FakeScoreboard implements QuizScoreboard {
  FakeScoreboard({
    this.outcome = const QuizSaved(best: 900, isNewBest: true, rounds: 3),
    this.available = true,
  });

  final QuizSaveOutcome outcome;
  final bool available;
  final List<QuizRoundResult> saved = [];
  var pendingSends = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<QuizSaveOutcome> save(QuizRoundResult result) async {
    saved.add(result);
    return available ? outcome : const QuizNotSaved();
  }

  @override
  Future<void> sendPending() async => pendingSends++;

  @override
  Future<QuizStanding?> standing() async =>
      const QuizStanding(best: 900, rounds: 3, rank: 4);

  @override
  Future<List<QuizLeader>> leaders({int limit = 10}) async => const [
    QuizLeader(rank: 1, name: 'Asha', points: 2100, isYou: false),
    QuizLeader(rank: 4, name: 'Chethan', points: 900, isYou: true),
  ];
}

void main() {
  group('points', () {
    test('harder questions are worth more; wrong answers nothing', () {
      int points(QuizDifficulty d, {bool correct = true, int seconds = 30}) =>
          QuizPoints.forAnswer(
            difficulty: d,
            correct: correct,
            took: Duration(seconds: seconds),
          );
      expect(points(QuizDifficulty.easy), 100);
      expect(points(QuizDifficulty.medium), 150);
      expect(points(QuizDifficulty.hard), 200);
      expect(points(QuizDifficulty.hard, correct: false, seconds: 0), 0);
    });

    test('a quick answer earns up to 50 more, falling over 10 s', () {
      int bonus(int ms) =>
          QuizPoints.forAnswer(
            difficulty: QuizDifficulty.easy,
            correct: true,
            took: Duration(milliseconds: ms),
          ) -
          QuizPoints.easy;
      expect(bonus(0), 50);
      expect(bonus(5000), 25);
      expect(bonus(10000), 0);
      expect(bonus(60000), 0);
    });

    test('the best possible round fits the backend limit (2500)', () {
      // 10 questions, at most 4 hard, all instant.
      const best =
          4 * (QuizPoints.hard + QuizPoints.maxSpeedBonus) +
          6 * (QuizPoints.medium + QuizPoints.maxSpeedBonus);
      expect(best, 2200);
      expect(best, lessThanOrEqualTo(2500));
    });
  });

  group('session', () {
    final t0 = DateTime.utc(2026, 11, 4, 10);

    test('times each answer from when its question appears', () {
      var s = QuizSession(
        [_q('a', QuizDifficulty.easy), _q('b', QuizDifficulty.hard)],
        id: 'round',
        at: t0,
      );
      s = s.answer(2, at: t0.add(const Duration(seconds: 2)));
      expect(s.pointsFor(0), 100 + 40);
      // Reading the explanation does not count against the next question.
      s = s.next(at: t0.add(const Duration(seconds: 20)));
      s = s.answer(0, at: t0.add(const Duration(seconds: 21)));
      expect(s.pointsFor(1), 0, reason: 'wrong');
      s = s.next(at: t0.add(const Duration(seconds: 25)));

      final result = s.result!;
      expect(result.id, 'round');
      expect(result.points, 140);
      expect(result.correct, 1);
      expect(result.total, 2);
      expect(result.startedAt, t0);
      expect(result.duration, const Duration(seconds: 21));
    });

    test('no result until the round is finished', () {
      final s = QuizSession([_q('a', QuizDifficulty.easy)], at: t0);
      expect(s.result, isNull);
      expect(s.answer(2).result, isNull);
      expect(s.answer(2).next().result, isNotNull);
    });

    test('a round survives being stored on the phone', () {
      final result = QuizRoundResult(
        id: 'x',
        points: 1234,
        correct: 8,
        total: 10,
        duration: const Duration(seconds: 95),
        startedAt: t0,
      );
      final back = QuizRoundResult.fromJson(result.toJson())!;
      expect(back.id, 'x');
      expect(back.points, 1234);
      expect(back.correct, 8);
      expect(back.duration, const Duration(seconds: 95));
      expect(back.startedAt, t0);
      expect(QuizRoundResult.fromJson({'id': 'x'}), isNull);
    });

    test('round ids are random version 4 UUIDs', () {
      final random = Random(1);
      final a = newRoundId(random);
      expect(
        a,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
            r'[0-9a-f]{12}$',
          ),
        ),
      );
      expect(newRoundId(random), isNot(a));
    });
  });

  group('results screen', () {
    Future<FakeScoreboard> play(
      WidgetTester tester, {
      FakeScoreboard? scoreboard,
      Size size = const Size(400, 2400),
      double text = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = text;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final board = scoreboard ?? FakeScoreboard();
      var now = DateTime.utc(2026, 11, 4, 10);
      await tester.pumpWidget(
        testApp(
          overrides: [
            quizScoreboardProvider.overrideWithValue(board),
            rajyotsavaClockProvider.overrideWithValue(() => now),
            // The same questions every run.
            quizRandomProvider.overrideWithValue(Random(7)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push<void>(RajyotsavaRoutes.quiz)
          .ignore();
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).last),
      );
      // The quiz's own list, not the tab's behind it.
      final quizList = find
          .descendant(
            of: find.byType(QuizPage),
            matching: find.byType(Scrollable),
          )
          .first;
      for (var i = 0; i < QuizController.questionsPerRound; i++) {
        final right = container.read(quizControllerProvider).current!;
        now = now.add(const Duration(seconds: 1));
        final option = find.byKey(ValueKey('quiz-option-${right.answerIndex}'));
        await tester.scrollUntilVisible(option, 200, scrollable: quizList);
        await tester.ensureVisible(option);
        await tester.pump();
        await tester.tap(option);
        await tester.pump();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('quiz-next')),
          200,
          scrollable: quizList,
        );
        expect(find.byKey(const ValueKey('quiz-answer-points')), findsOne);
        now = now.add(const Duration(seconds: 5));
        await tester.ensureVisible(find.byKey(const ValueKey('quiz-next')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('quiz-next')));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      return board;
    }

    testWidgets('shows points, saves the round once, and the leaderboard', (
      tester,
    ) async {
      final board = await play(tester);
      expect(board.pendingSends, 1, reason: 'old rounds sent on opening');
      expect(board.saved, hasLength(1));
      final round = board.saved.single;
      expect(round.correct, 10);
      // Every answer took 1 s: base points plus a 45-point bonus each.
      expect(round.points, greaterThanOrEqualTo(10 * (100 + 45)));
      expect(find.text('${round.points} points'), findsOneWidget);
      expect(find.text('New personal best!'), findsOneWidget);
      expect(
        find.text('Your best: 900 points · Rank #4 · 3 rounds'),
        findsOneWidget,
      );
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Chethan (you)'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // A new round does not resend the old one.
      await tester.ensureVisible(find.byKey(const ValueKey('quiz-restart')));
      await tester.tap(find.byKey(const ValueKey('quiz-restart')));
      await tester.pump();
      expect(board.saved, hasLength(1));
    });

    testWidgets('offline, the round is kept on the phone', (tester) async {
      await play(
        tester,
        scoreboard: FakeScoreboard(outcome: const QuizQueued()),
      );
      expect(find.textContaining('Saved on this phone'), findsOneWidget);
    });

    testWidgets('without a backend there is no leaderboard', (tester) async {
      await play(tester, scoreboard: FakeScoreboard(available: false));
      expect(find.byKey(const ValueKey('quiz-leaderboard')), findsNothing);
      expect(find.byKey(const ValueKey('quiz-points')), findsOneWidget);
    });

    testWidgets('the leaderboard fits a small phone at 2x text', (
      tester,
    ) async {
      await play(
        tester,
        size: AppTestScreens.smallestPhone,
        text: AppTextScale.max,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Chethan (you)'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(QuizPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
