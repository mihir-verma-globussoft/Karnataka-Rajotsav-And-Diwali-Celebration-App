import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/character_avatar_view.dart';
import 'presentation/flappy_bird_page.dart';
import 'presentation/game_page.dart';
import 'presentation/game_scoreboard_section.dart';
import 'presentation/leaderboard_page.dart';
import 'presentation/profile_page.dart';
import 'presentation/settings_page.dart';

/// The arcade scoreboard other features (the Deepavali page) may embed.
export 'presentation/arcade_scores_section.dart' show ArcadeScoresSection;

abstract final class FlappyBirdRoutes {
  static const String root = '/flappy_bird';
  static const String game = '/flappy_bird/game';
  static const String leaderboard = '/flappy_bird/leaderboard';
  static const String prizes = '/flappy_bird/prizes';
  static const String profile = '/flappy_bird/profile';
  static const String settings = '/flappy_bird/settings';
  static const String character = '/flappy_bird/character';
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
    image: 'assets/flappy_bird/banner.png',
  );

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: FlappyBirdRoutes.root,
      name: 'flappy_bird',
      builder: (context, state) => const FlappyBirdPage(),
    ),
    GoRoute(
      path: FlappyBirdRoutes.character,
      name: 'flappy_bird_character',
      builder: (context, state) => ProtectedFlappyPage(
        title: 'Player Character',
        builder: (player) => CharacterAvatarView(
          player: player,
          onComplete: (_) => context.pop(),
          onCancel: () => context.pop(),
        ),
      ),
    ),
    GoRoute(
      path: FlappyBirdRoutes.game,
      name: 'flappy_bird_game',
      builder: (context, state) => ProtectedFlappyPage(
        title: 'Three Lives',
        immersive: true,
        builder: (player) => FlappyGameView(player: player),
      ),
    ),
    GoRoute(
      path: FlappyBirdRoutes.leaderboard,
      name: 'flappy_bird_leaderboard',
      builder: (context, state) => ProtectedFlappyPage(
        title: 'Global Leaderboard',
        immersive: true,
        builder: (player) => LeaderboardView(currentPlayer: player),
      ),
    ),
    GoRoute(
      path: FlappyBirdRoutes.prizes,
      name: 'flappy_bird_prizes',
      builder: (context, state) => ProtectedFlappyPage(
        title: 'Prizes',
        immersive: true,
        builder: (player) => LeaderboardView(
          currentPlayer: player,
          scoreboard: const GameScoreboardSection(),
        ),
      ),
    ),
    GoRoute(
      path: FlappyBirdRoutes.profile,
      name: 'flappy_bird_profile',
      builder: (context, state) => ProtectedFlappyPage(
        title: 'My Profile',
        immersive: true,
        builder: (_) => const PlayerProfileView(),
      ),
    ),
    GoRoute(
      path: FlappyBirdRoutes.settings,
      name: 'flappy_bird_settings',
      builder: (context, state) => ProtectedFlappyPage(
        title: 'Settings',
        immersive: true,
        builder: (_) => const FlappySettingsView(),
      ),
    ),
  ];
}
