import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_diwali/domain/game_music.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_diwali/domain/game_over_audio.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_diwali/domain/pacman_scoreboard.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_diwali/pacman_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_diwali/presentation/pacman_game_page.dart';

import '../helpers.dart';

class _SilentMusic implements GameMusic {
  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _CountingAudio implements GameOverAudio {
  int plays = 0;
  int stops = 0;

  @override
  Future<void> play() async => plays++;

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async {}
}

void main() {
  reduceMotionForAllTests();

  testWidgets('being caught plays the game-over sound once; restart stops it', (
    tester,
  ) async {
    final audio = _CountingAudio();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameOverAudioProvider.overrideWithValue(audio),
          gameMusicProvider.overrideWithValue(_SilentMusic()),
          pacmanScoreboardProvider.overrideWithValue(
            const NoPacmanScoreboard(),
          ),
        ],
        child: const MaterialApp(home: PacmanGamePage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Play'));

    // Pacman stands still after hitting a wall, so a ghost always gets there.
    var steps = 0;
    while (audio.plays == 0 && steps++ < 6000) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(audio.plays, 1, reason: 'sound should start when caught');
    expect(find.textContaining('Caught!'), findsOneWidget);

    // Staying on the game-over screen does not replay it.
    await tester.pump(const Duration(seconds: 2));
    expect(audio.plays, 1);

    await tester.tap(find.text('Restart'));
    await tester.pump();
    expect(audio.stops, greaterThanOrEqualTo(1));
    await tester.pumpWidget(const SizedBox());
  });
}
