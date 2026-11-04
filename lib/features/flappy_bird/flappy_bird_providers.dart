import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import 'data/local_game_storage.dart';
import 'data/supabase_auth_repository.dart';
import 'data/supabase_player_repository.dart';
import 'domain/auth_repository.dart';
import 'domain/game_preferences.dart';
import 'domain/game_result.dart';
import 'domain/player.dart';
import 'domain/player_repository.dart';

final flappyAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase ||
      !config.hasGoogleAuth ||
      !Supabase.instance.isInitialized) {
    return const _UnconfiguredAuthRepository();
  }
  return SupabaseAuthRepository(
    Supabase.instance.client,
    config.googleWebClientId,
    config.googleIosClientId,
    ref.watch(loggerProvider),
  );
});

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase || !Supabase.instance.isInitialized) {
    return const _UnconfiguredPlayerRepository();
  }
  return SupabasePlayerRepository(Supabase.instance.client);
});

final gamePreferencesRepositoryProvider = Provider<GamePreferencesRepository>(
  (ref) => LocalGamePreferencesRepository(),
);

final pendingGameRepositoryProvider = Provider<PendingGameRepository>(
  (ref) => LocalPendingGameRepository(
    userId:
        ref
            .watch(flappyAuthStateProvider)
            .whenOrNull(data: (player) => player?.id) ??
        'signed_out',
  ),
);

final recentScoreRepositoryProvider = Provider<RecentScoreRepository>(
  (ref) => LocalRecentScoreRepository(
    userId:
        ref
            .watch(flappyAuthStateProvider)
            .whenOrNull(data: (player) => player?.id) ??
        'signed_out',
  ),
);

final flappyAuthStateProvider = StreamProvider<PlayerProfile?>(
  (ref) => ref.watch(flappyAuthRepositoryProvider).watchPlayer(),
);

final dashboardProvider = FutureProvider.autoDispose<DashboardData>(
  (ref) => ref.watch(playerRepositoryProvider).loadDashboard(),
);

/// The player's latest game score on this device; null before the first game.
final recentScoreProvider = FutureProvider.autoDispose<int?>(
  (ref) => ref.watch(recentScoreRepositoryProvider).load(),
);

/// The top of the global leaderboard, as shown in the Diwali arcade section.
final topLeaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>(
      (ref) => ref
          .watch(playerRepositoryProvider)
          .loadLeaderboard(offset: 0, limit: topLeaderboardSize),
    );

/// How many players the Diwali arcade section lists before "View full".
const topLeaderboardSize = 5;

final playerProfileProvider = FutureProvider.autoDispose<PlayerProfile>(
  (ref) => ref.watch(playerRepositoryProvider).loadProfile(),
);

final gamePreferencesProvider = FutureProvider<GamePreferences>(
  (ref) => ref.watch(gamePreferencesRepositoryProvider).load(),
);

final scoreSubmissionServiceProvider = Provider<ScoreSubmissionService>(
  (ref) => ScoreSubmissionService(
    ref.watch(playerRepositoryProvider),
    ref.watch(pendingGameRepositoryProvider),
    recentScores: ref.watch(recentScoreRepositoryProvider),
  ),
);

class ScoreSubmissionService {
  const ScoreSubmissionService(
    this._playerRepository,
    this._pendingRepository, {
    this._recentScores,
  });

  final PlayerRepository _playerRepository;
  final PendingGameRepository _pendingRepository;
  final RecentScoreRepository? _recentScores;

  Future<GameSubmission> submit(GameResult result) async {
    // Recorded before the network call so "Recent score" is right even when
    // the submission fails and is retried later.
    await _recentScores?.save(result.score);
    try {
      final submission = await _playerRepository.submitGame(result);
      await _pendingRepository.remove(result.gameId);
      return submission;
    } on Object {
      await _pendingRepository.save(result);
      rethrow;
    }
  }

  Future<int> retryPending() async {
    var sent = 0;
    for (final result in await _pendingRepository.loadAll()) {
      try {
        await _playerRepository.submitGame(result);
        await _pendingRepository.remove(result.gameId);
        sent++;
      } on Object {
        // Keep the item for a later controlled retry.
      }
    }
    return sent;
  }
}

class _UnconfiguredAuthRepository implements AuthRepository {
  const _UnconfiguredAuthRepository();

  Never _missing() => throw const AuthConfigurationException(
    'Add Supabase and Google client IDs to run the account features.',
  );

  @override
  Future<PlayerProfile?> currentPlayer() async => null;

  @override
  Future<void> deleteAccount() async => _missing();

  @override
  Future<PlayerProfile> signInWithGoogle() async => _missing();

  @override
  Future<void> signOut() async => _missing();

  @override
  Stream<PlayerProfile?> watchPlayer() => Stream.value(null);
}

class _UnconfiguredPlayerRepository implements PlayerRepository {
  const _UnconfiguredPlayerRepository();

  Never _missing() => throw const AuthConfigurationException(
    'Supabase is not configured for this build.',
  );

  @override
  Future<DashboardData> loadDashboard() async => _missing();

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard({
    required int offset,
    required int limit,
  }) async => _missing();

  @override
  Future<PlayerProfile> loadProfile() async => _missing();

  @override
  Future<PlayerStats> loadStats() async => _missing();

  @override
  Future<GameSubmission> submitGame(GameResult result) async => _missing();

  @override
  Future<PlayerProfile> updateUsername(String username) async => _missing();

  @override
  Future<PlayerProfile> updateCharacterAvatar(
    Uint8List bytes, {
    required String contentType,
  }) async => _missing();
}
