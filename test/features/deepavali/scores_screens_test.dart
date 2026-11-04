import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/content/quiz_questions.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/deepavali_scores.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/diya_game.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/diya_game_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/quiz_session.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/quiz_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/diya_game_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/quiz_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_theme.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/diwali_motion.dart';

import 'scores_test.dart' show FakeScoreboard;

class _QuizStore implements QuizStore {
  @override
  Future<int?> bestScore() async => null;
  @override
  Future<void> saveBestScore(int score) async {}
}

class _DiyaStore implements DiyaGameStore {
  @override
  Future<Duration?> bestTime(DiyaDifficulty difficulty) async => null;
  @override
  Future<void> saveBestTime(DiyaDifficulty difficulty, Duration time) async {}
}

Widget _host(
  FakeScoreboard board,
  Widget section, {
  required Size size,
  required double scale,
}) => ProviderScope(
  overrides: [
    deepavaliScoreboardProvider.overrideWithValue(board),
    quizStoreProvider.overrideWithValue(_QuizStore()),
    quizSeedProvider.overrideWithValue(() => 3),
    diyaGameStoreProvider.overrideWithValue(_DiyaStore()),
    diyaGameClockProvider.overrideWithValue(() => Duration.zero),
    diyaGameSeedProvider.overrideWithValue(() => 5),
  ],
  child: MediaQuery(
    data: MediaQueryData(
      size: size,
      disableAnimations: true,
      textScaler: TextScaler.linear(scale),
    ),
    child: MaterialApp(
      theme: DiwaliTheme.data,
      home: Scaffold(
        body: DiwaliMotionScope(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: section,
          ),
        ),
      ),
    ),
  ),
);

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, size, scale) in [
    ('360x800', const Size(360, 800), 1.0),
    ('320x568 at 2x text', const Size(320, 568), 2.0),
  ]) {
    testWidgets('quiz results show the leaderboard: $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final board = FakeScoreboard();
      await tester.pumpWidget(
        _host(board, const QuizSection(), size: size, scale: scale),
      );
      await tester.pumpAndSettle();

      final run = QuizSession.start(quizQuestions, seed: 3);
      await _tapText(tester, 'Start quiz');
      for (var q = 0; q < quizLength; q++) {
        await _tapText(tester, run.items[q].options[run.items[q].correctIndex]);
        await _tapText(tester, q == quizLength - 1 ? 'See results' : 'Next');
      }

      expect(find.text('You scored 10 / 10'), findsOneWidget);
      expect(find.text('Leaderboard · Deepavali Quiz'), findsOneWidget);
      expect(find.text('New personal best!'), findsOneWidget);
      expect(find.text('Chethan (you)'), findsOneWidget);
      expect(board.saved.single.game, DeepavaliGame.quiz);
      expect(tester.takeException(), isNull);
    });

    testWidgets('diya win shows the leaderboard: $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final board = FakeScoreboard();
      await tester.pumpWidget(
        _host(board, const DiyaGameSection(), size: size, scale: scale),
      );
      await tester.pumpAndSettle();

      await _tapText(tester, 'Gentle');
      await _tapText(tester, 'Start');
      for (var n = 1; n <= DiyaGame.diyaCount; n++) {
        final unlit = find.bySemanticsLabel(RegExp('^Diya $n of 12, unlit'));
        await tester.ensureVisible(unlit);
        await tester.tap(unlit);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('All 12 diyas are glowing!'), findsOneWidget);
      expect(find.text('Leaderboard · Light the Diyas'), findsOneWidget);
      expect(board.saved.single.game, DeepavaliGame.diya);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('no leaderboard: results look as before', (tester) async {
    const size = Size(360, 800);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final board = FakeScoreboard(available: false);
    await tester.pumpWidget(
      _host(board, const QuizSection(), size: size, scale: 1),
    );
    await tester.pumpAndSettle();
    final run = QuizSession.start(quizQuestions, seed: 3);
    await _tapText(tester, 'Start quiz');
    for (var q = 0; q < quizLength; q++) {
      await _tapText(tester, run.items[q].options[run.items[q].correctIndex]);
      await _tapText(tester, q == quizLength - 1 ? 'See results' : 'Next');
    }
    expect(find.text('You scored 10 / 10'), findsOneWidget);
    expect(find.textContaining('Leaderboard'), findsNothing);
    expect(find.text('Play again'), findsOneWidget);
  });
}
