import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/widgets/state_views.dart';
import '../../features/ar/ar_feature.dart';
import '../feature_module.dart';

/// Central router. Routes come only from registered [FeatureModule]s.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ArRoutes.root,
    routes: [for (final m in ref.watch(featureModulesProvider)) ...m.routes],
    errorBuilder: (context, state) => RouteErrorPage(error: state.error),
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Shown for unknown routes and navigation errors.
class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({this.error, super.key});

  final Object? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: SafeArea(
      child: ErrorView(
        error: error is AppFailure
            ? error!
            : const NotFoundFailure('This page does not exist.'),
        onRetry: () => GoRouter.of(context).go(ArRoutes.root),
        retryLabel: 'Go home',
      ),
    ),
  );
}
