import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/content/guess_objects.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/content/quiz_questions.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/deepavali_scores.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/diya_game.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/diya_game_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/quiz_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/game_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/guess_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/quiz_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/scoreboard_card.dart';

/// A leaderboard the test controls.
class FakeScoreboard implements DeepavaliScoreboard {
  FakeScoreboard({
    this.outcome = const ScoreSaved(best: 900, isNewBest: true, rounds: 3),
    this.available = true,
    this.leaderRows = const [
      ScoreLeader(rank: 1, name: 'Asha', points: 1400, isYou: false),
      ScoreLeader(rank: 4, name: 'Chethan', points: 900, isYou: true),
    ],
  });

  final ScoreSaveOutcome outcome;
  final bool available;
  final List<ScoreLeader> leaderRows;
  final List<GameRound> saved = [];
  var pendingSends = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<ScoreSaveOutcome> save(GameRound round) async {
    saved.add(round);
    return available ? outcome : const ScoreNotSaved();
  }

  @override
  Future<void> sendPending() async => pendingSends++;

  @override
  Future<ScoreStanding?> standing(DeepavaliGame game) async =>
      const ScoreStanding(best: 900, rounds: 3, rank: 4);

  @override
  Future<List<ScoreLeader>> leaders(
    DeepavaliGame game, {
    int limit = 10,
  }) async => leaderRows;
}

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

/// A wall clock and a play clock the test moves by hand.
class _Clocks {
  DateTime wall = DateTime.utc(2026, 11, 3, 12);
  Duration play = Duration.zero;

  void advance(Duration d) {
    wall = wall.add(d);
    play += d;
  }
}

const Duration _s = Duration(seconds: 1);

void main() {
  group('points', () {
    int answers(int correct, int total, Duration took) =>
        DeepavaliPoints.forAnswers(
          correct: correct,
          total: total,
          duration: took,
        );

    test('100 per correct answer, nothing for none', () {
      expect(answers(0, 10, Duration.zero), 0);
      expect(answers(1, 10, const Duration(minutes: 5)), 100);
      expect(answers(7, 10, const Duration(minutes: 5)), 700);
    });

    test('speed adds up to 50 per correct answer, falling over 10 s each', () {
      expect(answers(10, 10, Duration.zero), 1500);
      expect(answers(10, 10, const Duration(seconds: 50)), 1250);
      expect(answers(10, 10, const Duration(seconds: 100)), 1000);
      expect(answers(10, 10, const Duration(minutes: 30)), 1000);
      expect(answers(8, 8, Duration.zero), 1200);
    });

    test('at the same speed, one more correct answer is always worth more', () {
      for (final took in [Duration.zero, _s * 30, const Duration(minutes: 5)]) {
        for (var correct = 1; correct < 10; correct++) {
          expect(
            answers(correct + 1, 10, took),
            greaterThan(answers(correct, 10, took)),
          );
        }
      }
    });

    test('harder diya levels score more; time left adds up to 500', () {
      int diya(DiyaDifficulty d, Duration took) =>
          DeepavaliPoints.forDiya(difficulty: d, elapsed: took);
      expect(diya(DiyaDifficulty.gentle, DiyaDifficulty.gentle.limit), 500);
      expect(diya(DiyaDifficulty.breezy, DiyaDifficulty.breezy.limit), 1000);
      expect(diya(DiyaDifficulty.stormy, DiyaDifficulty.stormy.limit), 1500);
      expect(diya(DiyaDifficulty.stormy, Duration.zero), 2000);
      expect(
        diya(DiyaDifficulty.breezy, DiyaDifficulty.breezy.limit ~/ 2),
        1250,
      );
      // Winning faster is always worth more at the same level.
      expect(
        diya(DiyaDifficulty.breezy, _s * 5),
        greaterThan(diya(DiyaDifficulty.breezy, _s * 6)),
      );
    });
  });

  group('the migration matches the app', () {
    final sql = File('supabase/migrations/202611040002_deepavali_games.sql')
        .readAsStringSync();

    ({int maxScore, int perScoreMs}) limits(DeepavaliGame game) {
      final row = RegExp(
        "\\('${game.slug}',\\s*'[^']+',\\s*(\\d+),\\s*(\\d+),\\s*(\\d+)\\)",
      ).firstMatch(sql);
      expect(row, isNotNull, reason: '${game.slug} is not registered');
      expect(int.parse(row!.group(2)!), 3600000);
      return (
        maxScore: int.parse(row.group(1)!),
        perScoreMs: int.parse(row.group(3)!),
      );
    }

    // The server rejects a score when duration < (score - 5) x ms per point.
    bool plausible(GameRound round, int perScoreMs) =>
        round.points <= 5 ||
        round.duration.inMilliseconds >= (round.points - 5) * perScoreMs;

    test('every game is registered, and its best score fits the limit', () {
      final best = {
        DeepavaliGame.quiz: DeepavaliPoints.forAnswers(
          correct: quizLength,
          total: quizLength,
          duration: Duration.zero,
        ),
        DeepavaliGame.guess: DeepavaliPoints.forAnswers(
          correct: guessRounds,
          total: guessRounds,
          duration: Duration.zero,
        ),
        DeepavaliGame.diya: DeepavaliPoints.forDiya(
          difficulty: DiyaDifficulty.stormy,
          elapsed: Duration.zero,
        ),
      };
      for (final game in DeepavaliGame.values) {
        expect(best[game]!, lessThanOrEqualTo(limits(game).maxScore));
      }
    });

    test('a person is never rejected as too fast', () {
      GameRound round(DeepavaliGame game, int points, Duration took) =>
          GameRound(
            id: 'x',
            game: game,
            points: points,
            duration: took,
            startedAt: DateTime.utc(2026),
          );
      // Perfect quiz at 2 s a question; perfect guessing at 2 s an object.
      final quiz = round(
        DeepavaliGame.quiz,
        DeepavaliPoints.forAnswers(
          correct: quizLength,
          total: quizLength,
          duration: _s * 2 * quizLength,
        ),
        _s * 2 * quizLength,
      );
      final guess = round(
        DeepavaliGame.guess,
        DeepavaliPoints.forAnswers(
          correct: guessRounds,
          total: guessRounds,
          duration: _s * 2 * guessRounds,
        ),
        _s * 2 * guessRounds,
      );
      // The diyas lit in 3 s on the hardest level.
      final diya = round(
        DeepavaliGame.diya,
        DeepavaliPoints.forDiya(
          difficulty: DiyaDifficulty.stormy,
          elapsed: _s * 3,
        ),
        _s * 3,
      );
      expect(plausible(quiz, limits(DeepavaliGame.quiz).perScoreMs), isTrue);
      expect(plausible(guess, limits(DeepavaliGame.guess).perScoreMs), isTrue);
      expect(plausible(diya, limits(DeepavaliGame.diya).perScoreMs), isTrue);
    });

    test('a bot is rejected as too fast', () {
      final instantQuiz = GameRound(
        id: 'x',
        game: DeepavaliGame.quiz,
        points: 1500,
        duration: const Duration(milliseconds: 200),
        startedAt: DateTime.utc(2026),
      );
      expect(
        plausible(instantQuiz, limits(DeepavaliGame.quiz).perScoreMs),
        isFalse,
      );
    });
  });

  group('GameRound', () {
    test('survives being stored on the phone', () {
      final round = GameRound(
        id: newRoundId(Random(1)),
        game: DeepavaliGame.diya,
        points: 1234,
        duration: const Duration(milliseconds: 8123),
        startedAt: DateTime.utc(2026, 11, 3, 9, 30),
      );
      final back = GameRound.fromJson(round.toJson())!;
      expect(back.id, round.id);
      expect(back.game, DeepavaliGame.diya);
      expect(back.points, 1234);
      expect(back.duration, round.duration);
      expect(back.startedAt, round.startedAt);
    });

    test('a damaged or unknown stored game is ignored', () {
      expect(GameRound.fromJson(null), isNull);
      expect(GameRound.fromJson({'id': 'a'}), isNull);
      expect(
        GameRound.fromJson({
          'id': 'a',
          'game': 'flappy_bird',
          'points': 1,
          'durationMs': 1,
          'startedAt': '2026-11-03T00:00:00Z',
        }),
        isNull,
        reason: 'only Deepavali games are queued by this scoreboard',
      );
    });

    test('round ids are valid v4 UUIDs and differ', () {
      final random = Random(7);
      final a = newRoundId(random);
      expect(
        a,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab]')),
      );
      expect(newRoundId(random), isNot(a));
    });

    test('slugs are unique and valid for the backend registry', () {
      final slugs = DeepavaliGame.values.map((g) => g.slug).toList();
      expect(slugs.toSet().length, slugs.length);
      for (final slug in slugs) {
        expect(slug, matches(RegExp(r'^[a-z0-9_]{3,48}$')));
      }
    });
  });

  group('games send their scores', () {
    late FakeScoreboard board;
    late _Clocks clocks;
    late ProviderContainer container;

    setUp(() {
      board = FakeScoreboard();
      clocks = _Clocks();
      container = ProviderContainer(
        overrides: [
          deepavaliScoreboardProvider.overrideWithValue(board),
          deepavaliNowProvider.overrideWithValue(() => clocks.wall),
          diyaGameClockProvider.overrideWithValue(() => clocks.play),
          diyaGameStoreProvider.overrideWithValue(_DiyaStore()),
          diyaGameSeedProvider.overrideWithValue(() => 5),
          quizSeedProvider.overrideWithValue(() => 11),
          quizStoreProvider.overrideWithValue(_QuizStore()),
        ],
      );
    });

    void playQuiz({int took = 40}) {
      final quiz = container.read(quizProvider.notifier)..start();
      clocks.advance(_s * took);
      for (var i = 0; i < quizLength; i++) {
        quiz
          ..answer(0)
          ..next();
      }
    }

    test('a finished quiz is sent once, with its points and time', () async {
      final started = clocks.wall;
      playQuiz();
      final session = container.read(quizProvider)!;
      expect(session.finished, isTrue);
      expect(board.saved, hasLength(1));
      final round = board.saved.single;
      expect(round.game, DeepavaliGame.quiz);
      expect(round.duration, _s * 40);
      expect(round.startedAt, started);
      expect(
        round.points,
        DeepavaliPoints.forAnswers(
          correct: session.score,
          total: quizLength,
          duration: _s * 40,
        ),
      );
      expect(
        await container.read(quizProvider.notifier).saving,
        isA<ScoreSaved>(),
      );
    });

    test('an unfinished quiz sends nothing', () {
      container.read(quizProvider.notifier)
        ..start()
        ..answer(0)
        ..next();
      expect(board.saved, isEmpty);
      expect(container.read(quizProvider.notifier).saving, isNull);
    });

    test('starting a game sends what was kept on the phone, and play again '
        'makes a new id', () {
      playQuiz();
      final first = board.saved.single.id;
      expect(board.pendingSends, 1);
      playQuiz();
      expect(board.pendingSends, 2);
      expect(board.saved, hasLength(2));
      expect(board.saved.last.id, isNot(first));
    });

    test('next after the last question does not send again', () {
      playQuiz();
      container.read(quizProvider.notifier).next();
      expect(board.saved, hasLength(1));
    });

    test('quitting a finished quiz and starting another is a new game', () {
      playQuiz();
      container.read(quizProvider.notifier).quit();
      expect(container.read(quizProvider.notifier).saving, isNotNull);
      container.read(quizProvider.notifier).start();
      expect(container.read(quizProvider.notifier).saving, isNull);
    });

    test('a finished guessing game is sent as its own game', () {
      final guess = container.read(guessProvider.notifier)..start();
      clocks.advance(_s * 30);
      for (var i = 0; i < guessRounds; i++) {
        guess
          ..answer(0)
          ..next();
      }
      final session = container.read(guessProvider)!;
      expect(board.saved, hasLength(1));
      final round = board.saved.single;
      expect(round.game, DeepavaliGame.guess);
      expect(
        round.points,
        DeepavaliPoints.forAnswers(
          correct: session.score,
          total: guessRounds,
          duration: _s * 30,
        ),
      );
    });

    testWidgets('a diya win is sent with the level and time', (tester) async {
      final diya = container.read(diyaGameProvider.notifier)
        ..setDifficulty(DiyaDifficulty.breezy)
        ..start();
      clocks.advance(_s * 4);
      for (var i = 0; i < DiyaGame.diyaCount; i++) {
        diya.tap(i);
      }
      await tester.pump();
      expect(container.read(diyaGameProvider).isWin, isTrue);
      expect(board.saved, hasLength(1));
      final round = board.saved.single;
      expect(round.game, DeepavaliGame.diya);
      expect(round.duration, _s * 4);
      expect(
        round.points,
        DeepavaliPoints.forDiya(
          difficulty: DiyaDifficulty.breezy,
          elapsed: _s * 4,
        ),
      );
      expect(diya.saving, isNotNull);
      container.dispose();
    });

    testWidgets('a diya loss is not sent', (tester) async {
      final diya = container.read(diyaGameProvider.notifier)
        ..setDifficulty(DiyaDifficulty.gentle)
        ..start()
        ..tap(0);
      clocks.advance(DiyaDifficulty.gentle.limit + _s);
      await tester.pump(DiyaDifficulty.gentle.limit + _s);
      expect(container.read(diyaGameProvider).phase, DiyaGamePhase.timeUp);
      expect(board.saved, isEmpty);
      expect(diya.saving, isNull);
      container.dispose();
    });

    testWidgets('a relaxed diya win is not ranked', (tester) async {
      final diya = container.read(diyaGameProvider.notifier)
        ..setRelaxed(value: true)
        ..start();
      clocks.advance(_s * 60);
      for (var i = 0; i < DiyaGame.diyaCount; i++) {
        diya.tap(i);
      }
      await tester.pump();
      expect(container.read(diyaGameProvider).isWin, isTrue);
      expect(board.saved, isEmpty);
      expect(diya.saving, isNull);
      container.dispose();
    });

    testWidgets('each diya game gets its own id', (tester) async {
      final diya = container.read(diyaGameProvider.notifier)
        ..setDifficulty(DiyaDifficulty.gentle)
        ..start();
      for (var i = 0; i < DiyaGame.diyaCount; i++) {
        diya.tap(i);
      }
      diya.restart();
      for (var i = 0; i < DiyaGame.diyaCount; i++) {
        diya.tap(i);
      }
      await tester.pump();
      expect(board.saved, hasLength(2));
      expect(board.saved[0].id, isNot(board.saved[1].id));
      container.dispose();
    });

    test('no backend: games play and nothing is saved', () async {
      final offline = ProviderContainer(
        overrides: [
          quizSeedProvider.overrideWithValue(() => 11),
          quizStoreProvider.overrideWithValue(_QuizStore()),
        ],
      );
      addTearDown(offline.dispose);
      expect(
        offline.read(deepavaliScoreboardProvider),
        isA<NoDeepavaliScoreboard>(),
      );
      final quiz = offline.read(quizProvider.notifier)..start();
      for (var i = 0; i < quizLength; i++) {
        quiz
          ..answer(0)
          ..next();
      }
      expect(offline.read(quizProvider)!.finished, isTrue);
      expect(await quiz.saving, isA<ScoreNotSaved>());
    });
  });

  group('ScoreboardCard', () {
    Widget host(
      FakeScoreboard board,
      Future<ScoreSaveOutcome>? saving, {
      Size size = const Size(360, 800),
      double textScale = 1,
    }) => ProviderScope(
      overrides: [deepavaliScoreboardProvider.overrideWithValue(board)],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScoreboardCard(game: DeepavaliGame.quiz, saving: saving),
            ),
          ),
        ),
      ),
    );

    testWidgets('shows the result, standing and top players', (tester) async {
      final board = FakeScoreboard();
      await tester.pumpWidget(host(board, board.save(_round)));
      await tester.pumpAndSettle();
      expect(find.text('Leaderboard · Deepavali Quiz'), findsOneWidget);
      expect(find.text('New personal best!'), findsOneWidget);
      expect(
        find.text('Your best: 900 points · Rank #4 · 3 games'),
        findsOneWidget,
      );
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Chethan (you)'), findsOneWidget);
    });

    testWidgets('says so when the game is waiting for a connection', (
      tester,
    ) async {
      final board = FakeScoreboard(outcome: const ScoreQueued());
      await tester.pumpWidget(host(board, board.save(_round)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Saved on this phone'), findsOneWidget);
      expect(find.text('New personal best!'), findsNothing);
    });

    testWidgets('shows nothing without a leaderboard or a ranked game', (
      tester,
    ) async {
      final offline = FakeScoreboard(available: false);
      await tester.pumpWidget(host(offline, offline.save(_round)));
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNothing);
      expect(find.textContaining('Leaderboard'), findsNothing);

      await tester.pumpWidget(host(FakeScoreboard(), null));
      await tester.pumpAndSettle();
      expect(find.textContaining('Leaderboard'), findsNothing);
    });

    testWidgets('fits 320x568 at 2x text with a very long name', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final board = FakeScoreboard(
        leaderRows: [
          for (var i = 1; i <= 5; i++)
            ScoreLeader(
              rank: i,
              name: 'A player with an extremely long display name $i',
              points: 1500 - i,
              isYou: i == 2,
            ),
        ],
      );
      await tester.pumpWidget(
        host(
          board,
          board.save(_round),
          size: const Size(320, 568),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('extremely long'), findsNWidgets(5));
    });
  });
}

final GameRound _round = GameRound(
  id: 'r',
  game: DeepavaliGame.quiz,
  points: 900,
  duration: const Duration(seconds: 40),
  startedAt: DateTime.utc(2026, 11, 3),
);
