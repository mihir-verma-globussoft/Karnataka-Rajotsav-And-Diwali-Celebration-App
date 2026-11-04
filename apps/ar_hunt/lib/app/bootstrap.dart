import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../features/ar/ar_providers.dart';
import 'app.dart';
import 'auth/hunt_auth.dart';
import 'demo/demo_hunt.dart';
import 'feature_module.dart';
import 'feature_registry.dart';
import 'providers.dart';

/// Routes uncaught framework and platform errors to [logger].
void installErrorHandlers(AppLogger logger) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    previous?.call(details);
    logger.error(details.exceptionAsString(), details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Uncaught platform error', error, stack);
    return true;
  };
}

/// Restores the saved session before the first screen, so a signed-in player
/// never sees the sign-in page flash by.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp])
        .catchError((Object _) {}),
  );
  const logger = AppLogger();
  installErrorHandlers(logger);
  final config = AppConfig.fromEnvironment();
  if (config.hasSupabase && !huntDemoMode) {
    try {
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabaseAnonKey,
      );
    } catch (error, stackTrace) {
      logger.error('Supabase initialization failed', error, stackTrace);
    }
  }
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        featureModulesProvider.overrideWithValue(featureModules),
        if (huntDemoMode) ...[
          huntRepositoryProvider.overrideWithValue(DemoHuntRepository()),
          huntSessionProvider.overrideWith(
            (ref) => Stream.value(huntDemoSession),
          ),
        ],
      ],
      child: const App(),
    ),
  );
}
