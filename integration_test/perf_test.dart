import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/material.dart' show Scrollable;
import 'package:flutter/widgets.dart' show SingleChildScrollView;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/app.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_module.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/config/app_config.dart';

/// Frame-timing check. Run in profile mode on a real device:
///   flutter drive --no-dds --driver=test_driver/perf_driver.dart \
///     --target=integration_test/perf_test.dart --profile -d DEVICE_ID
///
/// The Deepavali tab animates all the time while it is on screen, so
/// `pumpAndSettle` never returns there. [_frames] pumps a fixed number of
/// frames instead.
Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _openApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        featureModulesProvider.overrideWithValue(featureModules),
        // No credentials: the access gate opens straight to the app shell.
        appConfigProvider.overrideWithValue(
          const AppConfig(environment: AppEnvironment.dev),
        ),
      ],
      child: const App(),
    ),
  );
  await _frames(tester, 60);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tab switching and navigation', (tester) async {
    await _openApp(tester);

    await binding.traceAction(() async {
      for (var round = 0; round < 3; round++) {
        for (final tab in ['Deepavali', 'Games', 'Team', 'Rajyotsava']) {
          await tester.tap(find.byKey(ValueKey('tab-$tab')));
          await _frames(tester, 40);
        }
      }
      await tester.tap(find.byKey(const ValueKey('tab-Games')));
      await _frames(tester, 40);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Flappy Bird'));
        await _frames(tester, 40);
        await tester.pageBack();
        await _frames(tester, 40);
      }
    }, reportKey: 'tab_switching');
  });

  testWidgets('deepavali tab: scroll, play and open screens', (tester) async {
    await _openApp(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Deepavali')));
    await _frames(tester, 60);

    final page = find.byType(SingleChildScrollView).first;
    final scrollable = find.byType(Scrollable).first;

    // Each flow is traced on its own, so a slow frame can be traced back to
    // what caused it.
    await binding.traceAction(() async {
      // Top to bottom and back, a screenful at a time.
      for (var i = 0; i < 24; i++) {
        await tester.drag(page, const Offset(0, -500));
        await _frames(tester, 12);
      }
      for (var i = 0; i < 24; i++) {
        await tester.drag(page, const Offset(0, 500));
        await _frames(tester, 12);
      }
    }, reportKey: 'deepavali_scroll');

    await tester.scrollUntilVisible(
      find.text('Start'),
      300,
      scrollable: scrollable,
    );
    await _frames(tester, 20);
    await binding.traceAction(() async {
      // The diya game running, with the wind blowing.
      await tester.tap(find.text('Start'));
      await _frames(tester, 120);
      await tester.tap(find.text('Pause'));
      await _frames(tester, 20);
    }, reportKey: 'deepavali_game');

    await tester.scrollUntilVisible(
      find.text('Start decorating'),
      300,
      scrollable: scrollable,
    );
    await _frames(tester, 20);
    await binding.traceAction(() async {
      // A full-screen feature and back.
      await tester.tap(find.text('Start decorating'));
      await _frames(tester, 40);
      for (final label in ['Diya', 'Lantern', 'Garland', 'Rangoli']) {
        await tester.tap(find.text(label));
        await _frames(tester, 10);
      }
      await tester.pageBack();
      await _frames(tester, 40);
    }, reportKey: 'deepavali_decorate');

    await binding.traceAction(() async {
      // Leave and come back, as people do.
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('tab-Games')));
        await _frames(tester, 40);
        await tester.tap(find.byKey(const ValueKey('tab-Deepavali')));
        await _frames(tester, 40);
      }
    }, reportKey: 'deepavali_tabs');
  });
}
