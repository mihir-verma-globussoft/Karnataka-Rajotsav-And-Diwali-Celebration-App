import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/app.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_module.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';

/// Frame-timing check. Run in profile mode on a real device:
///   flutter drive --driver=test_driver/perf_driver.dart \
///     --target=integration_test/perf_test.dart --profile -d DEVICE_ID
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tab switching and navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [featureModulesProvider.overrideWithValue(featureModules)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    await binding.traceAction(() async {
      for (var round = 0; round < 3; round++) {
        for (final tab in ['Deepavali', 'Games', 'Team', 'Rajyotsava']) {
          await tester.tap(find.byKey(ValueKey('tab-$tab')));
          await tester.pumpAndSettle();
        }
      }
      await tester.tap(find.byKey(const ValueKey('tab-Games')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Flappy Bird'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    }, reportKey: 'tab_switching');
  });
}
