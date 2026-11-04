import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/pacman_game_page.dart';
import 'presentation/pacman_intro_page.dart';
import 'presentation/pacman_roster.dart';
import 'presentation/pacman_scores_page.dart';

abstract final class PacmanDiwaliRoutes {
  static const String root = '/pacman_diwali';
  static const String play = '/pacman_diwali/play';
  static const String scores = '/pacman_diwali/scores';
}

class PacmanDiwaliFeature implements FeatureModule {
  const PacmanDiwaliFeature();

  @override
  String get id => 'pacman_diwali';

  @override
  FeatureTab? get tab => null;

  @override
  FeatureEntry? get entry => const FeatureEntry(
    title: 'Pac-Man',
    subtitle: 'Eat every dot and dodge the ghosts',
    icon: Icons.videogame_asset_outlined,
    path: PacmanDiwaliRoutes.root,
    group: FeatureGroups.games,
    order: 1,
    image: 'assets/pacman/banner.png',
  );

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: PacmanDiwaliRoutes.root,
      name: 'pacman_diwali',
      builder: (context, state) => const PacmanIntroPage(),
      routes: [
        GoRoute(
          path: 'play',
          name: 'pacman_diwali_play',
          // The chosen chasers and selfie ride along as the route's `extra`.
          builder: (context, state) =>
              PacmanGamePage(setup: state.extra as PacmanSetup?),
        ),
        GoRoute(
          path: 'scores',
          name: 'pacman_diwali_scores',
          builder: (context, state) => const PacmanScoresPage(),
        ),
      ],
    ),
  ];
}
