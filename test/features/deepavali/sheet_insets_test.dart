import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/diwali_sheet.dart';

void main() {
  testWidgets('a Deepavali sheet keeps its Close button above the Android '
      'navigation buttons', (tester) async {
    const nav = 48.0;
    const size = Size(360, 640);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          padding: EdgeInsets.only(top: 24, bottom: nav),
        ),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDiwaliSheet<void>(
                context,
                builder: (_) => const Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 800,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text('Close'),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.text('Close')).dy,
      lessThanOrEqualTo(size.height - nav),
    );
  });
}
