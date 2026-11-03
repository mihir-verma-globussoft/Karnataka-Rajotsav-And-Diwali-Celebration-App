import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/presentation/pacman_intro_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/pacman_game/presentation/pacman_roster.dart';

void main() {
  Future<void> openIntro(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: PacmanIntroPage()));
    await tester.pump(const Duration(milliseconds: 300));
  }

  FilledButton playButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('shows all six characters', (tester) async {
    await openIntro(tester);
    expect(pacmanEnemies.length, 6);
    for (final e in pacmanEnemies) {
      expect(find.text(e.name), findsOneWidget);
    }
  });

  testWidgets('exactly three must be picked before the selfie step', (
    tester,
  ) async {
    await openIntro(tester);
    expect(playButton(tester).onPressed, isNull);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(ValueKey('pick_$i')));
      await tester.pump();
    }
    expect(playButton(tester).onPressed, isNotNull);

    // A fourth pick is refused.
    await tester.tap(find.byKey(const ValueKey('pick_3')));
    await tester.pump();
    expect(find.textContaining('Only 3 chasers'), findsOneWidget);
    expect(playButton(tester).onPressed, isNotNull);

    // Unpicking one disables the button again.
    await tester.tap(find.byKey(const ValueKey('pick_0')));
    await tester.pump();
    expect(playButton(tester).onPressed, isNull);
  });

  testWidgets('tapping a character performs for 4s, then the popup closes', (
    tester,
  ) async {
    await openIntro(tester);
    await tester.tap(find.text('Karan Halku'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Dialog), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(Dialog), findsOneWidget); // still performing

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Dialog), findsNothing);
  });
}
