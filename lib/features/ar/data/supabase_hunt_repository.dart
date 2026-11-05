import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/hunt_models.dart';
import '../domain/hunt_repository.dart';

/// Talks to the RPCs in `supabase/migrations/202611040004_ar_hunt.sql` and the
/// shared `get_my_stats` and `get_leaderboard`.
class SupabaseHuntRepository implements HuntRepository {
  const SupabaseHuntRepository(this._client);

  static const _gameSlug = 'ar_hunt';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<HuntSnapshot> load() => _guard(() async {
    final values = await Future.wait<dynamic>([
      _client.rpc<dynamic>('ar_hunt_state'),
      _client.rpc<dynamic>('get_my_stats', params: {'p_game_slug': _gameSlug}),
    ]);
    final state = Map<String, dynamic>.from(values[0] as Map);
    final stats = Map<String, dynamic>.from(values[1] as Map);
    return HuntSnapshot(
      isAdmin: state['is_admin'] as bool,
      isActive: state['is_active'] as bool,
      items: [
        for (final item in state['items'] as List<dynamic>)
          HuntItem.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      points: (stats['high_score'] as num?)?.toInt() ?? 0,
      rank: (stats['global_rank'] as num?)?.toInt(),
    );
  });

  @override
  Future<List<HuntLeader>> leaders({int limit = 50}) => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_leaderboard',
      params: {'p_game_slug': _gameSlug, 'p_offset': 0, 'p_limit': limit},
    );
    return [
      for (final row in rows)
        HuntLeader.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  });

  @override
  Future<CollectResult> collect(String itemId) => _guard(() async {
    final dynamic row = await _client.rpc<dynamic>(
      'ar_collect_item',
      params: {'p_item_id': itemId},
    );
    return CollectResult.fromJson(Map<String, dynamic>.from(row as Map));
  });

  @override
  Future<bool> unlockAdmin(String pin) => _guard(
    () => _client.rpc<bool>('ar_admin_unlock', params: {'p_pin': pin}),
  );

  @override
  Future<HuntItem> placeItem({
    required String zone,
    required HuntItemKind kind,
    required double x,
    required double y,
    required double z,
    String? hint,
    double scale = 1,
  }) => _guard(() async {
    try {
      return await _place(zone, kind, x, y, z, hint, scale);
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST202' || scale == 1) rethrow;
      throw UnexpectedFailure(
        'This server cannot save sizes yet. Set the size to 100% and save.',
        error,
      );
    }
  });

  Future<HuntItem> _place(
    String zone,
    HuntItemKind kind,
    double x,
    double y,
    double z,
    String? hint,
    double scale,
  ) async {
    final dynamic row = await _client.rpc<dynamic>(
      'ar_admin_place_item',
      params: {
        'p_zone': zone,
        'p_kind': kind.name,
        'p_x': x,
        'p_y': y,
        'p_z': z,
        'p_hint': hint,
        // Only when it matters, so a database without migration 202611050003
        // still saves items at the standard size.
        if (scale != 1) 'p_scale': scale,
      },
    );
    return HuntItem.fromJson(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<void> removeItem(String itemId) => _guard(
    () => _client.rpc<void>(
      'ar_admin_remove_item',
      params: {'p_item_id': itemId},
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (error) {
      throw _translate(error);
    } on AppFailure {
      rethrow;
    } on AuthRetryableFetchException catch (error) {
      throw NetworkFailure('Check your connection and try again.', error);
    } on AuthException catch (error) {
      throw UnexpectedFailure('Please sign in again.', error);
    } on Exception catch (error) {
      // The network stack fails in many ways, and an office Wi-Fi login page
      // answers with HTML. They all mean the same thing to a player.
      throw NetworkFailure('Check your connection and try again.', error);
    }
  }

  Exception _translate(PostgrestException error) {
    switch (error.message) {
      case 'hunt_closed':
        return const HuntClosedException();
      case 'item_not_found':
        return const HuntItemGoneException();
      case 'too_fast':
        return const HuntTooFastException();
      case 'too_many_attempts':
        return UnexpectedFailure(
          'Too many wrong tries. Please wait 10 minutes and try again.',
          error,
        );
    }
    // PostgREST's "no such function": the migration has not been applied.
    if (error.code == 'PGRST202') {
      return UnexpectedFailure(
        'The hunt is not set up on the server yet.',
        error,
      );
    }
    if (error.code == '42501') {
      return UnexpectedFailure('Only hunt admins can do that.', error);
    }
    return UnexpectedFailure('The hunt could not be updated.', error);
  }
}

/// Used when the build has no backend settings, so the screens can still say
/// so instead of crashing.
class UnconfiguredHuntRepository implements HuntRepository {
  const UnconfiguredHuntRepository();

  static const _failure = UnexpectedFailure(
    'This build is not connected to the hunt server.',
  );

  @override
  String? get currentUserId => null;

  @override
  Future<HuntSnapshot> load() async => throw _failure;

  @override
  Future<List<HuntLeader>> leaders({int limit = 50}) async => throw _failure;

  @override
  Future<CollectResult> collect(String itemId) async => throw _failure;

  @override
  Future<HuntItem> placeItem({
    required String zone,
    required HuntItemKind kind,
    required double x,
    required double y,
    required double z,
    String? hint,
    double scale = 1,
  }) async => throw _failure;

  @override
  Future<bool> unlockAdmin(String pin) async => throw _failure;

  @override
  Future<void> removeItem(String itemId) async => throw _failure;
}
