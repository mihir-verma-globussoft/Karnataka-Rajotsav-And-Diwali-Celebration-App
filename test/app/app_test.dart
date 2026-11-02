import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/bootstrap.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_module.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/router/app_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_theme.dart';

import '../helpers.dart';

void main() {
  testWidgets('app launches on the home route', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    expect(find.text('Games'), findsOneWidget);
  });

  testWidgets('registered features contribute routes', (tester) async {
    await tester.pumpWidget(
      testApp(
        modules: [
          FakeFeature('x', [
            GoRoute(path: '/', builder: (_, _) => const Text('fake home')),
            GoRoute(path: '/x', builder: (_, _) => const Text('fake x')),
          ]),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('fake home'), findsOneWidget);

    final ctx = tester.element(find.text('fake home'));
    unawaited(GoRouter.of(ctx).push<void>('/x'));
    await tester.pumpAndSettle();
    expect(find.text('fake x'), findsOneWidget);

    GoRouter.of(ctx).pop();
    await tester.pumpAndSettle();
    expect(find.text('fake home'), findsOneWidget);
  });

  testWidgets('invalid route shows the error page and can recover', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go('/does-not-exist');
    await tester.pumpAndSettle();
    expect(find.byType(RouteErrorPage), findsOneWidget);

    await tester.tap(find.text('Go home'));
    await tester.pumpAndSettle();
    expect(find.text('Games'), findsOneWidget);
  });

  testWidgets('theme mode provider drives MaterialApp', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(themeModeProvider.notifier)
        .set(ThemeMode.dark);
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  test('feature ids and route paths are unique', () {
    final ids = featureModules.map((m) => m.id).toList();
    expect(ids.toSet().length, ids.length);
    final paths = [
      for (final m in featureModules)
        for (final r in m.routes)
          if (r is GoRoute) r.path,
    ];
    expect(paths.toSet().length, paths.length);
  });

  test('providers resolve with defaults and accept overrides', () {
    final container = ProviderContainer(
      overrides: [featureModulesProvider.overrideWithValue(featureModules)],
    );
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(container.read(routerProvider), isA<GoRouter>());
  });

  test('themes are Material 3 with matching brightness', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.useMaterial3, isTrue);
  });

  test('installErrorHandlers logs framework errors', () {
    final original = FlutterError.onError;
    addTearDown(() => FlutterError.onError = original);
    final logger = RecordingLogger();
    FlutterError.onError = (_) {};
    installErrorHandlers(logger);
    FlutterError.onError!(FlutterErrorDetails(exception: StateError('boom')));
    expect(logger.errors.single, contains('boom'));
  });
}
