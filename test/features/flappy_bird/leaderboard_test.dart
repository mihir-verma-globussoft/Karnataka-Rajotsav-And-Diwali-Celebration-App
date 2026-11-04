import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/game_result.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/player.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/player_repository.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/flappy_bird_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/presentation/leaderboard_page.dart';

void main() {
  final current = PlayerProfile(
    id: 'current',
    username: 'Current Player',
    createdAt: DateTime.utc(2026),
  );

  testWidgets('leaderboard renders rank order and highlights current player', (
    tester,
  ) async {
    final repository = _LeaderboardRepository([
      const LeaderboardEntry(
        rank: 1,
        userId: 'a',
        username: 'First',
        highScore: 90,
      ),
      const LeaderboardEntry(
        rank: 2,
        userId: 'b',
        username: 'Second',
        highScore: 80,
      ),
      const LeaderboardEntry(
        rank: 3,
        userId: 'c',
        username: 'Third',
        highScore: 70,
      ),
      const LeaderboardEntry(
        rank: 4,
        userId: 'current',
        username: 'Current Player',
        highScore: 60,
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [playerRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: LeaderboardView(currentPlayer: current)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Third'), findsOneWidget);
    expect(find.text('Current Player'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty leaderboard has a useful state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(
            _LeaderboardRepository([]),
          ),
        ],
        child: MaterialApp(home: LeaderboardView(currentPlayer: current)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Be the first player'), findsOneWidget);
  });
}

class _LeaderboardRepository implements PlayerRepository {
  _LeaderboardRepository(this.entries);

  final List<LeaderboardEntry> entries;

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard({
    required int offset,
    required int limit,
  }) async => entries.skip(offset).take(limit).toList();

  @override
  Future<DashboardData> loadDashboard() async => DashboardData(
    profile: PlayerProfile(
      id: 'current',
      username: 'Current Player',
      createdAt: DateTime.utc(2026),
    ),
    stats: const PlayerStats(
      highScore: 60,
      totalGames: 2,
      totalScore: 75,
      globalRank: 4,
    ),
  );

  @override
  Future<PlayerProfile> loadProfile() => throw UnimplementedError();

  @override
  Future<PlayerStats> loadStats() => throw UnimplementedError();

  @override
  Future<GameSubmission> submitGame(GameResult result) =>
      throw UnimplementedError();

  @override
  Future<PlayerProfile> updateUsername(String username) =>
      throw UnimplementedError();

  @override
  Future<PlayerProfile> updateCharacterAvatar(
    Uint8List bytes, {
    required String contentType,
  }) => throw UnimplementedError();
}
