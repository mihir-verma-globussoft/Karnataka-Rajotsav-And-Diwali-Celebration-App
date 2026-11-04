import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/deepavali_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/section_header.dart';

import 'phase2_test.dart' show FakeStore, ist;

void main() {
  const phones = [
    (name: 'tall phone', size: Size(390, 844), scale: 1.0, statusBar: 47.0),
    (
      name: '320x568 at 2x text',
      size: Size(320, 568),
      scale: 2.0,
      statusBar: 24.0,
    ),
  ];

  for (final p in phones) {
    testWidgets('Begin the celebration lands below the status bar: ${p.name}', (
      tester,
    ) async {
      tester.view.physicalSize = p.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deepavaliStoreProvider.overrideWithValue(FakeStore(seen: true)),
            deepavaliNowProvider.overrideWithValue(() => ist(3)),
          ],
          child: MediaQuery(
            data: MediaQueryData(
              size: p.size,
              padding: EdgeInsets.only(top: p.statusBar),
              disableAnimations: true,
              textScaler: TextScaler.linear(p.scale),
            ),
            child: const MaterialApp(home: DeepavaliPage()),
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Begin the celebration'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin the celebration'));
      await tester.pumpAndSettle();

      final header = find.widgetWithText(SectionHeader, 'Discover Deepavali');
      expect(
        tester.getTopLeft(header).dy,
        p.statusBar + AppSpacing.md,
        reason: 'heading must sit just under the status bar, not behind it',
      );
    });
  }
}
