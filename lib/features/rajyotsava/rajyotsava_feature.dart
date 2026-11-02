import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/rajyotsava_page.dart';

abstract final class RajyotsavaRoutes {
  static const String root = '/rajyotsava';
}

class RajyotsavaFeature implements FeatureModule {
  const RajyotsavaFeature();

  @override
  String get id => 'rajyotsava';

  @override
  FeatureEntry? get entry => const FeatureEntry(
    title: 'Karnataka Rajyotsava',
    subtitle: 'Quizzes, Kannada learning and Karnataka discovery',
    icon: Icons.flag_outlined,
    path: RajyotsavaRoutes.root,
  );

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: RajyotsavaRoutes.root,
      name: 'rajyotsava',
      builder: (context, state) => const RajyotsavaPage(),
    ),
  ];
}
