import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/errors/app_failure.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/data/hunt_connection.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/data/main_app_player.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/data/supabase_hunt_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// The game keeps its data in its own database, so each player of the main app
/// quietly gets a player there. Runs the real Supabase client on a fake network.
void main() {
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request request) server;
  var nextUser = 0;

  String jwt(int expiresAt) {
    String part(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    return '${part({'alg': 'none'})}.${part({'exp': expiresAt, 'sub': 'x'})}.sig';
  }

  int inOneHour() => DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;

  Map<String, Object?> session(
    String userId, {
    int? expiresAt,
    String? refresh,
  }) {
    final expiry = expiresAt ?? inOneHour();
    return {
      'access_token': jwt(expiry),
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at': expiry,
      'refresh_token': refresh ?? 'refresh-$userId',
      'user': {
        'id': userId,
        'aud': 'authenticated',
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'created_at': '2026-11-04T00:00:00Z',
      },
    };
  }

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  SupabaseClient client() {
    final created = SupabaseClient(
      'https://hunt.supabase.co',
      'public-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await server(request);
        return http.Response(
          response.body,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    addTearDown(created.dispose);
    return created;
  }

  Iterable<http.Request> signups() =>
      requests.where((r) => r.url.path.endsWith('/auth/v1/signup'));

  Future<void> saveSession(String mainUser, Map<String, Object?> saved) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ar_hunt.session.$mainUser', jsonEncode(saved));
  }

  int expiredAt() => DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
    nextUser = 0;
    server = (request) async {
      if (request.url.path.endsWith('/auth/v1/signup')) {
        return json(session('hunt-user-${nextUser++}'));
      }
      fail('Unexpected request: ${request.url}');
    };
  });

  test('a new player joins under their main app name, once', () async {
    final hunt = client();
    final connection = HuntConnection(hunt, _FakePlayer('main-1', 'Sharuk'));

    await connection.ready();
    await connection.ready();

    expect(signups(), hasLength(1));
    final body = jsonDecode(signups().single.body) as Map<String, dynamic>;
    expect((body['data'] as Map<String, dynamic>)['name'], 'Sharuk');
    expect(hunt.auth.currentUser?.id, 'hunt-user-0');
  });

  test('calls made at the same moment still create one player', () async {
    final connection = HuntConnection(
      client(),
      _FakePlayer('main-1', 'Sharuk'),
    );
    await Future.wait([
      connection.ready(),
      connection.ready(),
      connection.ready(),
    ]);
    expect(signups(), hasLength(1));
  });

  test('the same player comes back after the app restarts', () async {
    await HuntConnection(client(), _FakePlayer('main-1', 'Sharuk')).ready();
    requests.clear();

    final restarted = client();
    await HuntConnection(restarted, _FakePlayer('main-1', 'Sharuk')).ready();

    expect(signups(), isEmpty, reason: 'points must not be lost on a restart');
    expect(restarted.auth.currentUser?.id, 'hunt-user-0');
  });

  test('an expired session is refreshed, and the new one is kept', () async {
    await saveSession('main-1', session('kept', expiresAt: expiredAt()));
    server = (request) async {
      expect(request.url.path, endsWith('/auth/v1/token'));
      return json(session('kept', refresh: 'new-refresh'));
    };

    final hunt = client();
    await HuntConnection(hunt, _FakePlayer('main-1', 'Sharuk')).ready();
    await pumpEventQueue();

    expect(hunt.auth.currentUser?.id, 'kept');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ar_hunt.session.main-1'), contains('new-refresh'));
  });

  test('no network never creates a second player', () async {
    final saved = session('kept', expiresAt: expiredAt());
    await saveSession('main-1', saved);
    server = (request) async => throw http.ClientException('No network');

    final connection = HuntConnection(
      client(),
      _FakePlayer('main-1', 'Sharuk'),
    );
    await expectLater(connection.ready(), throwsA(anything));

    expect(signups(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('ar_hunt.session.main-1'),
      jsonEncode(saved),
      reason: 'the player is still there when the network returns',
    );
  });

  test('a session the server has lost starts a new player', () async {
    await saveSession('main-1', session('gone', expiresAt: expiredAt()));
    server = (request) async {
      if (request.url.path.endsWith('/auth/v1/token')) {
        return json({
          'code': 400,
          'error_code': 'refresh_token_not_found',
          'msg': 'Invalid Refresh Token',
        }, 400);
      }
      return json(session('fresh'));
    };

    final hunt = client();
    await HuntConnection(hunt, _FakePlayer('main-1', 'Sharuk')).ready();

    expect(signups(), hasLength(1));
    expect(hunt.auth.currentUser?.id, 'fresh');
  });

  test('each main app account has its own player on a shared phone', () async {
    final player = _FakePlayer('main-1', 'Asha');
    final hunt = client();
    final connection = HuntConnection(hunt, player);

    await connection.ready();
    expect(hunt.auth.currentUser?.id, 'hunt-user-0');

    player
      ..id = 'main-2'
      ..displayName = 'Ravi';
    await connection.ready();
    expect(hunt.auth.currentUser?.id, 'hunt-user-1');

    requests.clear();
    player.id = 'main-1';
    await connection.ready();
    expect(hunt.auth.currentUser?.id, 'hunt-user-0');
    expect(signups(), isEmpty, reason: 'Asha comes back, not a new player');
  });

  test('nobody signed in to the main app means no player', () async {
    final connection = HuntConnection(client(), _FakePlayer(null, ''));
    await expectLater(connection.ready(), throwsA(isA<UnexpectedFailure>()));
    expect(requests, isEmpty);
  });

  group('the repository', () {
    test('connects before talking to the database', () async {
      final hunt = client();
      final connection = HuntConnection(hunt, _FakePlayer('main-1', 'Sharuk'));
      server = (request) async {
        if (request.url.path.endsWith('/auth/v1/signup')) {
          return json(session('hunt-user'));
        }
        return json(<Object>[]);
      };
      final repository = SupabaseHuntRepository(hunt, ready: connection.ready);

      expect(await repository.leaders(), isEmpty);

      expect(requests.first.url.path, endsWith('/auth/v1/signup'));
      expect(requests.last.url.path, endsWith('/rpc/get_leaderboard'));
      expect(repository.currentUserId, 'hunt-user');
    });

    test('joining with no network reads as a network problem', () async {
      server = (request) async => throw http.ClientException('No network');
      final hunt = client();
      final connection = HuntConnection(hunt, _FakePlayer('main-1', 'Sharuk'));
      final repository = SupabaseHuntRepository(hunt, ready: connection.ready);

      await expectLater(repository.leaders(), throwsA(isA<NetworkFailure>()));
    });
  });

  group('the name from the main app', () {
    Future<SupabaseClient> signedInMainClient(
      Map<String, Object?> metadata,
    ) async {
      final main = client();
      final saved = session('main-1');
      (saved['user']! as Map<String, Object?>)['user_metadata'] = metadata;
      await main.auth.recoverSession(jsonEncode(saved));
      requests.clear();
      return main;
    }

    test('nobody signed in has no id', () {
      expect(MainAppPlayer(client()).currentId, isNull);
    });

    test('comes from their profile first', () async {
      server = (request) async {
        expect(request.url.path, endsWith('/rest/v1/profiles'));
        return json({'username': 'Sharuk M'});
      };
      final player = MainAppPlayer(await signedInMainClient({}));
      expect(player.currentId, 'main-1');
      expect(await player.name(), 'Sharuk M');
    });

    test('falls back to their Google name if the profile fails', () async {
      server = (request) async => json({'message': 'nope', 'code': 'X'}, 500);
      final player = MainAppPlayer(
        await signedInMainClient({'full_name': 'Google Name'}),
      );
      expect(await player.name(), 'Google Name');
    });

    test('always has something to show', () async {
      server = (request) async => json({'message': 'nope', 'code': 'X'}, 500);
      final player = MainAppPlayer(await signedInMainClient({}));
      expect(await player.name(), 'Player');
    });
  });
}

class _FakePlayer implements HuntPlayerSource {
  _FakePlayer(this.id, this.displayName);

  String? id;
  String displayName;

  @override
  String? get currentId => id;

  @override
  Future<String> name() async => displayName;
}
