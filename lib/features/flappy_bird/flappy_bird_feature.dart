import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/flappy_bird_page.dart';

abstract final class FlappyBirdRoutes {
  static const String root = '/flappy_bird';
}

class FlappyBirdFeature implements FeatureModule {
  const FlappyBirdFeature();

  @override
  String get id => 'flappy_bird';

  @override
  FeatureTab? get tab => null;

  @override
  FeatureEntry? get entry => const FeatureEntry(
    title: 'Flappy Bird',
    subtitle: 'Tap to fly and beat your score',
    icon: Icons.sports_esports_outlined,
    path: FlappyBirdRoutes.root,
    group: FeatureGroups.games,
    order: 0,
  );

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: FlappyBirdRoutes.root,
      name: 'flappy_bird',
      builder: (context, state) => const FlappyBirdPage(),
    ),
  ];
}
