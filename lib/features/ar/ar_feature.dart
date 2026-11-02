import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/ar_page.dart';

abstract final class ArRoutes {
  static const String root = '/ar';
}

class ArFeature implements FeatureModule {
  const ArFeature();

  @override
  String get id => 'ar';

  @override
  FeatureTab? get tab => null;

  @override
  FeatureEntry? get entry => const FeatureEntry(
    title: 'AR Game',
    subtitle: 'Karnataka-themed augmented reality',
    icon: Icons.view_in_ar_outlined,
    path: ArRoutes.root,
    group: FeatureGroups.games,
    order: 2,
  );

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: ArRoutes.root,
      name: 'ar',
      builder: (context, state) => const ArPage(),
    ),
  ];
}
