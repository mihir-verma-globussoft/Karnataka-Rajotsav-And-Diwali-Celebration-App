import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// How a feature appears as a tile on the home screen.
class FeatureEntry {
  const FeatureEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.path,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Location opened when the tile is tapped (the feature's own route).
  final String path;
}

/// Contract every feature implements to plug into the app.
///
/// A feature exposes only its routes and optional home tile. Its providers are
/// ordinary top-level Riverpod providers living inside the feature's own
/// directory, so no central dependency registration is needed.
abstract interface class FeatureModule {
  /// Stable identifier; equals the feature's directory name.
  String get id;

  /// Home-screen tile, or null when the feature is not launched from home.
  FeatureEntry? get entry;

  /// Top-level routes owned by this feature. Paths must start with `/<id>`
  /// (except the home shell) to avoid collisions.
  List<RouteBase> get routes;
}

/// Registered features. Overridden in `bootstrap` with the registry and in
/// tests with fakes; kept here so features can read it without importing the
/// registry (which would create an import cycle).
final featureModulesProvider = Provider<List<FeatureModule>>(
  (ref) =>
      throw UnimplementedError('featureModulesProvider must be overridden'),
);
