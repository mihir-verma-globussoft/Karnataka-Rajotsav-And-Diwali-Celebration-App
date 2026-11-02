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
  FeatureEntry? get entry => const FeatureEntry(
    title: 'Karnataka AR',
    subtitle: 'Augmented reality experience',
    icon: Icons.view_in_ar_outlined,
    path: ArRoutes.root,
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
