import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/deepavali_page.dart';

abstract final class DeepavaliRoutes {
  static const String root = '/deepavali';
}

class DeepavaliFeature implements FeatureModule {
  const DeepavaliFeature();

  @override
  String get id => 'deepavali';

  @override
  FeatureEntry? get entry => const FeatureEntry(
    title: 'Deepavali',
    subtitle: 'Diyas, rangoli, photo frames and wishes',
    icon: Icons.light_outlined,
    path: DeepavaliRoutes.root,
  );

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: DeepavaliRoutes.root,
      name: 'deepavali',
      builder: (context, state) => const DeepavaliPage(),
    ),
  ];
}
