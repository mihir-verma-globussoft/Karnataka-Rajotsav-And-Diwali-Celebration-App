import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/arcade_tokens.dart';
import '../event_gate_providers.dart';

/// Shown when the event is inactive or temporarily disabled by administrators.
class EventUnavailableView extends ConsumerWidget {
  const EventUnavailableView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: FlappyPalette.night,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/auth/login_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        // Centred when it fits; scrolls on short screens and at large text.
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: FlappyPalette.panel.withValues(
                    alpha: ArcadeOpacity.panel,
                  ),
                  borderRadius: ArcadeRadius.panelAll,
                  border: Border.all(
                    color: FlappyPalette.festivalGold.withValues(
                      alpha: ArcadeOpacity.border,
                    ),
                    width: ArcadeSizes.goldBorder,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_busy_outlined,
                      color: FlappyPalette.festivalGold,
                      size: AppIconSizes.xl,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Celebration Paused',
                      style: TextStyle(
                        color: FlappyPalette.white,
                        fontSize: ArcadeText.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'The event is currently being scheduled or undergoing maintenance. Please check back shortly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FlappyPalette.white70,
                        fontSize: ArcadeText.body,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(countdownSyncServiceProvider).resync();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlappyPalette.gold,
                        foregroundColor: FlappyPalette.night,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
