import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/app.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_module.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/config/app_config.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/collectible_card.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/rajyotsava_motion.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_feature.dart';

/// Frame timings for the Rajyotsava section: the tab with its fireworks,
/// scrolling, sub-screens, the easter egg reveal (tilt, flip, close) and
/// the collection. Run in profile mode on a real phone:
///   flutter drive --no-dds --driver=test_driver/perf_driver.dart \
///     --target=integration_test/rajyotsava_perf_test.dart --profile -d DEVICE
/// Summaries go to build/perf/raj_*.timeline_summary.json.
///
/// The tab animates all the time, so fixed frame pumps are used instead of
/// pumpAndSettle. Note: the reveal is found through the flag's secret tap,
/// so a run saves one found card on the phone.
Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rajyotsava: tab, screens, reveal and collection', (
    tester,
  ) async {
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
    await _frames(tester, 90);

    await binding.traceAction(() async {
      await _frames(tester, 180);
    }, reportKey: 'raj_idle');

    final scrollable = find.byType(Scrollable).first;
    GoRouter router() =>
        GoRouter.of(tester.element(find.byType(Scaffold).first));
    await binding.traceAction(() async {
      for (var i = 0; i < 14; i++) {
        await tester.drag(scrollable, const Offset(0, -500));
        await _frames(tester, 12);
      }
      for (var i = 0; i < 14; i++) {
        await tester.drag(scrollable, const Offset(0, 500));
        await _frames(tester, 12);
      }
    }, reportKey: 'raj_scroll');

    await binding.traceAction(() async {
      for (final path in [
        RajyotsavaRoutes.discover,
        RajyotsavaRoutes.cinema,
        RajyotsavaRoutes.learn,
      ]) {
        router().push<void>(path).ignore();
        await _frames(tester, 50);
        final inner = find.byType(Scrollable).last;
        for (var i = 0; i < 6; i++) {
          await tester.drag(inner, const Offset(0, -500), warnIfMissed: false);
          await _frames(tester, 10);
        }
        router().pop();
        await _frames(tester, 40);
      }
    }, reportKey: 'raj_screens');

    await tester.scrollUntilVisible(
      find.byType(WavingFlag).first,
      -300,
      scrollable: scrollable,
    );
    await _frames(tester, 20);
    await binding.traceAction(() async {
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byType(WavingFlag).first, warnIfMissed: false);
        await _frames(tester, 4);
      }
      await _frames(tester, 60);
      final card = find.byType(CollectibleCard);
      final g = await tester.startGesture(tester.getCenter(card));
      for (var i = 0; i < 30; i++) {
        await g.moveBy(Offset(i < 15 ? 6 : -6, 4));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _frames(tester, 30);
      await tester.tap(card);
      await _frames(tester, 40);
      await tester.tap(find.byKey(const ValueKey('collectible-close')));
      await _frames(tester, 30);
    }, reportKey: 'raj_reveal');

    router().push<void>(RajyotsavaRoutes.collection).ignore();
    await _frames(tester, 40);
    await binding.traceAction(() async {
      final inner = find.byType(Scrollable).last;
      for (var i = 0; i < 8; i++) {
        await tester.drag(inner, const Offset(0, -500));
        await _frames(tester, 10);
      }
      for (var i = 0; i < 8; i++) {
        await tester.drag(inner, const Offset(0, 500));
        await _frames(tester, 10);
      }
    }, reportKey: 'raj_collection');
  });
}
