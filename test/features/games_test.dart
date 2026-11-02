import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_availability.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_platform.dart';

import '../helpers.dart';

class _FakeAr implements ArPlatform {
  @override
  Future<ArAvailability> checkAvailability() async =>
      ArAvailability.unavailable;
}

void main() {
  const games = ['Flappy Bird', 'High Pitch Game', 'AR Game'];

  Future<void> openGames(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(overrides: [arPlatformProvider.overrideWithValue(_FakeAr())]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Games').last);
    await tester.pumpAndSettle();
  }

  testWidgets('Games tab lists the three games in order, stacked', (
    tester,
  ) async {
    await openGames(tester);
    final tops = [for (final g in games) tester.getTopLeft(find.text(g)).dy];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(tops.toSet().length, 3);
    expect(tester.takeException(), isNull);
  });

  for (final g in games) {
    testWidgets('tapping "$g" opens its module and back returns', (
      tester,
    ) async {
      await openGames(tester);
      await tester.tap(find.text(g));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(g), findsOneWidget);
    });
  }
}
