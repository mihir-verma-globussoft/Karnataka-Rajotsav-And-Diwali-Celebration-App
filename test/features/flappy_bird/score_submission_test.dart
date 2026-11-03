import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/game_result.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/player.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/player_repository.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/flappy_bird_providers.dart';

void main() {
  final result = GameResult(
    gameId: '00000000-0000-4000-8000-000000000001',
    score: 12,
    duration: const Duration(seconds: 30),
    startedAt: DateTime.utc(2026, 11, 3),
  );

  test('failed score is retained and a later retry removes it', () async {
    final remote = _FakePlayerRepository()..fail = true;
    final pending = _MemoryPendingRepository();
    final service = ScoreSubmissionService(remote, pending);

    await expectLater(service.submit(result), throwsA(isA<Exception>()));
    expect(await pending.loadAll(), [result]);

    remote.fail = false;
    expect(await service.retryPending(), 1);
    expect(await pending.loadAll(), isEmpty);
    expect(remote.submittedIds, {result.gameId});
  });

  test('zero score is submitted normally', () async {
    final remote = _FakePlayerRepository();
    final service = ScoreSubmissionService(remote, _MemoryPendingRepository());
    final zero = GameResult(
      gameId: '00000000-0000-4000-8000-000000000002',
      score: 0,
      duration: Duration.zero,
      startedAt: DateTime.utc(2026, 11, 3),
    );
    final submission = await service.submit(zero);
    expect(submission.totalGames, 1);
    expect(submission.highScore, 0);
  });

  test('lower score does not overwrite a higher personal best', () async {
    final remote = _FakePlayerRepository();
    final service = ScoreSubmissionService(remote, _MemoryPendingRepository());
    await service.submit(_result('00000000-0000-4000-8000-000000000010', 45));
    final lower = await service.submit(
      _result('00000000-0000-4000-8000-000000000011', 32),
    );
    expect(lower.highScore, 45);
    final higher = await service.submit(
      _result('00000000-0000-4000-8000-000000000012', 67),
    );
    expect(higher.highScore, 67);
  });

  test('the same game identifier increments totals exactly once', () async {
    final remote = _FakePlayerRepository();
    final service = ScoreSubmissionService(remote, _MemoryPendingRepository());
    final game = _result('00000000-0000-4000-8000-000000000020', 8);
    await service.submit(game);
    final duplicate = await service.submit(game);
    expect(duplicate.wasAlreadySubmitted, isTrue);
    expect(duplicate.totalGames, 1);
    expect(duplicate.totalScore, 8);
  });
}

GameResult _result(String id, int score) => GameResult(
  gameId: id,
  score: score,
  duration: const Duration(seconds: 60),
  startedAt: DateTime.utc(2026, 11, 3),
);

class _MemoryPendingRepository implements PendingGameRepository {
  final List<GameResult> values = [];

  @override
  Future<List<GameResult>> loadAll() async => List.of(values);

  @override
  Future<void> remove(String gameId) async {
    values.removeWhere((result) => result.gameId == gameId);
  }

  @override
  Future<void> save(GameResult result) async {
    if (!values.any((value) => value.gameId == result.gameId)) {
      values.add(result);
    }
  }
}

class _FakePlayerRepository implements PlayerRepository {
  bool fail = false;
  final Set<String> submittedIds = {};
  var games = 0;
  var highScore = 0;
  var totalScore = 0;

  @override
  Future<GameSubmission> submitGame(GameResult result) async {
    if (fail) throw Exception('offline');
    final duplicate = !submittedIds.add(result.gameId);
    final isNewHigh = !duplicate && result.score > highScore;
    if (!duplicate) {
      games++;
      totalScore += result.score;
      if (isNewHigh) highScore = result.score;
    }
    return GameSubmission(
      highScore: highScore,
      totalGames: games,
      totalScore: totalScore,
      isNewHighScore: isNewHigh,
      wasAlreadySubmitted: duplicate,
    );
  }

  @override
  Future<DashboardData> loadDashboard() => throw UnimplementedError();

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard({
    required int offset,
    required int limit,
  }) => throw UnimplementedError();

  @override
  Future<PlayerProfile> loadProfile() => throw UnimplementedError();

  @override
  Future<PlayerStats> loadStats() => throw UnimplementedError();

  @override
  Future<PlayerProfile> updateUsername(String username) =>
      throw UnimplementedError();

  @override
  Future<PlayerProfile> updateCharacterAvatar(
    Uint8List bytes, {
    required String contentType,
  }) => throw UnimplementedError();
}
