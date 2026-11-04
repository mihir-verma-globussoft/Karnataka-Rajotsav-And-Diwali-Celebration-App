import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/quiz_scores.dart';

/// The quiz leaderboard on the app's shared Supabase games backend (see
/// docs/GAMING_BACKEND.md). The quiz is registered there as
/// [gameSlug] by supabase/migrations/202611040001_rajyotsava_quiz_game.sql.
///
/// It uses the player already signed in to the app; rounds that cannot be
/// sent are kept on the phone, per player, and sent later. The server
/// counts each round once, by its id, so sending one again is safe.
class SupabaseQuizScoreboard implements QuizScoreboard {
  SupabaseQuizScoreboard(
    this._client, {
    SharedPreferencesAsync? preferences,
    this._now = DateTime.now,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  /// The quiz's id in the backend's game registry. Never change it.
  static const String gameSlug = 'rajyotsava_quiz';

  /// Rounds older than this are dropped from the phone: the server no
  /// longer accepts them.
  static const Duration maxPendingAge = Duration(days: 29);

  /// Longest round the backend accepts (max_duration_ms in the migration).
  /// A round left open longer is not sent.
  static const Duration maxRoundDuration = Duration(hours: 1);

  /// Most rounds kept on the phone; the oldest go first.
  static const int maxPending = 50;

  final SupabaseClient _client;
  final SharedPreferencesAsync _preferences;
  final DateTime Function() _now;

  String? get _userId => _client.auth.currentUser?.id;

  String _pendingKey(String userId) => 'rajyotsava.quiz.pending.v1.$userId';

  @override
  bool get isAvailable => _userId != null;

  @override
  Future<QuizSaveOutcome> save(QuizRoundResult result) async {
    final userId = _userId;
    if (userId == null || result.duration > maxRoundDuration) {
      return const QuizNotSaved();
    }
    try {
      final saved = await _submit(result);
      await _removePending(userId, result.id);
      return saved;
    } on Object {
      await _addPending(userId, result);
      return const QuizQueued();
    }
  }

  @override
  Future<void> sendPending() async {
    final userId = _userId;
    if (userId == null) return;
    for (final result in await _loadPending(userId)) {
      // The server only accepts rounds up to 30 days old.
      if (_now().difference(result.startedAt) > maxPendingAge) {
        await _removePending(userId, result.id);
        continue;
      }
      try {
        await _submit(result);
        await _removePending(userId, result.id);
      } on Object {
        // Kept for next time, whatever the error: the server gives the same
        // error code for "quiz not registered yet" as for a bad round, and
        // rounds saved before the quiz is registered must not be lost.
      }
    }
  }

  Future<QuizSaved> _submit(QuizRoundResult result) async {
    final dynamic response = await _client.rpc<dynamic>(
      'submit_game_result',
      params: {
        'p_game_id': result.id,
        'p_game_slug': gameSlug,
        'p_score': result.points,
        'p_duration_ms': result.duration.inMilliseconds,
        'p_started_at': result.startedAt.toUtc().toIso8601String(),
      },
    );
    final row = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    return QuizSaved(
      best: _int(row['high_score']),
      isNewBest: row['is_new_high_score'] as bool? ?? false,
      rounds: _int(row['total_games']),
    );
  }

  @override
  Future<QuizStanding?> standing() async {
    if (_userId == null) return null;
    try {
      final dynamic response = await _client.rpc<dynamic>(
        'get_my_stats',
        params: {'p_game_slug': gameSlug},
      );
      final row = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      return QuizStanding(
        best: _int(row['high_score']),
        rounds: _int(row['total_games']),
        rank: row['global_rank'] == null ? null : _int(row['global_rank']),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<List<QuizLeader>> leaders({int limit = 10}) async {
    final userId = _userId;
    if (userId == null) return const [];
    try {
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
            QuizLeader(
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

  Future<List<QuizRoundResult>> _loadPending(String userId) async {
    final stored =
        await _preferences.getStringList(_pendingKey(userId)) ?? const [];
    return [for (final item in stored) ?_decode(item)];
  }

  Future<void> _addPending(String userId, QuizRoundResult result) async {
    final pending = await _loadPending(userId);
    if (pending.any((r) => r.id == result.id)) return;
    final kept = [...pending, result];
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

  Future<void> _writePending(String userId, List<QuizRoundResult> pending) =>
      _preferences.setStringList(_pendingKey(userId), [
        for (final r in pending) jsonEncode(r.toJson()),
      ]);
}

QuizRoundResult? _decode(String item) {
  try {
    return QuizRoundResult.fromJson(jsonDecode(item));
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
