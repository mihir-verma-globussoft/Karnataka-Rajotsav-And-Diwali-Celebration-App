import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart' show RouteBase;
import 'package:rajotsav_and_diwali_celebration_app/app/app.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_module.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/logging/app_logger.dart';

/// Pumps the real [App] with the given feature modules (or the registered
/// ones when omitted).
Widget testApp({
  List<FeatureModule>? modules,
  List<Override> overrides = const [],
}) => ProviderScope(
  overrides: [
    featureModulesProvider.overrideWithValue(modules ?? featureModules),
    ...overrides,
  ],
  child: const App(),
);

/// Minimal [FeatureModule] fake for navigation tests.
class FakeFeature implements FeatureModule {
  const FakeFeature(this.id, this.routes);
  @override
  final String id;
  @override
  FeatureEntry? get entry => null;
  @override
  final List<RouteBase> routes;
}

/// Captures error messages instead of emitting them.
class RecordingLogger extends AppLogger {
  RecordingLogger();
  final List<String> errors = [];
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      errors.add(message);
}
