import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/game_score.dart';

class SupabaseGameScoresRepository implements GameScoresRepository {
  const SupabaseGameScoresRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<GameScore>> load() async {
    try {
      final rows = await _client
          .rpc<List<dynamic>>('get_my_game_scores')
          .timeout(const Duration(seconds: 15));
      return [
        for (final value in rows)
          if (value is Map<String, dynamic>)
            GameScore(
              slug: value['game_slug'] as String,
              name: value['display_name'] as String,
              bestScore: _int(value['best_score']),
              gamesPlayed: _int(value['games_played']),
              ceiling: _int(value['score_ceiling']),
              points: _int(value['points']),
            ),
      ];
    } on TimeoutException catch (error) {
      throw UnexpectedFailure('Your game scores took too long to load.', error);
    } on PostgrestException catch (error) {
      // `get_my_game_scores` is not deployed yet: build the scoreboard from the
      // per-game stats call every earlier migration already provides.
      if (error.code == 'PGRST202' || error.code == '42883') {
        return _fromGameStats();
      }
      throw UnexpectedFailure('Your game scores could not be loaded.', error);
    }
  }

  Future<List<GameScore>> _fromGameStats() async {
    try {
      return await Future.wait([
        for (final game in _games.entries) _statsFor(game.key, game.value),
      ]).timeout(const Duration(seconds: 15));
    } on TimeoutException catch (error) {
      throw UnexpectedFailure('Your game scores took too long to load.', error);
    } on PostgrestException catch (error) {
      throw UnexpectedFailure('Your game scores could not be loaded.', error);
    }
  }

  Future<GameScore> _statsFor(String slug, String name) async {
    final dynamic response = await _client.rpc<dynamic>(
      'get_my_stats',
      params: {'p_game_slug': slug},
    );
    final row = response is Map ? response : const <String, dynamic>{};
    return GameScore(
      slug: slug,
      name: name,
      bestScore: _int(row['high_score']),
      gamesPlayed: _int(row['total_games']),
    );
  }
}

/// The games on the combined leaderboard, for the fallback above.
const Map<String, String> _games = {
  'flappy_bird': 'Flappy Bird',
  'pacman': 'Pac-Man',
  'ar_hunt': 'Habba Hunt',
  'rajyotsava_quiz': 'Rajyotsava Quiz',
  'deepavali_quiz': 'Deepavali Quiz',
  'deepavali_guess': 'Guess the Object',
  'deepavali_diya': 'Light the Diyas',
};

int _int(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.tryParse(text) ?? 0,
  _ => 0,
};
