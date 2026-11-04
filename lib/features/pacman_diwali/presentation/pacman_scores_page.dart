import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/pacman_diwali_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/pacman_scoreboard.dart';
import '../pacman_providers.dart';
import 'diwali_sky.dart';

const Color _gold = PacmanColors.cFFFFD54F;
const Color _night = PacmanColors.cFF12002B;

/// The player's Pac-Man numbers (best, games, total, last score, global rank)
/// and the global leaderboard, like the Flappy Bird arcade.
class PacmanScoresPage extends ConsumerWidget {
  const PacmanScoresPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(pacmanStandingProvider)
      ..invalidate(pacmanLastScoreProvider)
      ..invalidate(pacmanLeadersProvider);
    await Future.wait([
      ref.read(pacmanLeadersProvider.future).then((_) {}, onError: (_) {}),
      ref.read(pacmanStandingProvider.future).then((_) {}, onError: (_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final board = ref.watch(pacmanScoreboardProvider);
    return Scaffold(
      backgroundColor: _night,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: PacmanColors.transparent,
        elevation: 0,
        foregroundColor: PacmanColors.white,
        title: const Text('Pac-Man scores'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DiwaliSky(toranTop: _toranTopBelowBar(context)),
          ),
          SafeArea(
            child: ConstrainedBody(
              child: !board.isAvailable
                  ? const _Note(
                      icon: Icons.account_circle_outlined,
                      message:
                          'Sign in with your account to save your scores '
                          'and join the leaderboard.',
                    )
                  : RefreshIndicator.adaptive(
                      onRefresh: () => _refresh(ref),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          const SizedBox(height: _toranClearance),
                          Text(
                            '🏆 Leaderboard 🏆',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: _gold,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  color: PacmanColors.deepOrange,
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _Stats(),
                          const SizedBox(height: AppSpacing.md),
                          const _Leaders(),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The toran hangs under the app bar, not behind its back button and title.
double Function(Size) _toranTopBelowBar(BuildContext context) {
  final top =
      MediaQuery.paddingOf(context).top + kToolbarHeight + PacmanSizes.toranGap;
  return (_) => top;
}

/// Room for the toran at the top of the scrolling content (the safe area
/// already clears the status bar).
const double _toranClearance = kToolbarHeight + PacmanSizes.toranBand;

class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standing = ref
        .watch(pacmanStandingProvider)
        .whenOrNull(data: (s) => s);
    final last = ref.watch(pacmanLastScoreProvider).whenOrNull(data: (s) => s);
    final stats = standing ?? PacmanStanding.empty;
    final rank = stats.rank;
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _StatCard(
              width: half,
              icon: Icons.emoji_events_outlined,
              value: '${stats.best}',
              label: 'Personal best',
            ),
            _StatCard(
              width: half,
              icon: Icons.sports_esports_outlined,
              value: '${stats.rounds}',
              label: 'Games played',
            ),
            _StatCard(
              width: half,
              icon: Icons.stars_outlined,
              value: '${stats.total}',
              label: 'Total score',
            ),
            _StatCard(
              width: half,
              icon: Icons.history,
              value: last == null ? '—' : '$last',
              label: 'Last score',
            ),
            _StatCard(
              width: constraints.maxWidth,
              icon: Icons.military_tech_outlined,
              value: rank == null ? '—' : '#$rank',
              label: 'Global rank',
              highlighted: true,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  final double width;
  final IconData icon;
  final String value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = highlighted ? _gold : PacmanColors.orangeAccent;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: highlighted ? PacmanColors.cCC4A1070 : PacmanColors.c99200040,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: highlighted ? _gold : PacmanColors.c88FFFFFF,
            width: highlighted ? PacmanSizes.highlightBorder : 0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: AppIconSizes.md),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: highlighted ? _gold : PacmanColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: highlighted ? _gold : PacmanColors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaders extends ConsumerWidget {
  const _Leaders();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(pacmanLeadersProvider)
      .when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(pacmanLeadersProvider),
        ),
        data: (leaders) => leaders.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: EmptyView(
                  message: 'No scores yet. Be the first on the board!',
                  icon: Icons.emoji_events_outlined,
                ),
              )
            : Column(
                children: [
                  for (final leader in leaders) ...[
                    _LeaderRow(leader: leader),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
      );
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.leader});

  final PacmanLeader leader;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = leader.avatarUrl;
    final rank = leader.rank;
    return Semantics(
      container: true,
      label:
          '${leader.isYou ? 'You, ' : ''}${leader.name}, rank $rank, '
          '${leader.points} diyas',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: leader.isYou
                ? PacmanColors.cCC4A1070
                : PacmanColors.c99200040,
            borderRadius: AppRadius.mdAll,
            border: leader.isYou
                ? Border.all(color: _gold, width: PacmanSizes.highlightBorder)
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: PacmanSizes.rankSlot,
                child: Text(
                  rank >= 1 && rank <= _medals.length
                      ? _medals[rank - 1]
                      : '#$rank',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CircleAvatar(
                radius: PacmanSizes.avatarRadius,
                foregroundImage: url == null ? null : NetworkImage(url),
                onForegroundImageError: url == null ? null : (_, _) {},
                child: Text(
                  leader.name.isEmpty
                      ? '?'
                      : leader.name.characters.first.toUpperCase(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  leader.isYou ? '${leader.name} (you)' : leader.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: PacmanColors.white,
                    fontWeight: leader.isYou
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '🪔 ${leader.points}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: PacmanColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: AppIconSizes.xl),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: PacmanColors.white70),
          ),
        ],
      ),
    ),
  );
}
