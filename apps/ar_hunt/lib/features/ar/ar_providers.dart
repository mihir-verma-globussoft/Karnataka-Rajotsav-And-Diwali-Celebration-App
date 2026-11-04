import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import 'data/audioplayers_hunt_sounds.dart';
import 'data/method_channel_ar_platform.dart';
import 'data/method_channel_ar_scene.dart';
import 'data/prefs_pending_finds_store.dart';
import 'data/supabase_hunt_repository.dart';
import 'domain/ar_availability.dart';
import 'domain/ar_platform.dart';
import 'domain/ar_scene.dart';
import 'domain/hunt_models.dart';
import 'domain/hunt_repository.dart';
import 'domain/hunt_rules.dart';

/// Override in tests with a fake [ArPlatform].
final arPlatformProvider = Provider<ArPlatform>(
  (ref) => MethodChannelArPlatform(),
);

final arAvailabilityProvider = FutureProvider.autoDispose<ArAvailability>(
  (ref) => ref.watch(arPlatformProvider).checkAvailability(),
);

/// Connects a native view, once created, to the Dart side.
final arSceneFactoryProvider = Provider<ArSceneController Function(int viewId)>(
  (ref) => MethodChannelArScene.new,
);

final huntRepositoryProvider = Provider<HuntRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase || !Supabase.instance.isInitialized) {
    return const UnconfiguredHuntRepository();
  }
  return SupabaseHuntRepository(Supabase.instance.client);
});

// Auto-dispose, so it never outlives a sign-in and credits the wrong player.
final pendingFindsProvider = Provider.autoDispose<PendingFindsStore>(
  (ref) => PrefsPendingFindsStore(
    ref.watch(huntRepositoryProvider).currentUserId ?? 'signed_out',
  ),
);

final huntSoundsProvider = Provider<HuntSounds>(
  (ref) => AudioplayersHuntSounds(),
);

/// Whether this build has the admin tools. Tests override it.
final huntAdminToolsProvider = Provider<bool>((ref) => huntAdminBuild);

/// Riverpod would otherwise quietly retry for about 38 seconds, leaving a player
/// with no connection on a spinner. The screens offer their own retry button.
Duration? _noRetry(int retryCount, Object error) => null;

/// Everything the hub shows. Sends any finds saved while offline first, and
/// counts the ones still waiting as found.
final huntSnapshotProvider = FutureProvider.autoDispose<HuntSnapshot>((
  ref,
) async {
  final repository = ref.watch(huntRepositoryProvider);
  final pending = ref.watch(pendingFindsProvider);
  await syncPendingFinds(repository, pending);
  final snapshot = await repository.load();
  final waiting = (await pending.load()).toSet();
  return HuntSnapshot(
    isAdmin: snapshot.isAdmin,
    isActive: snapshot.isActive,
    points: snapshot.points,
    rank: snapshot.rank,
    items: [
      for (final item in snapshot.items)
        waiting.contains(item.id) ? item.copyWith(found: true) : item,
    ],
  );
}, retry: _noRetry);

final huntLeadersProvider = FutureProvider.autoDispose<List<HuntLeader>>(
  (ref) => ref.watch(huntRepositoryProvider).leaders(),
  retry: _noRetry,
);
