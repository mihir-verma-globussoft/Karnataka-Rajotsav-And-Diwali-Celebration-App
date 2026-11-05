import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/app.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_module.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/config/app_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts and shows the home screen', (tester) async {
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
    await tester.pumpAndSettle();
    expect(find.text('Games'), findsOneWidget);
  });
}
