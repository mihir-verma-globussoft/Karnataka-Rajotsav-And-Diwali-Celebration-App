import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/games_page.dart';

/// Games tab: lists every feature whose entry has `group: FeatureGroups.games`.
/// Owned by the integration owner; game modules only register their entry.
class GamesFeature implements FeatureModule {
  const GamesFeature();

  @override
  String get id => 'games';

  @override
  FeatureTab? get tab => FeatureTab(
    order: 2,
    label: 'Games',
    icon: Icons.sports_esports_outlined,
    selectedIcon: Icons.sports_esports,
    builder: (context) => const GamesPage(),
  );

  @override
  FeatureEntry? get entry => null;

  @override
  List<RouteBase> get routes => const [];
}
