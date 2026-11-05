import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/game_result.dart';
import '../domain/player.dart';
import '../domain/player_repository.dart';

class SupabasePlayerRepository implements PlayerRepository {
  const SupabasePlayerRepository(this._client, {this.gameSlug = 'flappy_bird'});

  final SupabaseClient _client;
  final String gameSlug;

  @override
  Future<DashboardData> loadDashboard() async {
    final values = await Future.wait<Object>([
      loadProfile(),
      loadStats(),
      _loadGlobalArcadeStats(),
    ]);
    final flappyStats = values[1] as PlayerStats;
    final globalStats = values[2] as PlayerStats;
    return DashboardData(
      profile: values[0] as PlayerProfile,
      stats: PlayerStats(
        highScore: flappyStats.highScore,
        totalGames: globalStats.totalGames,
        totalScore: globalStats.totalScore,
        globalRank: globalStats.globalRank,
      ),
    );
  }

  @override
  Future<PlayerProfile> loadProfile() async {
    final userId = _requireUserId();
    try {
      final row = await _client
          .from('profiles')
          .select(
            'id, username, email, avatar_url, character_avatar_url, created_at',
          )
          .eq('id', userId)
          .single();
      return _profile(row);
    } on PostgrestException catch (error) {
      throw UnexpectedFailure('Your profile could not be loaded.', error);
    }
  }

  @override
  Future<PlayerStats> loadStats() async {
    try {
      final dynamic response = await _client.rpc<dynamic>(
        'get_my_stats',
        params: {'p_game_slug': gameSlug},
      );
      final row = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      return PlayerStats(
        highScore: _int(row['high_score']),
        totalGames: _int(row['total_games']),
        totalScore: _int(row['total_score']),
        globalRank: row['global_rank'] == null
            ? null
            : _int(row['global_rank']),
      );
    } on PostgrestException catch (error) {
      throw UnexpectedFailure('Player statistics could not be loaded.', error);
    }
  }

  Future<PlayerStats> _loadGlobalArcadeStats() async {
    try {
      final dynamic response = await _client.rpc<dynamic>(
        'get_global_arcade_stats',
      );
      final row = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      return PlayerStats(
        highScore: 0,
        totalGames: _int(row['total_games']),
        totalScore: _int(row['total_best_score']),
        globalRank: row['global_rank'] == null
            ? null
            : _int(row['global_rank']),
      );
    } on PostgrestException catch (error) {
      throw UnexpectedFailure(
        'Global arcade statistics could not be loaded.',
        error,
      );
    }
  }

  @override
  Future<PlayerProfile> updateUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.length < 3 || trimmed.length > 24) {
      throw const UnexpectedFailure('Username must be 3–24 characters.');
    }
    try {
      final row = await _client
          .from('profiles')
          .update({'username': trimmed})
          .eq('id', _requireUserId())
          .select(
            'id, username, email, avatar_url, character_avatar_url, created_at',
          )
          .single();
      return _profile(row);
    } on PostgrestException catch (error) {
      throw UnexpectedFailure('Username could not be updated.', error);
    }
  }

  @override
  Future<PlayerProfile> updateCharacterAvatar(
    Uint8List bytes, {
    required String contentType,
  }) async {
    if (bytes.isEmpty) {
      throw const UnexpectedFailure('The captured photo is empty.');
    }
    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      throw const UnexpectedFailure('The captured photo is too large.');
    }
    final userId = _requireUserId();
    const objectName = 'character-avatar';
    final path = '$userId/$objectName';
    try {
      await _client.storage
          .from('player-avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
              cacheControl: '3600',
            ),
          );
      final publicUrl = _client.storage
          .from('player-avatars')
          .getPublicUrl(path);
      final versionedUrl =
          '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      final row = await _client
          .from('profiles')
          .update({'character_avatar_url': versionedUrl})
          .eq('id', userId)
          .select(
            'id, username, email, avatar_url, character_avatar_url, created_at',
          )
          .single();
      return _profile(row);
    } on StorageException catch (error) {
      throw UnexpectedFailure(
        'Your player photo could not be uploaded (${error.message}).',
        error,
      );
    } on PostgrestException catch (error) {
      throw UnexpectedFailure(
        'Your player photo could not be saved (${error.message}).',
        error,
      );
    }
  }

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard({
    required int offset,
    required int limit,
  }) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'get_global_arcade_leaderboard',
        params: {'p_offset': offset, 'p_limit': limit.clamp(1, 50)},
      );
      return [
        for (final value in rows)
          if (value is Map<String, dynamic>)
            LeaderboardEntry(
              rank: _int(value['rank']),
              userId: value['user_id'] as String,
              username: value['username'] as String,
              avatarUrl: value['avatar_url'] as String?,
              highScore: _int(value['total_best_score']),
            ),
      ];
    } on PostgrestException catch (error) {
      throw UnexpectedFailure('The leaderboard could not be loaded.', error);
    }
  }

  @override
  Future<GameSubmission> submitGame(GameResult result) async {
    if (result.gameSlug != gameSlug) {
      throw UnexpectedFailure(
        'The result belongs to ${result.gameSlug}, not $gameSlug.',
      );
    }
    try {
      final dynamic response = await _client.rpc<dynamic>(
        'submit_game_result',
        params: {
          'p_game_id': result.gameId,
          'p_game_slug': result.gameSlug,
          'p_score': result.score,
          'p_duration_ms': result.duration.inMilliseconds,
          'p_started_at': result.startedAt.toIso8601String(),
        },
      );
      final row = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      return GameSubmission(
        highScore: _int(row['high_score']),
        totalGames: _int(row['total_games']),
        totalScore: _int(row['total_score']),
        isNewHighScore: row['is_new_high_score'] as bool? ?? false,
        wasAlreadySubmitted: row['already_submitted'] as bool? ?? false,
      );
    } on PostgrestException catch (error) {
      throw UnexpectedFailure(
        'Your score is saved on this device and will be retried (${error.message}).',
        error,
      );
    }
  }

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const UnexpectedFailure('Please sign in again.');
    return id;
  }
}

PlayerProfile _profile(Map<String, dynamic> row) => PlayerProfile(
  id: row['id'] as String,
  username: row['username'] as String,
  email: row['email'] as String?,
  avatarUrl: row['avatar_url'] as String?,
  characterAvatarUrl: row['character_avatar_url'] as String?,
  createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
);

int _int(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.parse(text),
  _ => 0,
};
