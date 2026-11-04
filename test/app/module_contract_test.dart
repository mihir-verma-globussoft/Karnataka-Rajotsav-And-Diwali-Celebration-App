import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_availability.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_platform.dart';

import '../helpers.dart';

class _FakeAr implements ArPlatform {
  @override
  Future<ArAvailability> checkAvailability() async =>
      ArAvailability.unavailable;

  @override
  Future<ArAvailability> prepare() async => ArAvailability.unavailable;

  @override
  Future<void> openSettings() async {}
}

/// Integration contract every registered module must satisfy.
void main() {
  reduceMotionForAllTests();
  final modules = featureModules.where((m) => m.id != 'home').toList();

  test('the festival modules and Games tab are registered', () {
    expect(modules.map((m) => m.id).toSet(), {
      'ar',
      'deepavali',
      'flappy_bird',
      'games',
      'pitch_game',
      'rajyotsava',
      'team',
    });
  });

  test('bottom bar has Rajyotsava, Deepavali, Games, Team in order', () {
    final tabs = [
      for (final m in featureModules)
        if (m.tab != null) m.tab!,
    ]..sort((a, b) => a.order.compareTo(b.order));
    expect(tabs.map((t) => t.label), [
      'Rajyotsava',
      'Deepavali',
      'Games',
      'Team',
    ]);
    expect(tabs.map((t) => t.order).toSet().length, tabs.length);
  });

  for (final m in modules) {
    test('${m.id}: routes are prefixed with /${m.id}', () {
      for (final r in m.routes.whereType<GoRoute>()) {
        expect(r.path, startsWith('/${m.id}'));
      }
      if (m.entry != null) expect(m.entry!.path, startsWith('/${m.id}'));
    });
  }

  for (final m in modules.where((m) => m.tab != null)) {
    testWidgets('${m.id}: tab renders without errors', (tester) async {
      await tester.pumpWidget(testApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text(m.tab!.label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(m.tab!.label), findsWidgets);
    });
  }

  for (final m in modules.where((m) => m.entry != null)) {
    testWidgets('${m.id}: entry route opens and goes back', (tester) async {
      await tester.pumpWidget(
        testApp(overrides: [arPlatformProvider.overrideWithValue(_FakeAr())]),
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push<void>(m.entry!.path)
          .ignore();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BackButton), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsNothing);
    });
  }
}
