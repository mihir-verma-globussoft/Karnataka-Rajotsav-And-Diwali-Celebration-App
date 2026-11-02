import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Known values for [FeatureEntry.group]; a group tab lists its entries.
abstract final class FeatureGroups {
  static const String games = 'games';
}

/// A top-level tab in the bottom navigation bar. Its content is shown inside
/// the home shell, so it is not a route.
class FeatureTab {
  const FeatureTab({
    required this.order,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  /// Position in the bar (ascending).
  final int order;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// A launchable tile shown inside a group tab (e.g. the Games tab).
class FeatureEntry {
  const FeatureEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.path,
    this.group,
    this.order = 0,
  });

  /// Which tab lists this entry (see [FeatureGroups]); null = not listed.
  final String? group;

  /// Position within the group (ascending).
  final int order;

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

  /// Bottom-bar tab this feature provides, or null.
  FeatureTab? get tab;

  /// Tile listed inside a group tab, or null.
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
