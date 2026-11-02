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
  FeatureEntry? get entry => const FeatureEntry(
    title: 'High Pitch / Low Pitch',
    subtitle: 'A sound-based voice game',
    icon: Icons.mic_none_outlined,
    path: PitchGameRoutes.root,
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
