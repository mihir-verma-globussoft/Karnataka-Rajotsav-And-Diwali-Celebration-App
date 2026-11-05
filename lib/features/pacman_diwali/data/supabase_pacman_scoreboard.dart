import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/pacman_scoreboard.dart';

/// Pac-Man's leaderboard on the app's shared Supabase games backend (see
/// docs/GAMING_BACKEND.md). The game is registered there as [gameSlug] by
/// supabase/migrations/202611040003_pacman_game.sql.
///
/// It uses the player already signed in to the app. Rounds that cannot be
/// sent are kept on the phone, per player, and sent later; the server counts
/// each round once, by its id.
class SupabasePacmanScoreboard implements PacmanScoreboard {
  SupabasePacmanScoreboard(
    this._client, {
    SharedPreferencesAsync? preferences,
    this._now = DateTime.now,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  /// The game's id in the backend's registry. Never change it.
  static const String gameSlug = 'pacman';

  /// The server no longer accepts rounds older than this.
  static const Duration maxPendingAge = Duration(days: 29);

  /// Longest round the backend accepts (max_duration_ms in the migration).
  static const Duration maxRoundDuration = Duration(hours: 1);

  /// Most rounds kept on the phone; the oldest go first.
  static const int maxPending = 50;

  final SupabaseClient _client;
  final SharedPreferencesAsync _preferences;
  final DateTime Function() _now;

  String? get _userId => _client.auth.currentUser?.id;

  String _pendingKey(String userId) => 'pacman.pending.v1.$userId';
  String _lastKey(String userId) => 'pacman.last.v1.$userId';

  @override
  bool get isAvailable => _userId != null;

  @override
  Future<PacmanSaveOutcome> save(PacmanRound round) async {
    final userId = _userId;
    if (userId == null || round.duration > maxRoundDuration) {
      return const PacmanNotSaved();
    }
    // Recorded first so "Last score" is right even when sending fails.
    await _preferences.setInt(_lastKey(userId), round.score);
    try {
      final saved = await _submit(round);
      await _removePending(userId, round.id);
      return saved;
    } on Object {
      await _addPending(userId, round);
      return const PacmanQueued();
    }
  }

  @override
  Future<void> sendPending() async {
    final userId = _userId;
    if (userId == null) return;
    for (final round in await _loadPending(userId)) {
      if (_now().difference(round.startedAt) > maxPendingAge) {
        await _removePending(userId, round.id);
        continue;
      }
      try {
        await _submit(round);
        await _removePending(userId, round.id);
      } on Object {
        // Kept for next time, whatever the error: a round saved before the
        // game is registered on the server must not be lost.
      }
    }
  }

  Future<PacmanSaved> _submit(PacmanRound round) async {
    final dynamic response = await _client.rpc<dynamic>(
      'submit_game_result',
      params: {
        'p_game_id': round.id,
        'p_game_slug': gameSlug,
        'p_score': round.score,
        'p_duration_ms': round.duration.inMilliseconds,
        'p_started_at': round.startedAt.toUtc().toIso8601String(),
      },
    );
    final row = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    return PacmanSaved(
      best: _int(row['high_score']),
      isNewBest: row['is_new_high_score'] as bool? ?? false,
      rounds: _int(row['total_games']),
    );
  }

  @override
  Future<PacmanStanding?> standing() async {
    if (_userId == null) return null;
    try {
      final dynamic response = await _client.rpc<dynamic>(
        'get_my_stats',
        params: {'p_game_slug': gameSlug},
      );
      final row = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      return PacmanStanding(
        best: _int(row['high_score']),
        rounds: _int(row['total_games']),
        total: _int(row['total_score']),
        rank: row['global_rank'] == null ? null : _int(row['global_rank']),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<int?> lastScore() async {
    final userId = _userId;
    return userId == null ? null : _preferences.getInt(_lastKey(userId));
  }

  @override
  Future<List<PacmanLeader>> leaders({int limit = 50}) async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.rpc<List<dynamic>>(
      'get_leaderboard',
      params: {
        'p_game_slug': gameSlug,
        'p_offset': 0,
        'p_limit': limit.clamp(1, 50),
      },
    );
    return [
      for (final value in rows)
        if (value is Map)
          PacmanLeader(
            rank: _int(value['rank']),
            name: '${value['username'] ?? 'Player'}',
            points: _int(value['high_score']),
            avatarUrl: value['avatar_url'] as String?,
            isYou: value['user_id'] == userId,
          ),
    ];
  }

  Future<List<PacmanRound>> _loadPending(String userId) async {
    final stored =
        await _preferences.getStringList(_pendingKey(userId)) ?? const [];
    return [for (final item in stored) ?_decode(item)];
  }

  Future<void> _addPending(String userId, PacmanRound round) async {
    final pending = await _loadPending(userId);
    if (pending.any((r) => r.id == round.id)) return;
    final kept = [...pending, round];
    await _writePending(
      userId,
      kept.length > maxPending ? kept.sublist(kept.length - maxPending) : kept,
    );
  }

  Future<void> _removePending(String userId, String id) async {
    final pending = await _loadPending(userId);
    if (!pending.any((r) => r.id == id)) return;
    await _writePending(userId, [
      for (final r in pending)
        if (r.id != id) r,
    ]);
  }

  Future<void> _writePending(String userId, List<PacmanRound> pending) =>
      _preferences.setStringList(_pendingKey(userId), [
        for (final r in pending) jsonEncode(r.toJson()),
      ]);
}

PacmanRound? _decode(String item) {
  try {
    return PacmanRound.fromJson(jsonDecode(item));
  } on Object {
    return null;
  }
}

int _int(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.tryParse(text) ?? 0,
  _ => 0,
};
