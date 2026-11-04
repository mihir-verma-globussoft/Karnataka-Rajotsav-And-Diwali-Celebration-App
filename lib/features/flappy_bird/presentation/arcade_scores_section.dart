import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/player.dart';
import '../flappy_bird_feature.dart';
import '../flappy_bird_providers.dart';
import 'widgets/arcade_widgets.dart';

/// The Flappy Bird arcade scoreboard for the Deepavali page: the player's own
/// numbers (the same stat cards as the arcade dashboard, plus their latest
/// score) and the top of the global leaderboard.
///
/// It lives here, with the data it reads, and is exposed through
/// `flappy_bird_feature.dart` — features may not import each other's internals.
class ArcadeScoresSection extends ConsumerWidget {
  const ArcadeScoresSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appConfigProvider).hasSupabase) {
      return const _Note('Sign in with an account to see your arcade scores.');
    }
    return ref
        .watch(dashboardProvider)
        .when(
          loading: () => const _Note('Loading your scores…'),
          error: (error, _) => _Note(
            error is AppFailure
                ? error.message
                : 'Your scores could not be loaded.',
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (dashboard) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Stats(stats: dashboard.stats),
              const SizedBox(height: AppSpacing.md),
              _Leaderboard(currentPlayerId: dashboard.profile.id),
              const SizedBox(height: AppSpacing.md),
              ArcadeActionButton(
                label: 'PLAY GAME',
                icon: Icons.play_arrow_rounded,
                primary: true,
                onPressed: () => context.push(FlappyBirdRoutes.game),
              ),
              const SizedBox(height: AppSpacing.xs),
              ArcadeActionButton(
                label: 'FULL LEADERBOARD',
                icon: Icons.leaderboard_outlined,
                onPressed: () => context.push(FlappyBirdRoutes.leaderboard),
              ),
            ],
          ),
        );
  }
}

class _Stats extends ConsumerWidget {
  const _Stats({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A missing value means no game has been played on this device yet.
    final recent = ref.watch(recentScoreProvider).asData?.value;
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.55,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StatCard(
              label: 'Personal best',
              value: '${stats.highScore}',
              icon: Icons.emoji_events_outlined,
            ),
            StatCard(
              label: 'Games played',
              value: '${stats.totalGames}',
              icon: Icons.sports_esports_outlined,
            ),
            StatCard(
              label: 'Total score',
              value: '${stats.totalScore}',
              icon: Icons.stars_outlined,
            ),
            StatCard(
              label: 'Recent score',
              value: recent == null ? '—' : '$recent',
              icon: Icons.history,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: StatCard(
            label: 'Global rank',
            value: stats.globalRank == null ? '—' : '#${stats.globalRank}',
            icon: Icons.military_tech_outlined,
            highlighted: true,
          ),
        ),
      ],
    );
  }
}

class _Leaderboard extends ConsumerWidget {
  const _Leaderboard({required this.currentPlayerId});

  final String currentPlayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return ArcadePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leaderboard',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          ref
              .watch(topLeaderboardProvider)
              .when(
                loading: () => const Text('Loading the leaderboard…'),
                error: (_, _) => TextButton.icon(
                  onPressed: () => ref.invalidate(topLeaderboardProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Could not load. Retry'),
                ),
                data: (entries) => entries.isEmpty
                    ? const Text('No scores yet. Be the first on the board!')
                    : Column(
                        children: [
                          for (final entry in entries)
                            _Row(
                              entry: entry,
                              isCurrent: entry.userId == currentPlayerId,
                            ),
                        ],
                      ),
              ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.isCurrent});

  final LeaderboardEntry entry;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: ArcadeSizes.rankWidth,
            child: Text(
              '#${entry.rank}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          PlayerAvatar(
            username: entry.username,
            avatarUrl: entry.avatarUrl,
            radius: AppIconSizes.sm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isCurrent ? '${entry.username} (You)' : entry.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text('${entry.highScore}', style: text.titleMedium),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.message, {this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ArcadePanel(
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
      ],
    ),
  );
}
