import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/app_logger.dart';
import 'app.dart';
import 'feature_module.dart';
import 'feature_registry.dart';

/// Routes uncaught framework and platform errors to [logger].
/// Swap the body for a crash reporter when one is adopted (see DECISIONS.md).
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

/// Logs provider failures that would otherwise be silent.
base class ErrorLoggingObserver extends ProviderObserver {
  const ErrorLoggingObserver(this._logger);

  final AppLogger _logger;

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) => _logger.error(
    'Provider failed: ${context.provider.name ?? context.provider.runtimeType}',
    error,
    stackTrace,
  );
}

/// Synchronous, minimal startup: nothing here may delay the first frame.
/// Defer nonessential work to providers that load after `runApp`.
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  const logger = AppLogger();
  installErrorHandlers(logger);
  runApp(
    ProviderScope(
      overrides: [featureModulesProvider.overrideWithValue(featureModules)],
      observers: const [if (!kReleaseMode) ErrorLoggingObserver(logger)],
      child: const App(),
    ),
  );
}
