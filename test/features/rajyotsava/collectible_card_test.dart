import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/haptics/app_haptics.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/easter_egg_collectibles.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/easter_eggs.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/collectible_card.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/collectible_reveal.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/rajyotsava_widgets.dart';

/// Records which haptics were played.
class RecordingHaptics implements AppHaptics {
  final List<String> played = [];
  @override
  Future<void> tap() async => played.add('tap');
  @override
  Future<void> selection() async => played.add('selection');
  @override
  Future<void> success() async => played.add('success');
  @override
  Future<void> warning() async => played.add('warning');
  @override
  Future<void> error() async => played.add('error');
  @override
  Future<void> heavy() async => played.add('heavy');
}

final _rajkumar = karnatakaCollectibles.firstWhere((c) => c.id == 'rajkumar');

Future<RecordingHaptics> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 900),
  double text = 1,
  bool reduce = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  if (reduce) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final haptics = RecordingHaptics();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hapticsProvider.overrideWithValue(haptics)],
      child: MaterialApp(
        home: RajyotsavaTheme(
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return haptics;
}

void main() {
  testWidgets('front shows title, Kannada title and rarity', (tester) async {
    await _pump(tester, CollectibleCard(collectible: _rajkumar, photo: null));
    expect(find.text('Dr. Rajkumar'), findsOneWidget);
    expect(find.text('ಡಾ. ರಾಜ್‌ಕುಮಾರ್'), findsOneWidget);
    expect(find.text('Legendary'), findsOneWidget);
    expect(find.text('History'), findsNothing);
  });

  testWidgets('tap flips to the back with a haptic, and back again', (
    tester,
  ) async {
    final haptics = await _pump(
      tester,
      CollectibleCard(collectible: _rajkumar, photo: null),
    );
    await tester.tap(find.byType(CollectibleCard));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(find.text(_rajkumar.kannadaDescription), findsOneWidget);
    expect(haptics.played, ['selection']);

    await tester.tap(find.byType(CollectibleCard));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsNothing);
  });

  testWidgets('with reduced motion the flip happens at once', (tester) async {
    await _pump(
      tester,
      CollectibleCard(collectible: _rajkumar, photo: null),
      reduce: true,
    );
    await tester.tap(find.byType(CollectibleCard));
    await tester.pump();
    await tester.pump(AppDurations.medium);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('dragging tilts the card, which springs back', (tester) async {
    await _pump(tester, CollectibleCard(collectible: _rajkumar, photo: null));
    Matrix4 cardTransform() => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(CollectibleCard),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform;
    final flat = cardTransform().clone();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CollectibleCard)),
    );
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(12, -8));
      await tester.pump();
    }
    expect(cardTransform(), isNot(flat));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(cardTransform(), flat);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every collectible fits a small phone at 2x text', (
    tester,
  ) async {
    for (final c in karnatakaCollectibles) {
      await _pump(
        tester,
        CollectibleCard(collectible: c, photo: null, width: 280),
        size: AppTestScreens.smallestPhone,
        text: 2,
      );
      await tester.tap(find.byType(CollectibleCard));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: c.id);
    }
  });

  group('reveal', () {
    Future<void> open(WidgetTester tester, Reveal reveal) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showCollectibleReveal(
              context,
              reveal: reveal,
              total: karnatakaCollectibles.length,
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('announces the secret and closes', (tester) async {
      await open(tester, NewCollectible(_rajkumar));
      expect(find.text('ನಿಮಗೆ ಕರ್ನಾಟಕದ ಒಂದು ರಹಸ್ಯ ಸಿಕ್ಕಿದೆ!'), findsOneWidget);
      expect(find.text('You discovered a Karnataka secret!'), findsOneWidget);
      expect(find.byType(CollectibleCard), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('collectible-close')));
      await tester.pumpAndSettle();
      expect(find.byType(CollectibleCard), findsNothing);
    });

    testWidgets('shows the completion card when all are found', (tester) async {
      await open(tester, const CollectionComplete());
      expect(find.text('Karnataka Treasure Hunter'), findsOneWidget);
      expect(find.textContaining('all 22'), findsOneWidget);
    });
  });
}
