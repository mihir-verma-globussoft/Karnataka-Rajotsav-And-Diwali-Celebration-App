import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_providers.dart';
import '../../domain/deepavali_scores.dart';
import '../theme/diwali_palette.dart';
import 'diwali_card.dart';

/// What the results screen of a Deepavali game shows about the online
/// leaderboard: whether this game was saved, the player's best and rank, and
/// the top players.
///
/// Shows nothing when this build has no leaderboard, nobody is signed in or
/// [saving] is null (a game that is not ranked).
class ScoreboardCard extends ConsumerStatefulWidget {
  const ScoreboardCard({required this.game, required this.saving, super.key});

  final DeepavaliGame game;

  /// The finished game being sent, from the game's notifier.
  final Future<ScoreSaveOutcome>? saving;

  @override
  ConsumerState<ScoreboardCard> createState() => _ScoreboardCardState();
}

typedef _Board = ({
  ScoreSaveOutcome outcome,
  ScoreStanding? standing,
  List<ScoreLeader> leaders,
});

class _ScoreboardCardState extends ConsumerState<ScoreboardCard> {
  /// Rows shown on the results screen.
  static const int _top = 5;

  late final Future<_Board?> _board = _load();

  Future<_Board?> _load() async {
    final saving = widget.saving;
    if (saving == null) return null;
    final outcome = await saving;
    if (!mounted) return null;
    if (outcome is ScoreSaved) {
      ref.read(arcadeScoreRevisionProvider.notifier).refresh();
    }
    if (outcome is ScoreNotSaved) return null;
    final scoreboard = ref.read(deepavaliScoreboardProvider);
    final (standing, leaders) = await (
      scoreboard.standing(widget.game),
      scoreboard.leaders(widget.game, limit: _top),
    ).wait;
    return (outcome: outcome, standing: standing, leaders: leaders);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.saving == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return FutureBuilder<_Board?>(
      future: _board,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: CircularProgressIndicator(color: DiwaliPalette.gold),
            ),
          );
        }
        final board = snapshot.data;
        if (board == null) return const SizedBox.shrink();
        final standing = board.standing;
        final status = switch (board.outcome) {
          ScoreSaved(isNewBest: true) => 'New personal best!',
          ScoreSaved() => 'Saved to the leaderboard.',
          ScoreQueued() =>
            'Saved on this phone. It will reach the leaderboard when you '
                'are back online.',
          ScoreNotSaved() => '',
        };
        return DiwaliCard(
          child: Column(
            key: ValueKey('scoreboard-${widget.game.slug}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Leaderboard · ${widget.game.title}',
                  style: text.titleMedium?.copyWith(color: DiwaliPalette.gold),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                liveRegion: true,
                child: Text(
                  status,
                  key: const ValueKey('scoreboard-status'),
                  style: text.bodyMedium?.copyWith(
                    color: board.outcome is ScoreSaved
                        ? DiwaliPalette.success
                        : DiwaliPalette.creamMuted,
                  ),
                ),
              ),
              if (standing != null && standing.rounds > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    'Your best: ${standing.best} points',
                    if (standing.rank case final rank?) 'Rank #$rank',
                    '${standing.rounds} '
                        '${standing.rounds == 1 ? 'game' : 'games'}',
                  ].join(' · '),
                  key: const ValueKey('scoreboard-standing'),
                  style: text.bodyMedium?.copyWith(color: DiwaliPalette.cream),
                ),
              ],
              if (board.leaders.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final leader in board.leaders) _LeaderRow(leader: leader),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.leader});

  final ScoreLeader leader;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final url = leader.avatarUrl;
    final name = leader.isYou ? '${leader.name} (you)' : leader.name;
    return Semantics(
      label: 'Rank ${leader.rank}, $name, ${leader.points} points',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: leader.isYou
              ? DiwaliPalette.gold.withValues(alpha: AppOpacity.faint)
              : null,
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppSizes.minTouchTarget,
              child: Text(
                '#${leader.rank}',
                style: text.titleSmall?.copyWith(
                  color: leader.rank <= 3
                      ? DiwaliPalette.gold
                      : DiwaliPalette.creamMuted,
                ),
              ),
            ),
            CircleAvatar(
              radius: AppIconSizes.md / 2 + AppSpacing.xs,
              backgroundColor: DiwaliPalette.surfaceHigh,
              foregroundImage: url == null ? null : NetworkImage(url),
              child: const Icon(
                Icons.person,
                size: AppIconSizes.sm,
                color: DiwaliPalette.creamMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodyLarge?.copyWith(
                  color: DiwaliPalette.cream,
                  fontWeight: leader.isYou ? FontWeight.bold : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${leader.points}',
              style: text.titleSmall?.copyWith(color: DiwaliPalette.cream),
            ),
          ],
        ),
      ),
    );
  }
}
