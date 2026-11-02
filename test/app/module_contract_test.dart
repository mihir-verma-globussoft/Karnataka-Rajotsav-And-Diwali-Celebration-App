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
}

/// Integration contract every registered module must satisfy.
void main() {
  final modules = featureModules.where((m) => m.id != 'home').toList();

  test('the five festival modules are registered', () {
    expect(modules.map((m) => m.id).toSet(), {
      'ar',
      'deepavali',
      'flappy_bird',
      'pitch_game',
      'rajyotsava',
    });
  });

  for (final m in modules) {
    test('${m.id}: routes are prefixed with /${m.id} and have an entry', () {
      expect(m.entry, isNotNull);
      expect(m.entry!.path, startsWith('/${m.id}'));
      for (final r in m.routes.whereType<GoRoute>()) {
        expect(r.path, startsWith('/${m.id}'));
      }
    });

    testWidgets('${m.id}: opens from home and goes back', (tester) async {
      // Modules with native/async dependencies are faked here.
      await tester.pumpWidget(
        testApp(overrides: [arPlatformProvider.overrideWithValue(_FakeAr())]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(m.entry!.title));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(m.entry!.title), findsOneWidget);
    });
  }
}
