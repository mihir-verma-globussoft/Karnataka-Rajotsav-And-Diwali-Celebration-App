import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/deepavali_scores.dart';

/// The Deepavali leaderboards on the app's shared Supabase games backend (see
/// docs/GAMING_BACKEND.md). The three games are registered there by
/// supabase/migrations/202611040002_deepavali_games.sql.
///
/// It uses the player already signed in to the app; games that cannot be
/// sent are kept on the phone, per player, and sent later. The server counts
/// each game once, by its id, so sending one again is safe.
class SupabaseDeepavaliScoreboard implements DeepavaliScoreboard {
  SupabaseDeepavaliScoreboard(
    this._client, {
    SharedPreferencesAsync? preferences,
    this._now = DateTime.now,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  /// Games older than this are dropped from the phone: the server no longer
  /// accepts them (30 days).
  static const Duration maxPendingAge = Duration(days: 29);

  /// Longest game the backend accepts (max_duration_ms in the migration). A
  /// game left open longer is not sent.
  static const Duration maxDuration = Duration(hours: 1);

  /// Most games kept on the phone; the oldest go first.
  static const int maxPending = 50;

  final SupabaseClient _client;
  final SharedPreferencesAsync _preferences;
  final DateTime Function() _now;

  String? get _userId => _client.auth.currentUser?.id;

  String _pendingKey(String userId) => 'deepavali.scores.pending.v1.$userId';

  @override
  bool get isAvailable => _userId != null;

  @override
  Future<ScoreSaveOutcome> save(GameRound round) async {
    final userId = _userId;
    if (userId == null || round.duration > maxDuration) {
      return const ScoreNotSaved();
    }
    try {
      final saved = await _submit(round);
      await _removePending(userId, round.id);
      return saved;
    } on Object {
      await _addPending(userId, round);
      return const ScoreQueued();
    }
  }

  @override
  Future<void> sendPending() async {
    final userId = _userId;
    if (userId == null) return;
    for (final round in await _loadPending(userId)) {
      // The server only accepts games up to 30 days old.
      if (_now().difference(round.startedAt) > maxPendingAge) {
        await _removePending(userId, round.id);
        continue;
      }
      try {
        await _submit(round);
        await _removePending(userId, round.id);
      } on Object {
        // Kept for next time, whatever the error: the server gives the same
        // error code for "game not registered yet" as for a bad score, and
        // games saved before the migration is applied must not be lost.
      }
    }
  }

  Future<ScoreSaved> _submit(GameRound round) async {
    final dynamic response = await _client.rpc<dynamic>(
      'submit_game_result',
      params: {
        'p_game_id': round.id,
        'p_game_slug': round.game.slug,
        'p_score': round.points,
        'p_duration_ms': round.duration.inMilliseconds,
        'p_started_at': round.startedAt.toUtc().toIso8601String(),
      },
    );
    final row = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    return ScoreSaved(
      best: _int(row['high_score']),
      isNewBest: row['is_new_high_score'] as bool? ?? false,
      rounds: _int(row['total_games']),
    );
  }

  @override
  Future<ScoreStanding?> standing(DeepavaliGame game) async {
    if (_userId == null) return null;
    try {
      final dynamic response = await _client.rpc<dynamic>(
        'get_my_stats',
        params: {'p_game_slug': game.slug},
      );
      final row = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      return ScoreStanding(
        best: _int(row['high_score']),
        rounds: _int(row['total_games']),
        rank: row['global_rank'] == null ? null : _int(row['global_rank']),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<List<ScoreLeader>> leaders(
    DeepavaliGame game, {
    int limit = 10,
  }) async {
    final userId = _userId;
    if (userId == null) return const [];
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'get_leaderboard',
        params: {
          'p_game_slug': game.slug,
          'p_offset': 0,
          'p_limit': limit.clamp(1, 50),
        },
      );
      return [
        for (final value in rows)
          if (value is Map)
            ScoreLeader(
              rank: _int(value['rank']),
              name: '${value['username'] ?? 'Player'}',
              points: _int(value['high_score']),
              avatarUrl: value['avatar_url'] as String?,
              isYou: value['user_id'] == userId,
            ),
      ];
    } on Object {
      return const [];
    }
  }

  Future<List<GameRound>> _loadPending(String userId) async {
    final stored =
        await _preferences.getStringList(_pendingKey(userId)) ?? const [];
    return [for (final item in stored) ?_decode(item)];
  }

  Future<void> _addPending(String userId, GameRound round) async {
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

  Future<void> _writePending(String userId, List<GameRound> pending) =>
      _preferences.setStringList(_pendingKey(userId), [
        for (final r in pending) jsonEncode(r.toJson()),
      ]);
}

GameRound? _decode(String item) {
  try {
    return GameRound.fromJson(jsonDecode(item));
  } on FormatException {
    return null;
  }
}

int _int(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.tryParse(text) ?? 0,
  _ => 0,
};
