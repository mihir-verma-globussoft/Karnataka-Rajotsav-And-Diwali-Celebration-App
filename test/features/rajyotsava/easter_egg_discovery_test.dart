import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/easter_egg_collectibles.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/shake.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/collectible_card.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/rajyotsava_motion.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_providers.dart';

import '../../helpers.dart';
import 'collectible_card_test.dart' show RecordingHaptics;
import 'easter_eggs_test.dart' show MemoryEggStore;

/// A shake source the test can fire, counting active sensor listeners.
class FakeShakes implements ShakeSource {
  final _controller = StreamController<void>.broadcast();
  var listeners = 0;

  void shake() => _controller.add(null);

  @override
  Stream<void> shakes() {
    late StreamController<void> c;
    StreamSubscription<void>? sub;
    c = StreamController<void>(
      onListen: () {
        listeners++;
        sub = _controller.stream.listen(c.add);
      },
      onCancel: () async {
        listeners--;
        await sub?.cancel();
        await c.close();
      },
    );
    return c.stream;
  }
}

class _Env {
  _Env(this.shakes, this.store, this.haptics);
  final FakeShakes shakes;
  final MemoryEggStore store;
  final RecordingHaptics haptics;
}

Future<_Env> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final env = _Env(FakeShakes(), MemoryEggStore(), RecordingHaptics());
  await tester.pumpWidget(
    testApp(
      overrides: [
        shakeSourceProvider.overrideWithValue(env.shakes),
        easterEggStoreProvider.overrideWithValue(env.store),
        easterEggRandomProvider.overrideWithValue(Random(4)),
        hapticsProvider.overrideWithValue(env.haptics),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Future<void> _close(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('collectible-close')));
  await tester.pumpAndSettle();
}

String _shownTitle(WidgetTester tester) =>
    tester.widget<CollectibleCard>(find.byType(CollectibleCard)).collectible.id;

void main() {
  testWidgets('a shake on the tab reveals and saves a new collectible', (
    tester,
  ) async {
    final env = await _pump(tester);
    expect(env.shakes.listeners, 1, reason: 'sensor on while tab is shown');

    env.shakes.shake();
    await tester.pumpAndSettle();
    expect(find.text('ನಿಮಗೆ ಕರ್ನಾಟಕದ ಒಂದು ರಹಸ್ಯ ಸಿಕ್ಕಿದೆ!'), findsOneWidget);
    final first = _shownTitle(tester);
    expect(env.store.saved.keys, [first]);
    expect(env.haptics.played, ['heavy', 'success']);
    await _close(tester);

    env.shakes.shake();
    await tester.pumpAndSettle();
    expect(_shownTitle(tester), isNot(first));
    expect(env.store.saved, hasLength(2));
  });

  testWidgets('a burst of shakes opens only one reveal', (tester) async {
    final env = await _pump(tester);
    env.shakes
      ..shake()
      ..shake()
      ..shake();
    await tester.pumpAndSettle();
    expect(find.byType(CollectibleCard), findsOneWidget);
    expect(env.store.saved, hasLength(1));
  });

  testWidgets('shakes are ignored while the keyboard is open', (tester) async {
    final env = await _pump(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    env.shakes.shake();
    await tester.pumpAndSettle();
    expect(find.byType(CollectibleCard), findsNothing);
    expect(env.store.saved, isEmpty);
  });

  testWidgets('the sensor stops on other tabs and moves to sub-screens', (
    tester,
  ) async {
    final env = await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Games')));
    await tester.pumpAndSettle();
    expect(env.shakes.listeners, 0, reason: 'off on another tab');
    env.shakes.shake();
    await tester.pumpAndSettle();
    expect(find.byType(CollectibleCard), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tab-Rajyotsava')));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push<void>(RajyotsavaRoutes.learn)
        .ignore();
    await tester.pumpAndSettle();
    expect(env.shakes.listeners, 1, reason: 'only the visible screen');
    env.shakes.shake();
    await tester.pumpAndSettle();
    expect(find.byType(CollectibleCard), findsOneWidget);
  });

  testWidgets('after all 22, a shake shows the completion card', (
    tester,
  ) async {
    final env = await _pump(tester);
    for (var i = 0; i < karnatakaCollectibles.length; i++) {
      env.shakes.shake();
      await tester.pumpAndSettle();
      await _close(tester);
    }
    expect(env.store.saved, hasLength(22));
    env.shakes.shake();
    await tester.pumpAndSettle();
    expect(find.text('Karnataka Treasure Hunter'), findsOneWidget);
  });

  group('hidden taps', () {
    Future<void> tapTimes(WidgetTester tester, Finder target, int n) async {
      for (var i = 0; i < n; i++) {
        await tester.tap(target, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
    }

    testWidgets('4 taps on the flag reveal nothing', (tester) async {
      final env = await _pump(tester);
      await tapTimes(tester, find.byType(WavingFlag), 4);
      expect(find.byType(CollectibleCard), findsNothing);
      expect(env.store.saved, isEmpty);
    });

    testWidgets('tapping the flag 5 times reveals a collectible', (
      tester,
    ) async {
      final env = await _pump(tester);
      await tapTimes(tester, find.byType(WavingFlag), 5);
      expect(find.byType(CollectibleCard), findsOneWidget);
      expect(env.store.saved, hasLength(1));
    });

    testWidgets('taps and shakes share the no-repeat rule', (tester) async {
      final env = await _pump(tester);
      await tapTimes(tester, find.byType(WavingFlag), 5);
      final first = _shownTitle(tester);
      await _close(tester);
      env.shakes.shake();
      await tester.pumpAndSettle();
      expect(_shownTitle(tester), isNot(first));
      expect(env.store.saved, hasLength(2));
    });

    testWidgets("Dr. Rajkumar's photo on Kannada Cinema", (tester) async {
      final env = await _pump(tester);
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push<void>(RajyotsavaRoutes.cinema)
          .ignore();
      await tester.pumpAndSettle();
      await tapTimes(tester, find.bySemanticsLabel('Photo of Dr. Rajkumar'), 5);
      expect(find.byType(CollectibleCard), findsOneWidget);
      expect(env.store.saved, hasLength(1));
    });

    testWidgets('long-pressing the Songs & Folk Arts title', (tester) async {
      final env = await _pump(tester);
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push<void>(RajyotsavaRoutes.culture)
          .ignore();
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Songs & Folk Arts'));
      await tester.pumpAndSettle();
      expect(find.byType(CollectibleCard), findsOneWidget);
      expect(env.store.saved, hasLength(1));
    });
  });
}
