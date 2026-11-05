import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/arcade_tokens.dart';
import '../domain/game_score.dart';
import '../flappy_bird_providers.dart';

/// The player's own scoreboard: one row per game with their best score and
/// the points it adds to the combined leaderboard, and the combined total.
class GameScoreboardSection extends ConsumerWidget {
  const GameScoreboardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(gameScoresProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: FlappyPalette.panel.withValues(alpha: ArcadeOpacity.panel),
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: FlappyPalette.white.withValues(alpha: ArcadeOpacity.hairline),
          width: ArcadeSizes.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'YOUR SCOREBOARD',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: FlappyPalette.white70,
              fontWeight: FontWeight.w800,
              letterSpacing: ArcadeText.labelSpacing,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          scores.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (error, _) => _Message(
              error is AppFailure
                  ? error.message
                  : 'Your game scores could not be loaded.',
              onRetry: () => ref.invalidate(gameScoresProvider),
            ),
            data: (rows) => rows.isEmpty
                ? const _Message('Play a game to start your scoreboard.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Tiles(scores: rows),
                      const SizedBox(height: AppSpacing.sm),
                      if (rows.every((row) => row.points != null))
                        _Total(
                          points: rows.fold(
                            0,
                            (sum, row) => sum + (row.points ?? 0),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Two games per row; a tile grows with its text, so nothing is clipped at
/// large text sizes.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.scores});

  final List<GameScore> scores;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - AppSpacing.xs) / 2;
      return Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final score in scores)
            SizedBox(
              width: width,
              child: _GameTile(score: score),
            ),
        ],
      );
    },
  );
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.score});

  final GameScore score;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final played = score.gamesPlayed > 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: FlappyPalette.sparkPink.withValues(
            alpha: ArcadeOpacity.hairline,
          ),
          width: ArcadeSizes.hairline,
        ),
        color: FlappyPalette.panel.withValues(alpha: ArcadeOpacity.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: ArcadeSizes.gameIconBox,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FlappyPalette.sparkPink.withValues(
                      alpha: ArcadeOpacity.splash,
                    ),
                  ),
                  child: Icon(
                    _iconFor(score.slug),
                    size: AppIconSizes.md,
                    color: FlappyPalette.festivalGold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${score.points ?? score.bestScore}',
                  textAlign: TextAlign.end,
                  style: text.headlineSmall?.copyWith(
                    color: FlappyPalette.festivalGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            score.name,
            style: text.titleSmall?.copyWith(
              color: FlappyPalette.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            !played
                ? 'Not played yet'
                : score.points == null
                ? '${score.gamesPlayed} played'
                : 'Best ${score.bestScore} · ${score.gamesPlayed} played',
            style: text.bodySmall?.copyWith(color: FlappyPalette.white70),
          ),
        ],
      ),
    );
  }
}

IconData _iconFor(String slug) => switch (slug) {
  'flappy_bird' => Icons.flutter_dash,
  'pacman' => Icons.sports_esports_rounded,
  'ar_hunt' => Icons.explore_rounded,
  'rajyotsava_quiz' => Icons.quiz_rounded,
  'deepavali_quiz' => Icons.help_center_rounded,
  'deepavali_guess' => Icons.psychology_alt_rounded,
  'deepavali_diya' => Icons.local_fire_department_rounded,
  _ => Icons.emoji_events_rounded,
};

class _Total extends StatelessWidget {
  const _Total({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Wraps onto two lines when the text is large, instead of overflowing.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        Text(
          'Combined score',
          style: text.titleMedium?.copyWith(
            color: FlappyPalette.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '$points pts',
          style: text.titleLarge?.copyWith(
            color: FlappyPalette.festivalGold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.message, {this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: FlappyPalette.white),
      ),
      if (onRetry != null)
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
    ],
  );
}
