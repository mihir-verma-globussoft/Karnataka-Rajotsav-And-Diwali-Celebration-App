import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_models.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/presentation/leaderboard_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/presentation/widgets/ar_camera_view.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/presentation/widgets/hunt_celebration.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/presentation/widgets/hunt_widgets.dart';

import '../../helpers.dart';
import 'hunt_fakes.dart';

/// Finishing the hunt ends in a party on the leaderboard: the song, crackers,
/// diyas and the winner's name. Everyone else sees a plain, quiet board.
void main() {
  reduceMotionForAllTests();

  const iWon = [
    HuntLeader(rank: 1, userId: 'me', username: 'Sharuk', points: 90),
    HuntLeader(rank: 2, userId: 'other', username: 'Ravi', points: 20),
  ];
  const raviWon = [
    HuntLeader(rank: 1, userId: 'other', username: 'Ravi', points: 90),
    HuntLeader(rank: 2, userId: 'me', username: 'Sharuk', points: 20),
  ];

  HuntSnapshot snapshot({bool finished = true}) => HuntSnapshot(
    isAdmin: false,
    isActive: true,
    points: 90,
    rank: 1,
    items: [
      item('a1', found: finished),
      item('a2', kind: HuntItemKind.flag, found: true),
    ],
  );

  late CountingSounds sounds;

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(AppDurations.medium);
    await tester.pump(AppDurations.medium);
    await tester.pump(AppDurations.medium);
  }

  Future<void> open(
    WidgetTester tester,
    String route, {
    List<HuntLeader> rows = iWon,
    bool finished = true,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    sounds = CountingSounds();
    final scene = FakeScene();
    await tester.pumpWidget(
      testApp(
        overrides: [
          huntRepositoryProvider.overrideWithValue(
            FakeRepository(
              snapshot: snapshot(finished: finished),
              leaderRows: rows,
            ),
          ),
          pendingFindsProvider.overrideWithValue(FakePendingFinds()),
          huntSoundsProvider.overrideWithValue(sounds),
          arPlatformProvider.overrideWithValue(FakeArPlatform()),
          arSceneFactoryProvider.overrideWithValue((_) => scene),
          arCameraBuilderProvider.overrideWithValue((_, onCreated) {
            scheduleMicrotask(() => onCreated(1));
            return const ColoredBox(color: AppColors.ink);
          }),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push<void>(route)
        .ignore();
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pump();
    await tester.tap(find.text(text));
    await settle(tester);
  }

  void goThrough(WidgetTester tester, List<AppLifecycleState> states) {
    for (final state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  testWidgets('finishing the hunt leads to the song, crackers and the winner', (
    tester,
  ) async {
    await open(tester, ArRoutes.hunt);
    expect(find.text('You found them all!'), findsOneWidget);

    await tapText(tester, 'See the leaderboard');

    expect(sounds.playing, isTrue);
    expect(find.byType(HuntCrackers), findsOneWidget);
    expect(find.text('You are the winner!'), findsOneWidget);
    expect(find.byType(HuntItemArt), findsWidgets, reason: 'diyas and flags');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a finished player coming back from the hub gets the party too', (
    tester,
  ) async {
    await open(tester, ArRoutes.root);
    await tapText(tester, 'See the full leaderboard');
    expect(sounds.playing, isTrue);
    expect(find.byType(HuntCrackers), findsOneWidget);
  });

  testWidgets('a player still hunting gets the plain board from the hub', (
    tester,
  ) async {
    await open(tester, ArRoutes.root, finished: false);
    await tapText(tester, 'See the full leaderboard');
    expect(sounds.musicStarts, 0);
    expect(find.byType(HuntCrackers), findsNothing);
    expect(find.byType(HuntWinnerBanner), findsNothing);
  });

  testWidgets('the plain leaderboard stays quiet', (tester) async {
    await open(tester, ArRoutes.leaderboard);
    expect(sounds.musicStarts, 0);
    expect(find.byType(HuntCrackers), findsNothing);
    expect(find.byType(HuntWinnerBanner), findsNothing);
    expect(find.byTooltip('Mute the song'), findsNothing);
    expect(find.text('Sharuk (you)'), findsOneWidget);
  });

  testWidgets('someone else on top is named as the winner', (tester) async {
    await open(tester, ArRoutes.celebration, rows: raviWon);
    expect(find.text('Winner: Ravi'), findsOneWidget);
    expect(find.text('You are the winner!'), findsNothing);
    expect(find.text('Sharuk (you)'), findsOneWidget, reason: 'still listed');
  });

  testWidgets('an empty board still celebrates, without a winner', (
    tester,
  ) async {
    await open(tester, ArRoutes.celebration, rows: const []);
    expect(sounds.playing, isTrue);
    expect(find.byType(HuntWinnerBanner), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving the page stops the song', (tester) async {
    await open(tester, ArRoutes.celebration);
    expect(sounds.playing, isTrue);

    GoRouter.of(tester.element(find.byType(LeaderboardPage))).pop();
    await settle(tester);

    expect(sounds.playing, isFalse);
  });

  testWidgets('the song stops when the app is hidden, and comes back', (
    tester,
  ) async {
    await open(tester, ArRoutes.celebration);

    goThrough(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden]);
    expect(sounds.playing, isFalse);

    goThrough(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect(sounds.playing, isTrue);
  });

  testWidgets('the song can be muted, and stays muted', (tester) async {
    await open(tester, ArRoutes.celebration);

    await tester.tap(find.byTooltip('Mute the song'));
    await settle(tester);
    expect(sounds.playing, isFalse);

    goThrough(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden]);
    goThrough(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect(sounds.playing, isFalse, reason: 'coming back must not unmute it');

    await tester.tap(find.byTooltip('Play the song'));
    await settle(tester);
    expect(sounds.playing, isTrue);
  });

  testWidgets('crackers hold still when reduced motion is on', (tester) async {
    await open(tester, ArRoutes.celebration);
    expect(find.byType(HuntCrackers), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('crackers burst when motion is allowed', (tester) async {
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await open(tester, ArRoutes.celebration);
    expect(tester.hasRunningAnimations, isTrue);
  });
}
