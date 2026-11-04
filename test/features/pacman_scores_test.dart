import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/domain/game_over_audio.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/domain/pacman_scoreboard.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/pacman_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/presentation/pacman_game_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/presentation/pacman_scores_page.dart';

import '../helpers.dart';

class _SilentAudio implements GameOverAudio {
  @override
  Future<void> play() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeBoard implements PacmanScoreboard {
  _FakeBoard({this.available = true, this.outcome = const PacmanQueued()});

  final bool available;
  final PacmanSaveOutcome outcome;
  final List<PacmanRound> saved = [];

  @override
  bool get isAvailable => available;

  @override
  Future<PacmanSaveOutcome> save(PacmanRound round) async {
    saved.add(round);
    return outcome;
  }

  @override
  Future<void> sendPending() async {}

  @override
  Future<PacmanStanding?> standing() async =>
      const PacmanStanding(best: 42, rounds: 7, total: 180, rank: 3);

  @override
  Future<int?> lastScore() async => 17;

  @override
  Future<List<PacmanLeader>> leaders({int limit = 50}) async => const [
    PacmanLeader(rank: 1, name: 'Uma Shanker', points: 90),
    PacmanLeader(rank: 2, name: 'Karan', points: 61),
    PacmanLeader(rank: 3, name: 'Test', points: 42, isYou: true),
    PacmanLeader(
      rank: 4,
      name: 'A very long player name that must wrap on small phones',
      points: 10,
    ),
  ];
}

void main() {
  reduceMotionForAllTests();

  void smallestPhone(WidgetTester tester) {
    tester.view.physicalSize = AppTestScreens.smallestPhone;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = AppTextScale.max;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }

  Widget scores(PacmanScoreboard board) => ProviderScope(
    overrides: [pacmanScoreboardProvider.overrideWithValue(board)],
    child: const MaterialApp(home: PacmanScoresPage()),
  );

  testWidgets('shows my numbers, last score, rank and the leaderboard', (
    tester,
  ) async {
    await tester.pumpWidget(scores(_FakeBoard()));
    await tester.pumpAndSettle();
    expect(find.text('Personal best'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('180'), findsOneWidget);
    expect(find.text('Last score'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    expect(find.text('#3'), findsOneWidget);
    expect(find.text('Uma Shanker'), findsOneWidget);
    expect(find.text('Test (you)'), findsOneWidget);
  });

  testWidgets('scores screen fits 320x568 at 2x text', (tester) async {
    smallestPhone(tester);
    await tester.pumpWidget(scores(_FakeBoard()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('without an account it explains how to join', (tester) async {
    smallestPhone(tester);
    await tester.pumpWidget(scores(_FakeBoard(available: false)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a finished game is saved once and the result is shown', (
    tester,
  ) async {
    final board = _FakeBoard(
      outcome: const PacmanSaved(best: 9, isNewBest: true, rounds: 2),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameOverAudioProvider.overrideWithValue(_SilentAudio()),
          pacmanScoreboardProvider.overrideWithValue(board),
        ],
        child: const MaterialApp(home: PacmanGamePage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Play'));
    var steps = 0;
    while (board.saved.isEmpty && steps++ < 6000) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump(const Duration(seconds: 2));
    expect(board.saved, hasLength(1));
    expect(board.saved.single.duration, greaterThan(Duration.zero));
    expect(find.textContaining('New personal best: 9'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);

    await tester.tap(find.text('Restart'));
    await tester.pump();
    expect(find.textContaining('New personal best'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('a round survives a round trip through the phone storage', () {
    final round = PacmanRound.finished(
      score: 12,
      duration: const Duration(seconds: 30),
      startedAt: DateTime.utc(2026, 11, 4, 8),
    );
    final back = PacmanRound.fromJson(round.toJson());
    expect(back.id, round.id);
    expect(back.score, 12);
    expect(back.duration, const Duration(seconds: 30));
    expect(back.startedAt, round.startedAt);
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(round.id),
      isTrue,
    );
  });
}
