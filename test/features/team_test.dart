import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/team/team_members.dart';

import '../helpers.dart';

void main() {
  test('exactly six developers are listed', () {
    expect(teamMembers, hasLength(6));
  });

  testWidgets('Team tab shows all six developers without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team').last);
    await tester.pumpAndSettle();

    expect(find.text('Our Team'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Lazy grid: the first rows are built; scrolling reveals the rest.
    await tester.scrollUntilVisible(find.text('Harsh Vardhan'), 200);
    expect(find.text('Harsh Vardhan'), findsOneWidget);
  });
}
