import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/easter_egg_collectibles.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/easter_eggs.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/collectible_card.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_providers.dart';

import '../../helpers.dart';
import 'easter_egg_discovery_test.dart' show FakeShakes;
import 'easter_eggs_test.dart' show MemoryEggStore;

Discovery _found() => Discovery(discoveredAt: DateTime(2026, 11, 4), count: 1);

Future<MemoryEggStore> _open(
  WidgetTester tester, {
  Iterable<String> found = const [],
  Size size = const Size(400, 900),
  double text = 1,
  FakeShakes? shakes,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final store = MemoryEggStore()
    ..saved = {for (final id in found) id: _found()};
  await tester.pumpWidget(
    testApp(
      overrides: [
        easterEggStoreProvider.overrideWithValue(store),
        shakeSourceProvider.overrideWithValue(shakes ?? FakeShakes()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first))
      .push<void>(RajyotsavaRoutes.collection)
      .ignore();
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('shows progress, found cards and locked silhouettes', (
    tester,
  ) async {
    await _open(tester, found: ['rajkumar', 'hampi']);
    expect(find.text('2 / 22 found'), findsOneWidget);
    expect(find.text('Dr. Rajkumar'), findsOneWidget);
    expect(find.text('Hampi'), findsOneWidget);
    expect(find.text('Jog Falls'), findsNothing, reason: 'locked stays secret');
    expect(find.byIcon(Icons.lock), findsNWidgets(20));
  });

  testWidgets('category filters show only that category', (tester) async {
    await _open(tester, found: ['rajkumar', 'hampi']);
    await tester.tap(find.byKey(const ValueKey('collection-filter-place')));
    await tester.pumpAndSettle();
    final places = karnatakaCollectibles
        .where((c) => c.category == EggCategory.place)
        .length;
    expect(find.text('Hampi'), findsOneWidget);
    expect(find.text('Dr. Rajkumar'), findsNothing);
    expect(find.byIcon(Icons.lock), findsNWidgets(places - 1));

    await tester.tap(find.byKey(const ValueKey('collection-filter-all')));
    await tester.pumpAndSettle();
    expect(find.text('Dr. Rajkumar'), findsOneWidget);
  });

  testWidgets('a found card opens again as the 3D card, not as new', (
    tester,
  ) async {
    final store = await _open(tester, found: ['rajkumar']);
    await tester.tap(find.text('Dr. Rajkumar'));
    await tester.pumpAndSettle();
    expect(find.byType(CollectibleCard), findsOneWidget);
    expect(find.text('From your collection'), findsOneWidget);
    expect(find.text('You discovered a Karnataka secret!'), findsNothing);
    expect(store.saves, 0, reason: 'reopening does not discover');
  });

  testWidgets('a shake on the collection updates it straight away', (
    tester,
  ) async {
    // The reveal and the grid share the manager, so a new find shows up.
    final shakes = FakeShakes();
    await _open(tester, shakes: shakes);
    expect(find.text('0 / 22 found'), findsOneWidget);
    shakes.shake();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collectible-close')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 22 found'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(21));
  });

  testWidgets('everything found fits a small phone at 2x text', (tester) async {
    await _open(
      tester,
      found: [for (final c in karnatakaCollectibles) c.id],
      size: AppTestScreens.smallestPhone,
      text: AppTextScale.max,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('22 / 22 found'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Need a hint?" shows one hint at a time and moves on', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('collection-hint')));
    await tester.pumpAndSettle();
    expect(find.text('Hint 1 of 8'), findsOneWidget);
    expect(find.text('ಅಲ್ಲಾಡಿಸಿ!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hint-next')));
    await tester.pumpAndSettle();
    expect(find.text('Hint 2 of 8'), findsOneWidget);
    expect(find.text('ನಮ್ಮ ಬಾವುಟ'), findsOneWidget);
    expect(find.text('ಅಲ್ಲಾಡಿಸಿ!'), findsNothing);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    // Opening it again goes on to a new hint.
    await tester.tap(find.byKey(const ValueKey('collection-hint')));
    await tester.pumpAndSettle();
    expect(find.text('Hint 2 of 8'), findsOneWidget);
  });

  testWidgets('the hint sheet fits a small phone at 2x text', (tester) async {
    await _open(
      tester,
      size: AppTestScreens.smallestPhone,
      text: AppTextScale.max,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('collection-hint')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('collection-hint')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 8; i++) {
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('hint-next')));
      await tester.tap(find.byKey(const ValueKey('hint-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Hint 1 of 8'), findsOneWidget, reason: 'wraps round');
  });

  testWidgets('no hint button once everything is found', (tester) async {
    await _open(tester, found: [for (final c in karnatakaCollectibles) c.id]);
    expect(find.byKey(const ValueKey('collection-hint')), findsNothing);
  });
}
