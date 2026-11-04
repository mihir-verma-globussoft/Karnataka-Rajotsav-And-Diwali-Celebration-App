import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';

Future<double> _clearance(
  WidgetTester tester, {
  double nav = 0,
  double text = 1,
}) async {
  late double value;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        padding: EdgeInsets.only(bottom: nav),
        textScaler: TextScaler.linear(text),
      ),
      child: Builder(
        builder: (context) {
          value = AppSizes.floatingBarClearanceOf(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return value;
}

void main() {
  testWidgets('floating bar clearance adds the Android nav area', (
    tester,
  ) async {
    final none = await _clearance(tester);
    final buttons = await _clearance(tester, nav: 48);
    expect(none, AppSizes.floatingBarClearance);
    expect(buttons, none + 48);
  });

  testWidgets('floating bar clearance grows with large text', (tester) async {
    expect(
      await _clearance(tester, text: 2),
      greaterThan(await _clearance(tester, text: 1)),
    );
  });
}
