import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_preferences.dart';
import '../domain/game_result.dart';
import '../domain/player_repository.dart';

class LocalGamePreferencesRepository implements GamePreferencesRepository {
  LocalGamePreferencesRepository([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _soundKey = 'flappy_bird.sound_effects';
  final SharedPreferencesAsync _preferences;

  @override
  Future<GamePreferences> load() async => GamePreferences(
    soundEffectsEnabled: await _preferences.getBool(_soundKey) ?? true,
  );

  @override
  Future<void> save(GamePreferences preferences) =>
      _preferences.setBool(_soundKey, preferences.soundEffectsEnabled);
}

class LocalPendingGameRepository implements PendingGameRepository {
  LocalPendingGameRepository({
    required String userId,
    SharedPreferencesAsync? preferences,
  }) : _pendingKey = 'flappy_bird.pending_results.$userId',
       _preferences = preferences ?? SharedPreferencesAsync();

  final String _pendingKey;
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<GameResult>> loadAll() async {
    final stored = await _preferences.getStringList(_pendingKey) ?? const [];
    return stored.map(_decode).whereType<GameResult>().toList();
  }

  @override
  Future<void> save(GameResult result) async {
    final results = await loadAll();
    if (results.any((item) => item.gameId == result.gameId)) return;
    results.add(result);
    await _write(results);
  }

  @override
  Future<void> remove(String gameId) async {
    final results = await loadAll();
    results.removeWhere((item) => item.gameId == gameId);
    await _write(results);
  }

  Future<void> _write(List<GameResult> results) => _preferences.setStringList(
    _pendingKey,
    results.map(_encode).toList(growable: false),
  );
}

String _encode(GameResult result) => jsonEncode({
  'id': result.gameId,
  'game_slug': result.gameSlug,
  'score': result.score,
  'duration_ms': result.duration.inMilliseconds,
  'started_at': result.startedAt.toIso8601String(),
});

GameResult? _decode(String source) {
  try {
    final value = jsonDecode(source) as Map<String, dynamic>;
    return GameResult(
      gameId: value['id'] as String,
      gameSlug: value['game_slug'] as String? ?? 'flappy_bird',
      score: value['score'] as int,
      duration: Duration(milliseconds: value['duration_ms'] as int),
      startedAt: DateTime.parse(value['started_at'] as String),
    );
  } on Object {
    return null;
  }
}
