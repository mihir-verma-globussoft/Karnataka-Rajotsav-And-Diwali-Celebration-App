import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import 'data/asset_game_music.dart';
import 'data/asset_game_over_audio.dart';
import 'data/supabase_pacman_scoreboard.dart';
import 'domain/game_music.dart';
import 'domain/game_over_audio.dart';
import 'domain/pacman_scoreboard.dart';

/// Override in tests with a fake [GameOverAudio].
final gameOverAudioProvider = Provider<GameOverAudio>((ref) {
  final audio = AssetGameOverAudio();
  ref.onDispose(audio.dispose);
  return audio;
});

/// Override in tests with a fake [GameMusic].
final gameMusicProvider = Provider<GameMusic>((ref) {
  final music = AssetGameMusic();
  ref.onDispose(music.dispose);
  return music;
});

/// Pac-Man's scores on the shared games backend, when this build has one
/// (run with --dart-define-from-file=.env); otherwise the game works without
/// scores. Override in tests.
final pacmanScoreboardProvider = Provider<PacmanScoreboard>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase || !Supabase.instance.isInitialized) {
    return const NoPacmanScoreboard();
  }
  return SupabasePacmanScoreboard(Supabase.instance.client);
});

/// The player's best, games, total and global rank; null if unavailable.
final pacmanStandingProvider = FutureProvider.autoDispose<PacmanStanding?>((
  ref,
) async {
  final board = ref.watch(pacmanScoreboardProvider);
  await board.sendPending();
  return board.standing();
});

/// The player's latest score on this phone.
final pacmanLastScoreProvider = FutureProvider.autoDispose<int?>(
  (ref) => ref.watch(pacmanScoreboardProvider).lastScore(),
);

/// The global leaderboard, best first.
final pacmanLeadersProvider = FutureProvider.autoDispose<List<PacmanLeader>>(
  (ref) => ref.watch(pacmanScoreboardProvider).leaders(),
);
