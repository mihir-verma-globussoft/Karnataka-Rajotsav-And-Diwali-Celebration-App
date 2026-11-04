import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../../auth/global_auth_providers.dart';
import '../../auth/presentation/global_avatar_setup_view.dart';
import '../../auth/presentation/global_login_view.dart';
import '../../providers.dart';
import '../domain/event_gate_models.dart';
import '../event_gate_providers.dart';
import 'event_unavailable_view.dart';
import 'global_countdown_view.dart';

/// Root-level application entry gate.
/// Governs access across the entire app before rendering any main application
/// shell or feature module.
class GlobalApplicationAccessGate extends ConsumerWidget {
  const GlobalApplicationAccessGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    // Development fallback when credentials are not configured
    if (!config.hasSupabase || !config.hasGoogleAuth) {
      return config.isProd
          ? const Scaffold(body: SafeArea(child: EventUnavailableView()))
          : child;
    }

    final authAsync = ref.watch(globalAuthStateProvider);

    return authAsync.when(
      loading: () => const Scaffold(body: SafeArea(child: LoadingView())),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: ErrorView(
            error: error,
            onRetry: () => ref.invalidate(globalAuthStateProvider),
          ),
        ),
      ),
      data: (player) {
        // 1. Unauthenticated: Show Google Sign-In
        if (player == null) {
          return const GlobalLoginView();
        }

        // 2. Authenticated but missing avatar: Show Avatar Setup
        if (!player.hasCharacterAvatar) {
          return Scaffold(
            body: SafeArea(
              child: GlobalAvatarSetupView(
                player: player,
                onComplete: (_) {
                  ref.invalidate(globalAuthStateProvider);
                },
              ),
            ),
          );
        }

        // 3. Resolve Event Status (Countdown or Unlocked)
        final accessState = ref.watch(applicationAccessStateProvider);

        return switch (accessState) {
          ApplicationAccessState.unauthenticated => const GlobalLoginView(),
          ApplicationAccessState.authenticatedWithoutAvatar => Scaffold(
            body: SafeArea(
              child: GlobalAvatarSetupView(
                player: player,
                onComplete: (_) {
                  ref.invalidate(globalAuthStateProvider);
                },
              ),
            ),
          ),
          ApplicationAccessState.authenticatedEventWaiting =>
            GlobalCountdownView(player: player),
          ApplicationAccessState.eventInactive => const Scaffold(
            body: SafeArea(child: EventUnavailableView()),
          ),
          ApplicationAccessState.authenticatedEventStarted => child,
        };
      },
    );
  }
}
