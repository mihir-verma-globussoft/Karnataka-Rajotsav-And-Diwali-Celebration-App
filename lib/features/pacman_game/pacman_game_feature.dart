import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/pacman_page.dart';

abstract final class PacmanGameRoutes {
  static const String root = '/pacman_game';
}

/// Pac-Man: eat every dot, dodge the ghosts, grab a power pellet to turn the
/// tables.
class PacmanGameFeature implements FeatureModule {
  const PacmanGameFeature();

  @override
  String get id => 'pacman_game';

  @override
  FeatureTab? get tab => null;

  @override
  FeatureEntry? get entry => const FeatureEntry(
    title: 'Pac-Man',
    subtitle: 'Eat every dot and dodge the ghosts',
    icon: Icons.videogame_asset_outlined,
    path: PacmanGameRoutes.root,
    group: FeatureGroups.games,
    order: 1,
    image: 'assets/pacman/banner.png',
  );

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: PacmanGameRoutes.root,
      name: 'pacman_game',
      builder: (context, state) => const PacmanPage(),
    ),
  ];
}
