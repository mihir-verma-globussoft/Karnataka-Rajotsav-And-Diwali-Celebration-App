import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/config/app_config.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/game_result.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/player.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/player_repository.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/flappy_bird_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/flappy_bird_providers.dart';

void main() {
  const configured = AppConfig(
    environment: AppEnvironment.dev,
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'key',
  );

  Future<void> pump(
    WidgetTester tester, {
    required PlayerRepository repository,
    int? recent,
    AppConfig config = configured,
  }) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          playerRepositoryProvider.overrideWithValue(repository),
          recentScoreRepositoryProvider.overrideWithValue(
            _MemoryRecentScore(recent),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ArcadeScoresSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the player stats, recent score and the leaderboard', (
    tester,
  ) async {
    await pump(tester, repository: _Repository(), recent: 7);

    expect(find.text('Personal best'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
    expect(find.text('Games played'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('Total score'), findsOneWidget);
    expect(find.text('130'), findsOneWidget);
    expect(find.text('Recent score'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Global rank'), findsOneWidget);
    expect(find.text('#3'), findsWidgets);
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Me (You)'), findsOneWidget);
  });

  testWidgets('recent score is a dash before the first game', (tester) async {
    await pump(tester, repository: _Repository());
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('an unconfigured build explains instead of failing', (
    tester,
  ) async {
    await pump(
      tester,
      repository: _Repository(),
      config: const AppConfig(environment: AppEnvironment.dev),
    );
    expect(find.textContaining('Sign in with an account'), findsOneWidget);
  });

  test(
    'the submission service records the latest score even when offline',
    () async {
      final recent = _MemoryRecentScore(null);
      final service = ScoreSubmissionService(
        _Repository(failSubmit: true),
        _NoPending(),
        recentScores: recent,
      );
      final game = GameResult(
        gameId: '00000000-0000-4000-8000-000000000099',
        score: 21,
        duration: const Duration(seconds: 30),
        startedAt: DateTime.utc(2026, 11, 4),
      );
      await expectLater(service.submit(game), throwsA(isA<Exception>()));
      expect(await recent.load(), 21);
    },
  );
}

class _MemoryRecentScore implements RecentScoreRepository {
  _MemoryRecentScore(this.value);

  int? value;

  @override
  Future<int?> load() async => value;

  @override
  Future<void> save(int score) async => value = score;
}

class _NoPending implements PendingGameRepository {
  @override
  Future<List<GameResult>> loadAll() async => const [];

  @override
  Future<void> remove(String gameId) async {}

  @override
  Future<void> save(GameResult result) async {}
}

class _Repository implements PlayerRepository {
  _Repository({this.failSubmit = false});

  final bool failSubmit;

  @override
  Future<DashboardData> loadDashboard() async => DashboardData(
    profile: PlayerProfile(
      id: 'me',
      username: 'Me',
      createdAt: DateTime.utc(2026),
    ),
    stats: const PlayerStats(
      highScore: 42,
      totalGames: 9,
      totalScore: 130,
      globalRank: 3,
    ),
  );

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard({
    required int offset,
    required int limit,
  }) async => const [
    LeaderboardEntry(rank: 1, userId: 'a', username: 'Asha', highScore: 90),
    LeaderboardEntry(rank: 2, userId: 'b', username: 'Bala', highScore: 60),
    LeaderboardEntry(rank: 3, userId: 'me', username: 'Me', highScore: 42),
  ];

  @override
  Future<GameSubmission> submitGame(GameResult result) async =>
      failSubmit ? throw Exception('offline') : throw UnimplementedError();

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
