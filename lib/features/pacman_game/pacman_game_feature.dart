import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/pacman_game_page.dart';
import 'presentation/pacman_intro_page.dart';
import 'presentation/pacman_roster.dart';

abstract final class PacmanGameRoutes {
  static const String root = '/pacman_game';
  static const String play = '/pacman_game/play';
}

class PacmanGameFeature implements FeatureModule {
  const PacmanGameFeature();

  @override
  String get id => 'pacman_game';

  @override
  FeatureTab? get tab => null;

  @override
  FeatureEntry? get entry => const FeatureEntry(
    title: 'Pac-Man',
    subtitle: 'Diwali special: light every diya, dodge the chasers',
    icon: Icons.circle_outlined,
    path: PacmanGameRoutes.root,
    group: FeatureGroups.games,
    order: 1,
  );

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: PacmanGameRoutes.root,
      name: 'pacman_game',
      builder: (context, state) => const PacmanIntroPage(),
      routes: [
        GoRoute(
          path: 'play',
          name: 'pacman_play',
          // The chosen chasers and selfie ride along as the route's `extra`.
          builder: (context, state) =>
              PacmanGamePage(setup: state.extra as PacmanSetup?),
        ),
      ],
    ),
  ];
}
