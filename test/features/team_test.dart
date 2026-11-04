import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/team/team_members.dart';

import '../helpers.dart';

void main() {
  test('exactly seven developers are listed', () {
    expect(teamMembers, hasLength(7));
  });

  testWidgets('Team tab shows all seven developers without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team').last);
    await tester.pumpAndSettle();

    expect(find.text('Meet the team'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Lazy grid: the first rows are built; scrolling reveals the rest.
    await tester.scrollUntilVisible(find.text('Harsh Vardhan'), 200);
    expect(find.text('Harsh Vardhan'), findsOneWidget);
  });

  testWidgets('opening a member plays fireworks and a tap adds a burst', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mihir Verma'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tapAt(const Offset(160, 300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('1 of 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The show is finite: it settles once the sparks fade.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });
}
