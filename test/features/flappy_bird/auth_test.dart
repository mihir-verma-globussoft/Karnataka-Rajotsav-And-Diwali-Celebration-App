import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/config/app_config.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/auth_repository.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/game_result.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/player.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/player_repository.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/flappy_bird_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/presentation/flappy_bird_page.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.dev,
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'publishable-key',
    googleWebClientId: 'web.apps.googleusercontent.com',
  );

  testWidgets('configured app root is blocked until Google sign-in', (
    tester,
  ) async {
    final auth = _FakeAuthRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          flappyAuthRepositoryProvider.overrideWithValue(auth),
        ],
        child: const MaterialApp(
          home: PlayerOnboardingGate(child: Text('PRIVATE APP ROOT')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('PRIVATE APP ROOT'), findsNothing);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE APP ROOT'), findsOneWidget);
  });

  testWidgets('existing session restores the player dashboard', (tester) async {
    final auth = _FakeAuthRepository(_player);
    addTearDown(auth.dispose);
    await _pump(tester, config, auth);
    expect(find.text('Current Player'), findsOneWidget);
    expect(find.text('Personal best'), findsOneWidget);
  });

  testWidgets('new player is asked for a camera character photo', (
    tester,
  ) async {
    final auth = _FakeAuthRepository(
      PlayerProfile(
        id: 'new-player',
        username: 'New Player',
        createdAt: DateTime.utc(2026),
      ),
    );
    addTearDown(auth.dispose);
    await _pump(tester, config, auth);
    expect(find.text('Create your character'), findsOneWidget);
    expect(find.text('TAKE PHOTO'), findsOneWidget);
    expect(find.textContaining('public leaderboard avatar'), findsOneWidget);
  });

  testWidgets('successful Google login opens the dashboard', (tester) async {
    final auth = _FakeAuthRepository();
    addTearDown(auth.dispose);
    await _pump(tester, config, auth);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Current Player'), findsOneWidget);
  });

  testWidgets('cancelled Google login remains signed out with feedback', (
    tester,
  ) async {
    final auth = _FakeAuthRepository()..cancelNext = true;
    addTearDown(auth.dispose);
    await _pump(tester, config, auth);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-in was cancelled.'), findsOneWidget);
  });

  testWidgets('logout returns to the login screen', (tester) async {
    final auth = _FakeAuthRepository(_player);
    addTearDown(auth.dispose);
    await _pump(tester, config, auth);
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  AppConfig config,
  AuthRepository auth,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        flappyAuthRepositoryProvider.overrideWithValue(auth),
        playerRepositoryProvider.overrideWithValue(_FakePlayerRepository()),
        pendingGameRepositoryProvider.overrideWithValue(_EmptyPending()),
      ],
      child: const MaterialApp(home: FlappyBirdPage()),
    ),
  );
  await tester.pumpAndSettle();
}

final _player = PlayerProfile(
  id: 'current',
  username: 'Current Player',
  email: 'player@example.com',
  characterAvatarUrl: 'https://example.com/player.jpg',
  createdAt: DateTime.utc(2026),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository([this._current]);

  final StreamController<PlayerProfile?> _events = StreamController.broadcast();
  PlayerProfile? _current;
  bool cancelNext = false;

  Future<void> dispose() => _events.close();

  @override
  Future<PlayerProfile?> currentPlayer() async => _current;

  @override
  Future<void> deleteAccount() async {
    _current = null;
    _events.add(null);
  }

  @override
  Future<PlayerProfile> signInWithGoogle() async {
    if (cancelNext) throw const AuthCancelledException();
    _current = _player;
    _events.add(_current);
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _events.add(null);
  }

  @override
  Stream<PlayerProfile?> watchPlayer() async* {
    yield _current;
    yield* _events.stream;
  }
}

class _FakePlayerRepository implements PlayerRepository {
  @override
  Future<DashboardData> loadDashboard() async => DashboardData(
    profile: _player,
    stats: const PlayerStats(
      highScore: 10,
      totalGames: 2,
      totalScore: 14,
      globalRank: 4,
    ),
  );

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard({
    required int offset,
    required int limit,
  }) async => [];

  @override
  Future<PlayerProfile> loadProfile() async => _player;

  @override
  Future<PlayerStats> loadStats() async => PlayerStats.zero;

  @override
  Future<GameSubmission> submitGame(GameResult result) =>
      throw UnimplementedError();

  @override
  Future<PlayerProfile> updateUsername(String username) async => _player;

  @override
  Future<PlayerProfile> updateCharacterAvatar(
    Uint8List bytes, {
    required String contentType,
  }) async => _player;
}

class _EmptyPending implements PendingGameRepository {
  @override
  Future<List<GameResult>> loadAll() async => [];

  @override
  Future<void> remove(String gameId) async {}

  @override
  Future<void> save(GameResult result) async {}
}
