import 'dart:typed_data';

import 'game_result.dart';
import 'player.dart';

abstract interface class PlayerRepository {
  Future<DashboardData> loadDashboard();

  Future<PlayerProfile> loadProfile();

  Future<PlayerStats> loadStats();

  Future<PlayerProfile> updateUsername(String username);

  Future<PlayerProfile> updateCharacterAvatar(
    Uint8List bytes, {
    required String contentType,
  });

  Future<List<LeaderboardEntry>> loadLeaderboard({
    required int offset,
    required int limit,
  });

  Future<GameSubmission> submitGame(GameResult result);
}

abstract interface class PendingGameRepository {
  Future<void> save(GameResult result);

  Future<List<GameResult>> loadAll();

  Future<void> remove(String gameId);
}
