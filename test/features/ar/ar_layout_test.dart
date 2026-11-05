import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_availability.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_scene.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_models.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_rules.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/poster_lock.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/presentation/place_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/presentation/widgets/ar_camera_view.dart';

import '../../helpers.dart';
import 'hunt_fakes.dart';

/// docs/DESIGN_SYSTEM.md: every screen must fit the smallest supported phone at
/// the largest supported text size, without overflowing.
void main() {
  reduceMotionForAllTests();
  const longClue =
      'Behind the tallest plant next to the big window in the corner of the '
      'second floor meeting room near the coffee machine, look down';

  HuntSnapshot snapshot({bool admin = false, bool everythingFound = false}) =>
      HuntSnapshot(
        isAdmin: admin,
        isActive: true,
        points: 125,
        rank: 12,
        items: [
          item('a1', found: everythingFound, hint: longClue),
          item('a2', kind: HuntItemKind.flag, found: everythingFound),
          item('b1', zone: 'b', found: true),
          item('c1', zone: 'c', found: true),
          item('d1', zone: 'd', found: true),
        ],
      );

  const leaders = [
    HuntLeader(
      rank: 1,
      userId: 'me',
      username: 'A very long player name indeed',
      points: 125000,
    ),
    HuntLeader(rank: 22, userId: 'other', username: 'Ravi', points: 10),
  ];

  late FakeScene scene;

  Future<void> pumpAt(
    WidgetTester tester,
    String route, {
    required HuntSnapshot data,
    ArAvailability availability = ArAvailability.supported,
    List<HuntLeader> rows = leaders,
    bool adminTools = true,
    FakeRepository? repository,
  }) async {
    tester.view.physicalSize = AppTestScreens.smallestPhone;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = AppTextScale.max;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    scene = FakeScene();
    await tester.pumpWidget(
      testApp(
        modules: [
          for (final module in featureModules)
            if (module.id != 'ar') module,
          ArFeature(adminTools: adminTools),
        ],
        overrides: [
          huntAdminToolsProvider.overrideWithValue(adminTools),
          huntRepositoryProvider.overrideWithValue(
            repository ?? FakeRepository(snapshot: data, leaderRows: rows),
          ),
          pendingFindsProvider.overrideWithValue(FakePendingFinds()),
          huntSoundsProvider.overrideWithValue(SilentSounds()),
          arPlatformProvider.overrideWithValue(FakeArPlatform(availability)),
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
    await tester.pump();
    await tester.pump(AppDurations.medium);
    await tester.pump(AppDurations.medium);
    await tester.pump(AppDurations.medium);
  }

  void lockOn(String poster) {
    for (var i = 0; i < PosterLock.samplesNeeded; i++) {
      scene.emit(sighting(poster));
    }
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(AppDurations.medium);
  }

  /// Lets the message timer run out, so the test ends with none pending.
  Future<void> drainTimers(WidgetTester tester) async {
    await tester.pump(AppDurations.arMessage);
    await tester.pump(AppDurations.medium);
  }

  testWidgets('the game is the AR entry under the Games tab', (tester) async {
    // Tall enough for the Games tab's picture cards to all be on screen.
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    scene = FakeScene();
    await tester.pumpWidget(
      testApp(
        overrides: [
          huntRepositoryProvider.overrideWithValue(
            FakeRepository(snapshot: snapshot(), leaderRows: leaders),
          ),
          pendingFindsProvider.overrideWithValue(FakePendingFinds()),
          arPlatformProvider.overrideWithValue(FakeArPlatform()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-Games')));
    await tester.pumpAndSettle();

    expect(find.text('AR Game'), findsOneWidget);
    expect(find.textContaining('diyas'), findsOneWidget);
    await tester.tap(find.text('AR Game'));
    await tester.pump();
    await tester.pump(AppDurations.medium);
    await tester.pump(AppDurations.medium);
    await tester.pump(AppDurations.medium);

    expect(find.text('Habba Hunt'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-hunting')), findsOneWidget);
    expect(find.byKey(const ValueKey('join-name')), findsNothing);
  });

  testWidgets('the user build has no admin tools, even for an admin', (
    tester,
  ) async {
    await pumpAt(
      tester,
      ArRoutes.root,
      data: snapshot(admin: true),
      adminTools: false,
    );
    expect(find.text('Admin'), findsNothing);
    expect(find.byKey(const ValueKey('admin-place')), findsNothing);
    expect(find.byKey(const ValueKey('admin-unlock')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('the user build does not even have routes to the admin screens', () {
    final paths = const ArFeature(adminTools: false).routes
        .whereType<GoRoute>()
        .map((route) => route.path);
    expect(paths, isNot(contains(ArRoutes.place)));
    expect(paths, isNot(contains(ArRoutes.items)));
    expect(paths, containsAll([ArRoutes.root, ArRoutes.hunt]));
  });

  test('one app for everyone: the admin tools are in, behind the PIN', () {
    expect(huntAdminBuild, isTrue);
    final paths = const ArFeature().routes.whereType<GoRoute>().map(
      (route) => route.path,
    );
    expect(paths, containsAll([ArRoutes.place, ArRoutes.items]));
  });

  testWidgets('the admin build unlocks with the right PIN only', (
    tester,
  ) async {
    final repository = FakeRepository(
      snapshot: snapshot(),
      leaderRows: leaders,
    );
    await pumpAt(
      tester,
      ArRoutes.root,
      data: snapshot(),
      repository: repository,
    );
    expect(find.byKey(const ValueKey('admin-place')), findsNothing);
    expect(tester.takeException(), isNull);

    Future<void> tryPin(String pin) async {
      await tester.tap(find.byTooltip('Admin: enter PIN'));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'the dialog must fit');
      await tester.enterText(find.byKey(const ValueKey('admin-pin')), pin);
      await tester.ensureVisible(
        find.byKey(const ValueKey('admin-pin-submit')),
      );
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('admin-pin-submit')));
      await settle(tester);
    }

    await tryPin('000000');
    expect(find.textContaining('PIN is not right'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-place')), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);

    await tryPin('123456');
    await settle(tester);
    expect(find.text('Admin'), findsOneWidget, reason: 'the card appears now');
    expect(find.byKey(const ValueKey('admin-place')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  group('the admin icon at the top', () {
    const locked = 'Admin: enter PIN';
    const unlocked = 'Place diyas and flags';

    testWidgets('asks for the PIN straight away and unlocks', (tester) async {
      await pumpAt(
        tester,
        ArRoutes.root,
        data: snapshot(),
        repository: FakeRepository(snapshot: snapshot(), leaderRows: leaders),
      );
      // In the top bar, so nobody has to scroll to find it.
      await tester.tap(find.byTooltip(locked));
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey('admin-pin')), '123456');
      await tester.tap(find.byKey(const ValueKey('admin-pin-submit')));
      await settle(tester);
      await settle(tester);

      expect(find.byTooltip(unlocked), findsOneWidget);
      expect(find.byTooltip(locked), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a wrong PIN keeps it locked', (tester) async {
      await pumpAt(tester, ArRoutes.root, data: snapshot());
      await tester.tap(find.byTooltip(locked));
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey('admin-pin')), '000000');
      await tester.tap(find.byKey(const ValueKey('admin-pin-submit')));
      await settle(tester);
      expect(find.textContaining('PIN is not right'), findsOneWidget);
      expect(find.byTooltip(locked), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('once unlocked, it opens the placing screen', (tester) async {
      await pumpAt(tester, ArRoutes.root, data: snapshot(admin: true));
      await tester.tap(find.byTooltip(unlocked));
      await settle(tester);
      await settle(tester);
      expect(find.byType(PlacePage), findsOneWidget);
    });

    testWidgets('is not there when the admin tools are left out', (
      tester,
    ) async {
      await pumpAt(
        tester,
        ArRoutes.root,
        data: snapshot(admin: true),
        adminTools: false,
      );
      expect(find.byTooltip(locked), findsNothing);
      expect(find.byTooltip(unlocked), findsNothing);
    });
  });

  testWidgets('a player sees no Admin card, only the small icon', (
    tester,
  ) async {
    await pumpAt(tester, ArRoutes.root, data: snapshot());
    expect(find.text('Admin'), findsNothing);
    expect(find.textContaining('organiser PIN'), findsNothing);
    expect(find.byTooltip('Admin: enter PIN'), findsOneWidget);
  });

  testWidgets('hub fits, as a player', (tester) async {
    await pumpAt(tester, ArRoutes.root, data: snapshot(), adminTools: false);
    expect(find.text('Keep hunting'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub fits, as an admin, scrolled to the end', (tester) async {
    await pumpAt(tester, ArRoutes.root, data: snapshot(admin: true));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-items')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub fits with nothing placed', (tester) async {
    await pumpAt(
      tester,
      ArRoutes.root,
      data: const HuntSnapshot(
        isAdmin: false,
        isActive: true,
        items: [],
        points: 0,
      ),
      rows: const [],
    );
    expect(find.textContaining('Nothing has been hidden'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub fits on a phone without AR', (tester) async {
    await pumpAt(
      tester,
      ArRoutes.root,
      data: snapshot(),
      availability: ArAvailability.unsupportedDevice,
    );
    expect(find.textContaining('does not support AR'), findsOneWidget);
    expect(find.text('Keep hunting'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub fits when the hunt has closed', (tester) async {
    await pumpAt(
      tester,
      ArRoutes.root,
      data: HuntSnapshot(
        isAdmin: false,
        isActive: false,
        items: snapshot().items,
        points: 5,
      ),
    );
    expect(find.textContaining('has closed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaderboard fits, and marks you', (tester) async {
    await pumpAt(tester, ArRoutes.leaderboard, data: snapshot());
    expect(find.textContaining('(you)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the winners\' party fits, with a very long name', (
    tester,
  ) async {
    await pumpAt(
      tester,
      ArRoutes.celebration,
      data: snapshot(everythingFound: true),
    );
    expect(find.text('You are the winner!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('placed items list fits', (tester) async {
    await pumpAt(tester, ArRoutes.items, data: snapshot(admin: true));
    expect(tester.takeException(), isNull);
  });

  group('hunt', () {
    testWidgets('scanning fits', (tester) async {
      await pumpAt(tester, ArRoutes.hunt, data: snapshot());
      expect(tester.takeException(), isNull);
    });

    testWidgets('locking on fits', (tester) async {
      await pumpAt(tester, ArRoutes.hunt, data: snapshot());
      scene.emit(sighting('a'));
      await settle(tester);
      expect(find.text('Hold steady…'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits with a long clue, a message and a collect button', (
      tester,
    ) async {
      await pumpAt(tester, ArRoutes.hunt, data: snapshot());
      lockOn('a');
      await settle(tester);
      scene.emit(
        const ArNearestChanged(
          itemId: 'a1',
          distance: 2,
          bearing: 0.4,
          onScreen: true,
        ),
      );
      scene.emit(const ArTrackingChanged(ArTracking.tooDark));
      await settle(tester);
      expect(find.byKey(const ValueKey('collect-nearest')), findsOneWidget);
      expect(find.textContaining('Clue:'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await drainTimers(tester);
    });

    testWidgets('tapping the view reaches native, in logical pixels', (
      tester,
    ) async {
      await pumpAt(tester, ArRoutes.hunt, data: snapshot());
      lockOn('a');
      await settle(tester);
      await drainTimers(tester);
      // Open camera, between the top bar and the panel, even at 2x text.
      await tester.tapAt(const Offset(160, 170));
      await settle(tester);
      expect(scene.taps.single, [160, 170]);
    });

    testWidgets('finished screen fits', (tester) async {
      await pumpAt(
        tester,
        ArRoutes.hunt,
        data: snapshot(everythingFound: true),
      );
      expect(find.text('You found them all!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a session failure shows a way back', (tester) async {
      await pumpAt(tester, ArRoutes.hunt, data: snapshot());
      scene.emit(const ArFailed('session_failed'));
      await settle(tester);
      expect(find.text('Go back'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('placing', () {
    testWidgets('non-admins are told no', (tester) async {
      await pumpAt(tester, ArRoutes.place, data: snapshot());
      expect(find.textContaining('Only hunt admins'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scanning fits', (tester) async {
      await pumpAt(tester, ArRoutes.place, data: snapshot(admin: true));
      expect(tester.takeException(), isNull);
    });

    testWidgets('idle, draft and selected panels fit', (tester) async {
      await pumpAt(tester, ArRoutes.place, data: snapshot(admin: true));
      lockOn('a');
      await settle(tester);
      expect(find.textContaining('placed'), findsWidgets);
      expect(tester.takeException(), isNull);

      // The longest message: nothing to rest on, so it floats.
      scene.emit(
        const ArSurfaceTapped(position: Vec3(1, 0, 1), onSurface: false),
      );
      await settle(tester);
      expect(find.byKey(const ValueKey('save-draft')), findsOneWidget);
      expect(find.byKey(const ValueKey('draft-size')), findsOneWidget);
      expect(find.textContaining('floating'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cancel'));
      await settle(tester);
      scene.emit(const ArItemTapped(itemId: 'a1', distance: 1));
      await settle(tester);
      expect(find.byKey(const ValueKey('remove-selected')), findsOneWidget);
      expect(find.textContaining('Clue:'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await drainTimers(tester);
    });

    testWidgets('the clue field stays usable with the keyboard up', (
      tester,
    ) async {
      await pumpAt(tester, ArRoutes.place, data: snapshot(admin: true));
      lockOn('a');
      await settle(tester);
      scene.emit(
        const ArSurfaceTapped(position: Vec3(1, 0, 1), onSurface: true),
      );
      await settle(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await settle(tester);
      expect(tester.takeException(), isNull);
      await drainTimers(tester);
    });
  });
}
