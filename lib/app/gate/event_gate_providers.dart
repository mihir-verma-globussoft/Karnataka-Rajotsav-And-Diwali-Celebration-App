import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/global_auth_providers.dart';
import '../providers.dart';
import 'data/event_gate_repository.dart';
import 'domain/event_gate_models.dart';
import 'services/countdown_sync_service.dart';

final eventGateRepositoryProvider = Provider<EventGateRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase || !Supabase.instance.isInitialized) {
    return const FallbackEventGateRepository();
  }
  return SupabaseEventGateRepository(Supabase.instance.client);
});

final countdownSyncServiceProvider = Provider<CountdownSyncService>((ref) {
  final repository = ref.watch(eventGateRepositoryProvider);
  final service = CountdownSyncService(repository: repository);
  ref.onDispose(service.dispose);
  return service;
});

final eventGateStatusProvider = StreamProvider<EventGateStatus>((ref) {
  final service = ref.watch(countdownSyncServiceProvider);
  return service.statusStream;
});

/// Resolves the comprehensive root-level application access state.
final applicationAccessStateProvider = Provider<ApplicationAccessState>((ref) {
  final config = ref.watch(appConfigProvider);

  // If unconfigured in dev/test, bypass gate to keep local dev and widget tests passing
  if (!config.hasSupabase || !config.hasGoogleAuth) {
    return config.isProd
        ? ApplicationAccessState.eventInactive
        : ApplicationAccessState.authenticatedEventStarted;
  }

  // 1. Check Authentication
  final authState = ref.watch(globalAuthStateProvider);
  final player = authState.asData?.value;
  if (player == null) {
    return ApplicationAccessState.unauthenticated;
  }

  // 2. Check Player Character Avatar
  if (!player.hasCharacterAvatar) {
    return ApplicationAccessState.authenticatedWithoutAvatar;
  }

  // 3. Check Event Configuration & Countdown Status
  final gateStatus =
      ref.watch(eventGateStatusProvider).asData?.value ??
      ref.watch(countdownSyncServiceProvider).currentStatus;

  if (gateStatus == null) {
    // Initial fetch in progress
    return ApplicationAccessState.authenticatedEventWaiting;
  }

  if (!gateStatus.isActive) {
    return ApplicationAccessState.eventInactive;
  }

  if (gateStatus.isStarted) {
    return ApplicationAccessState.authenticatedEventStarted;
  }

  return ApplicationAccessState.authenticatedEventWaiting;
});
