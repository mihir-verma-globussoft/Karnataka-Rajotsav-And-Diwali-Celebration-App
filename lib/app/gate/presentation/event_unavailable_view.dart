import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../event_gate_providers.dart';

/// Shown when the event is inactive or temporarily disabled by administrators.
class EventUnavailableView extends ConsumerWidget {
  const EventUnavailableView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: const Color(0xFF1B0B2E),
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
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF140728).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFFD166).withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_busy_outlined,
                    color: Color(0xFFFFD166),
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Celebration Paused',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'The event is currently being scheduled or undergoing maintenance. Please check back shortly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(countdownSyncServiceProvider).resync();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC94A),
                      foregroundColor: const Color(0xFF1B0B2E),
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
      ],
    ),
  );
}
