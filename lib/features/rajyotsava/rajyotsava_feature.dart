import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/rajyotsava_page.dart';

abstract final class RajyotsavaRoutes {
  /// Add sub-route paths here; every path must start with `/rajyotsava`.
  static const String prefix = '/rajyotsava';
}

class RajyotsavaFeature implements FeatureModule {
  const RajyotsavaFeature();

  @override
  String get id => 'rajyotsava';

  @override
  FeatureTab? get tab => FeatureTab(
    order: 0,
    label: 'Rajyotsava',
    icon: Icons.temple_hindu_outlined,
    selectedIcon: Icons.temple_hindu,
    builder: (context) => const RajyotsavaPage(),
  );

  @override
  FeatureEntry? get entry => null;

  @override
  List<RouteBase> get routes => const [];
}
