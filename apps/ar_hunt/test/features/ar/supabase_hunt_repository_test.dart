import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ar_hunt/core/errors/app_failure.dart';
import 'package:ar_hunt/features/ar/data/supabase_hunt_repository.dart';
import 'package:ar_hunt/features/ar/domain/hunt_models.dart';
import 'package:ar_hunt/features/ar/domain/hunt_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Runs the real repository and the real Supabase client against a fake
/// network, so the RPC names and parameters are checked against the SQL.
void main() {
  late List<http.Request> requests;

  SupabaseHuntRepository repositoryAnswering(
    Future<http.Response> Function(http.Request request) answer,
  ) {
    requests = [];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await answer(request);
        // Real responses carry their request, and the client relies on that.
        return http.Response(
          response.body,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    return SupabaseHuntRepository(client);
  }

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  /// How PostgREST reports an exception raised in SQL.
  http.Response sqlError(String message, String code, [int status = 400]) =>
      json({
        'message': message,
        'code': code,
        'details': null,
        'hint': null,
      }, status);

  String rpcOf(http.Request request) => request.url.path.split('/').last;
  Map<String, dynamic> bodyOf(http.Request request) =>
      jsonDecode(request.body) as Map<String, dynamic>;

  group('talks to the RPCs in the migration', () {
    test('load combines the hunt state with the shared stats', () async {
      final repository = repositoryAnswering((request) async {
        return switch (rpcOf(request)) {
          'ar_hunt_state' => json({
            'is_admin': true,
            'is_active': true,
            'items': [
              {
                'id': 'i1',
                'zone': 'b',
                'kind': 'flag',
                'x': 1.5,
                'y': 0,
                'z': -2,
                'hint': 'Behind the plant',
                'found': true,
              },
            ],
          }),
          'get_my_stats' => json({
            'high_score': 25,
            'global_rank': 3,
            'total_games': 2,
            'total_score': 25,
          }),
          _ => json({'message': 'unexpected'}, 404),
        };
      });

      final snapshot = await repository.load();

      expect(snapshot.isAdmin, isTrue);
      expect(snapshot.points, 25);
      expect(snapshot.rank, 3);
      expect(snapshot.items.single.kind, HuntItemKind.flag);
      expect(snapshot.items.single.found, isTrue);
      final stats = requests.firstWhere((r) => rpcOf(r) == 'get_my_stats');
      expect(bodyOf(stats), {'p_game_slug': 'ar_hunt'});
    });

    test('a new player has no rank yet', () async {
      final repository = repositoryAnswering(
        (request) async => rpcOf(request) == 'ar_hunt_state'
            ? json({'is_admin': false, 'is_active': true, 'items': <Object>[]})
            : json({
                'high_score': 0,
                'global_rank': null,
                'total_games': 0,
                'total_score': 0,
              }),
      );
      final snapshot = await repository.load();
      expect(snapshot.rank, isNull);
      expect(snapshot.points, 0);
      expect(snapshot.items, isEmpty);
    });

    test('leaders ask the shared leaderboard for this game', () async {
      final repository = repositoryAnswering(
        (_) async => json([
          {
            'rank': 1,
            'user_id': 'u1',
            'username': 'Asha',
            'avatar_url': null,
            'high_score': 40,
          },
        ]),
      );
      final leaders = await repository.leaders(limit: 7);
      expect(leaders.single.username, 'Asha');
      expect(leaders.single.points, 40);
      expect(rpcOf(requests.single), 'get_leaderboard');
      expect(bodyOf(requests.single), {
        'p_game_slug': 'ar_hunt',
        'p_offset': 0,
        'p_limit': 7,
      });
    });

    test('collect sends the item and reads the result', () async {
      final repository = repositoryAnswering(
        (_) async => json({
          'points': 15,
          'first_finder': true,
          'already_found': false,
          'is_admin': false,
          'total_points': 40,
        }),
      );
      final result = await repository.collect('item-1');
      expect(result.points, 15);
      expect(result.firstFinder, isTrue);
      expect(rpcOf(requests.single), 'ar_collect_item');
      expect(bodyOf(requests.single), {'p_item_id': 'item-1'});
    });

    test('placing sends every field the SQL expects', () async {
      final repository = repositoryAnswering(
        (_) async => json({
          'id': 'new',
          'zone': 'c',
          'kind': 'diya',
          'x': 1,
          'y': 2,
          'z': 3,
          'hint': 'Near the door',
          'found': false,
        }),
      );
      final item = await repository.placeItem(
        zone: 'c',
        kind: HuntItemKind.diya,
        x: 1,
        y: 2,
        z: 3,
        hint: 'Near the door',
      );
      expect(item.id, 'new');
      expect(rpcOf(requests.single), 'ar_admin_place_item');
      expect(bodyOf(requests.single), {
        'p_zone': 'c',
        'p_kind': 'diya',
        'p_x': 1,
        'p_y': 2,
        'p_z': 3,
        'p_hint': 'Near the door',
      });
    });

    test('removing names the item', () async {
      final repository = repositoryAnswering(
        (_) async => http.Response('', 204),
      );
      await repository.removeItem('item-9');
      expect(rpcOf(requests.single), 'ar_admin_remove_item');
      expect(bodyOf(requests.single), {'p_item_id': 'item-9'});
    });

    test('unlocking reports whether the PIN was right', () async {
      final repository = repositoryAnswering((request) async {
        return json(bodyOf(request)['p_pin'] == '123456');
      });
      expect(await repository.unlockAdmin('000000'), isFalse);
      expect(await repository.unlockAdmin('123456'), isTrue);
      expect(rpcOf(requests.first), 'ar_admin_unlock');
    });
  });

  group('turns server refusals into something the app can act on', () {
    Future<void> collectWith(http.Response response) =>
        repositoryAnswering((_) async => response).collect('i');

    test('closed hunt', () async {
      await expectLater(
        collectWith(sqlError('hunt_closed', 'P0001')),
        throwsA(isA<HuntClosedException>()),
      );
    });

    test('removed item, which the live server sends as a 500', () async {
      await expectLater(
        collectWith(sqlError('item_not_found', 'P0002', 500)),
        throwsA(isA<HuntItemGoneException>()),
      );
    });

    test('finds coming too fast', () async {
      await expectLater(
        collectWith(sqlError('too_fast', 'P0001')),
        throwsA(isA<HuntTooFastException>()),
      );
    });

    test('too many wrong PINs gives a clear message', () async {
      final repository = repositoryAnswering(
        (_) async => sqlError('too_many_attempts', 'P0001'),
      );
      await expectLater(
        repository.unlockAdmin('000000'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (failure) => failure.message,
            'message',
            contains('10 minutes'),
          ),
        ),
      );
    });

    test('a server without the migration says so', () async {
      final repository = repositoryAnswering(
        (_) async => sqlError('Could not find the function', 'PGRST202', 404),
      );
      await expectLater(
        repository.load(),
        throwsA(
          isA<UnexpectedFailure>().having(
            (failure) => failure.message,
            'message',
            contains('not set up'),
          ),
        ),
      );
    });

    test('a refused admin action says who may do it', () async {
      final repository = repositoryAnswering(
        (_) async => sqlError('Administrator access required', '42501', 403),
      );
      await expectLater(
        repository.removeItem('i'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (failure) => failure.message,
            'message',
            contains('admins'),
          ),
        ),
      );
    });
  });

  group('having no connection always reads as a network problem', () {
    // The hub shows a failure's message, and only knows these as AppFailures.
    final failures = <String, Object>{
      'the http client failing': http.ClientException('Connection refused'),
      'a socket failing': const SocketException('No route to host'),
      'a timeout': TimeoutException('Took too long'),
      'a captive portal answering with HTML': const FormatException('<html>'),
    };

    for (final MapEntry(key: name, value: failure) in failures.entries) {
      test(name, () async {
        final repository = repositoryAnswering((_) async => throw failure);
        await expectLater(repository.leaders(), throwsA(isA<NetworkFailure>()));
      });
    }
  });
}
