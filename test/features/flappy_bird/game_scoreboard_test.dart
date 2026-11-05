import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/game_score.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/flappy_bird_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/presentation/game_scoreboard_section.dart';

Future<void> _pump(
  WidgetTester tester,
  Future<List<GameScore>> Function() load,
) async {
  // The smallest supported phone, at twice the text size.
  tester.view
    ..physicalSize = const Size(640, 1136)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [gameScoresProvider.overrideWith((ref) => load())],
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(child: GameScoreboardSection()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows every game with its points and the combined total', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => const [
        GameScore(
          slug: 'flappy_bird',
          name: 'Flappy Bird',
          bestScore: 14,
          gamesPlayed: 9,
          ceiling: 100,
          points: 140,
        ),
        GameScore(
          slug: 'pacman',
          name: 'Pac-Man',
          bestScore: 0,
          gamesPlayed: 0,
          ceiling: 200,
          points: 0,
        ),
      ],
    );

    expect(find.text('Flappy Bird'), findsOneWidget);
    expect(find.text('Pac-Man'), findsOneWidget);
    expect(find.text('Not played yet'), findsOneWidget);
    expect(find.text('140 pts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without points it shows best scores and no combined total', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => const [
        GameScore(
          slug: 'flappy_bird',
          name: 'Flappy Bird',
          bestScore: 14,
          gamesPlayed: 9,
        ),
      ],
    );

    expect(find.text('14'), findsOneWidget);
    expect(find.text('9 played'), findsOneWidget);
    expect(find.text('Combined score'), findsNothing);
  });

  testWidgets('a failed load shows a retry button, not a spinner', (
    tester,
  ) async {
    await _pump(tester, () async => throw Exception('offline'));

    expect(find.text('Your game scores could not be loaded.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
