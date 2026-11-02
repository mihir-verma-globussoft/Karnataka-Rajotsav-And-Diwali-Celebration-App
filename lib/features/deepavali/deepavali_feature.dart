import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/deepavali_page.dart';

abstract final class DeepavaliRoutes {
  /// Add sub-route paths here; every path must start with `/deepavali`.
  static const String prefix = '/deepavali';
}

class DeepavaliFeature implements FeatureModule {
  const DeepavaliFeature();

  @override
  String get id => 'deepavali';

  @override
  FeatureTab? get tab => FeatureTab(
    order: 1,
    label: 'Deepavali',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome,
    builder: (context) => const DeepavaliPage(),
  );

  @override
  FeatureEntry? get entry => null;

  @override
  List<RouteBase> get routes => const [];
}
