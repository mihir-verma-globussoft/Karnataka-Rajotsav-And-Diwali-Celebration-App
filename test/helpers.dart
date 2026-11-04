import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart' show RouteBase;
import 'package:rajotsav_and_diwali_celebration_app/app/app.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_module.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/logging/app_logger.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_providers.dart';

/// Pumps the real [App] with the given feature modules (or the registered
/// ones when omitted).
///
/// The Rajyotsava tab's confetti and fireworks normally keep going while it
/// is on screen; here they stop after [AppDurations.ambient] so
/// `pumpAndSettle` can finish.
Widget testApp({
  List<FeatureModule>? modules,
  List<Override> overrides = const [],
}) => ProviderScope(
  overrides: [
    featureModulesProvider.overrideWithValue(modules ?? featureModules),
    rajyotsavaAmbientDurationProvider.overrideWithValue(AppDurations.ambient),
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
  FeatureTab? get tab => null;
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

/// Animated modules (Deepavali) never "settle", so tests that call
/// `pumpAndSettle` ask the platform for reduced motion, which those modules
/// honour by showing a still scene. Call once at the top of `main()`.
void reduceMotionForAllTests() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });
}
