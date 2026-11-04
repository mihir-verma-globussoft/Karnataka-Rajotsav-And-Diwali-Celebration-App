import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
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

/// docs/DESIGN_SYSTEM.md: every tab and every screen must fit the smallest
/// supported phone at the largest supported text size, in light and dark
/// mode, without overflowing ("nothing goes outside the screen").
void main() {
  reduceMotionForAllTests();
  final tabs = [
    for (final m in featureModules)
      if (m.tab != null) m.tab!.label,
  ];
  // Screens reachable by a fixed path (paths with parameters are covered by
  // their module's own tests).
  final paths = [
    for (final m in featureModules)
      for (final r in m.routes.whereType<GoRoute>())
        if (r.path != '/' && !r.path.contains(':')) r.path,
  ];

  void smallestPhone(WidgetTester tester, Brightness brightness) {
    tester.view.physicalSize = AppTestScreens.smallestPhone;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = AppTextScale.max;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(overrides: [arPlatformProvider.overrideWithValue(_FakeAr())]),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    for (final tab in tabs) {
      testWidgets('tab "$tab" fits, ${brightness.name}', (tester) async {
        smallestPhone(tester, brightness);
        await pumpApp(tester);
        await tester.tap(find.byKey(ValueKey('tab-$tab')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    for (final path in paths) {
      testWidgets('screen $path fits, ${brightness.name}', (tester) async {
        smallestPhone(tester, brightness);
        await pumpApp(tester);
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .push<void>(path)
            .ignore();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
