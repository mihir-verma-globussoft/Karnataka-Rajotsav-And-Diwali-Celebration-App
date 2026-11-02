import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/pitch_game_page.dart';

abstract final class PitchGameRoutes {
  static const String root = '/pitch_game';
}

class PitchGameFeature implements FeatureModule {
  const PitchGameFeature();

  @override
  String get id => 'pitch_game';

  @override
  FeatureTab? get tab => null;

  @override
  FeatureEntry? get entry => const FeatureEntry(
    title: 'High Pitch Game',
    subtitle: 'A sound-based voice game',
    icon: Icons.mic_none_outlined,
    path: PitchGameRoutes.root,
    group: FeatureGroups.games,
    order: 1,
  );

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: PitchGameRoutes.root,
      name: 'pitch_game',
      builder: (context, state) => const PitchGamePage(),
    ),
  ];
}
