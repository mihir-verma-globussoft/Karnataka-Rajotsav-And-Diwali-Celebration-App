import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/domain/game_over_audio.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/domain/pacman_scoreboard.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/pacman_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/presentation/pacman_game_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/presentation/pacman_intro_page.dart';

import '../helpers.dart';

class _SilentAudio implements GameOverAudio {
  @override
  Future<void> play() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// docs/DESIGN_SYSTEM.md: sub-screens fit 320x568 at 2x text without overflow.
void main() {
  reduceMotionForAllTests();

  void smallestPhone(WidgetTester tester) {
    tester.view.physicalSize = AppTestScreens.smallestPhone;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = AppTextScale.max;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }

  testWidgets('game screen fits and shows the start overlay', (tester) async {
    smallestPhone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameOverAudioProvider.overrideWithValue(_SilentAudio()),
          pacmanScoreboardProvider.overrideWithValue(
            const NoPacmanScoreboard(),
          ),
        ],
        child: const MaterialApp(home: PacmanGamePage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('Play'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // dispose timers
  });

  testWidgets('character popup fits at 2x text', (tester) async {
    smallestPhone(tester);
    await tester.pumpWidget(const MaterialApp(home: PacmanIntroPage()));
    await tester.pumpAndSettle();
    final uma = find.text('Uma Shanker – The Destroyer');
    await tester.scrollUntilVisible(uma, 100);
    await tester.ensureVisible(uma);
    await tester.pump();
    await tester.tap(uma);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
}
