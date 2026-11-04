import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/arcade_tokens.dart';
import '../../../features/flappy_bird/domain/player.dart';
import '../../../features/flappy_bird/flappy_bird_providers.dart';
import '../event_gate_providers.dart';

/// Global Diwali Countdown Entry Gate.
/// Uses the exact same visual assets, full-bleed poster background, and
/// festive design language as the login screen.
class GlobalCountdownView extends ConsumerWidget {
  const GlobalCountdownView({required this.player, super.key});

  final PlayerProfile player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateStatus =
        ref.watch(eventGateStatusProvider).asData?.value ??
        ref.watch(countdownSyncServiceProvider).currentStatus;

    final remaining = gateStatus?.remainingDuration ?? Duration.zero;

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    return Scaffold(
      backgroundColor: FlappyPalette.night,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final screenAspect = screenWidth / screenHeight;
          const imageAspect = 576.0 / 1024.0;

          final double renderedHeight;
          final double offsetY;
          if (screenAspect < imageAspect) {
            renderedHeight = screenHeight;
            offsetY = 0;
          } else {
            renderedHeight = screenWidth / imageAspect;
            offsetY = (screenHeight - renderedHeight) / 2;
          }

          // Keep the fixed-height countdown panel above the poster tagline
          // (which begins at roughly y=700 in the 576x1024 source image).
          final taglineTop = offsetY + (700.0 / 1024.0) * renderedHeight;
          final panelBottomLimit = (screenHeight - 190.0).clamp(
            0.0,
            screenHeight,
          );
          final panelTop = (taglineTop - 190.0).clamp(0.0, panelBottomLimit);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed background poster image (matching login screen)
              Positioned.fill(
                child: Image.asset(
                  'assets/auth/login_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // Compact signed-in user chip at the top right.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: (screenWidth - (AppSpacing.md * 2))
                              .clamp(0, 180)
                              .toDouble(),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: FlappyPalette.black.withValues(
                              alpha: ArcadeOpacity.scrim,
                            ),
                            borderRadius: AppRadius.lgAll,
                            border: Border.all(
                              color: FlappyPalette.white24,
                              width: ArcadeSizes.hairline,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: FlappyPalette.gold,
                                foregroundImage: player.displayAvatarUrl != null
                                    ? NetworkImage(player.displayAvatarUrl!)
                                    : null,
                                onForegroundImageError: (_, _) {},
                                child: Text(
                                  player.username.isEmpty
                                      ? '?'
                                      : player.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: ArcadeText.tiny,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: ArcadeSizes.chipGap),
                              Flexible(
                                child: Text(
                                  player.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: FlappyPalette.white,
                                    fontSize: ArcadeText.small,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: ArcadeSizes.tightGap),
                              IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: FlappyPalette.white70,
                                  size: ArcadeSizes.smallIcon,
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints(
                                  minWidth: ArcadeSizes.compactButton,
                                  minHeight: ArcadeSizes.compactButton,
                                ),
                                tooltip: 'Sign out',
                                onPressed: () async {
                                  await ref
                                      .read(flappyAuthRepositoryProvider)
                                      .signOut();
                                  ref.invalidate(flappyAuthStateProvider);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Countdown display anchored above the festival poster tagline.
              Positioned(
                top: panelTop,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: ArcadeSizes.countdownMaxWidth,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 4-Block Countdown Timer
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: FlappyPalette.panel.withValues(
                                  alpha: ArcadeOpacity.panelLight,
                                ),
                                borderRadius: AppRadius.lgAll,
                                border: Border.all(
                                  color: FlappyPalette.festivalGold.withValues(
                                    alpha: ArcadeOpacity.border,
                                  ),
                                  width: ArcadeSizes.goldBorder,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: FlappyPalette.glowSoft,
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'CELEBRATION OPENS IN',
                                    style: TextStyle(
                                      color: FlappyPalette.festivalGold,
                                      fontSize: ArcadeText.caption,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _TimeUnitCard(value: days, label: 'DAYS'),
                                      _TimeSeparator(),
                                      _TimeUnitCard(
                                        value: hours,
                                        label: 'HOURS',
                                      ),
                                      _TimeSeparator(),
                                      _TimeUnitCard(
                                        value: minutes,
                                        label: 'MINS',
                                      ),
                                      _TimeSeparator(),
                                      _TimeUnitCard(
                                        value: seconds,
                                        label: 'SECS',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            // Auto-unlock helper caption
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: FlappyPalette.black.withValues(
                                  alpha: ArcadeOpacity.scrimLight,
                                ),
                                borderRadius: AppRadius.mdAll,
                              ),
                              child: const Text(
                                'The celebration will unlock automatically when the timer reaches zero.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: FlappyPalette.white70,
                                  fontSize: ArcadeText.small,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimeUnitCard extends StatelessWidget {
  const _TimeUnitCard({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final formatted = value.toString().padLeft(2, '0');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: ArcadeSizes.countdownTileWidth,
          height: ArcadeSizes.countdownTileHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [FlappyPalette.tileTop, FlappyPalette.tileBottom],
            ),
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: FlappyPalette.gold.withValues(alpha: ArcadeOpacity.half),
              width: ArcadeSizes.hairline,
            ),
          ),
          child: Center(
            child: Text(
              formatted,
              style: const TextStyle(
                color: FlappyPalette.white,
                fontSize: ArcadeText.digit,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            color: FlappyPalette.festivalGold,
            fontSize: ArcadeText.unit,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Text(
      ':',
      style: TextStyle(
        color: FlappyPalette.festivalGold,
        fontSize: ArcadeText.title,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
