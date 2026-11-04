import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/deepavali_scores.dart';
import '../../domain/diya_game.dart';
import '../../domain/sound.dart';
import '../state/feedback.dart';
import '../state/game_notifier.dart';
import '../theme/diwali_palette.dart';
import '../widgets/celebration_burst.dart';
import '../widgets/diwali_button.dart';
import '../widgets/diwali_card.dart';
import '../widgets/diwali_motion.dart';
import '../widgets/diya_art.dart';
import '../widgets/scoreboard_card.dart';
import '../widgets/section_header.dart';

/// "mm:ss" for a duration, rounding up so the display never shows 00:00 while
/// time remains.
String formatGameTime(Duration d, {bool roundUp = false}) {
  final totalSeconds = roundUp
      ? (d.inMilliseconds / 1000).ceil()
      : d.inMilliseconds ~/ 1000;
  final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// "24 s" / "24.5 s" for results.
String formatResultTime(Duration d) {
  final tenths = (d.inMilliseconds / 100).round();
  final whole = tenths ~/ 10;
  final frac = tenths % 10;
  return frac == 0 ? '$whole s' : '$whole.$frac s';
}

/// One-line rules for a difficulty, shown on the start screen.
String difficultyBlurb(DiyaDifficulty d, {required bool relaxed}) {
  const n = DiyaGame.diyaCount;
  if (relaxed) {
    return 'Light all $n diyas at once, at your own pace. No timer, no wind.';
  }
  final seconds = d.limit.inSeconds;
  return switch (d) {
    DiyaDifficulty.gentle => 'No wind. Light all $n diyas in $seconds seconds.',
    DiyaDifficulty.breezy =>
      'Gusts blow out one diya at a time, so keep relighting. Have all $n '
          'glowing at once within $seconds seconds. A shaking diya is next: '
          'tap it to shield it.',
    DiyaDifficulty.stormy =>
      'Faster, fiercer gusts. Have all $n glowing at once within $seconds '
          'seconds. Tap the shaking diya in time to shield it.',
  };
}

/// Inline mini-game: keep every diya lit at once while the wind tries to
/// blow them out.
class DiyaGameSection extends ConsumerStatefulWidget {
  const DiyaGameSection({super.key});

  @override
  ConsumerState<DiyaGameSection> createState() => _DiyaGameSectionState();
}

class _DiyaGameSectionState extends ConsumerState<DiyaGameSection> {
  void _tap(int index) {
    final result = ref.read(diyaGameProvider.notifier).tap(index);
    final feedback = ref.read(diwaliFeedbackProvider);
    switch (result) {
      case DiyaTap.none:
        break;
      case DiyaTap.lit:
        if (ref.read(diyaGameProvider).isWin) {
          feedback.both(Haptic.medium, Sfx.win);
        } else {
          feedback.both(Haptic.light, Sfx.diyaLight);
        }
      case DiyaTap.shielded:
        feedback.both(Haptic.selection, Sfx.tap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = DiwaliMotion.of(context);
    // Only the phase: the game state changes ten times a second while playing,
    // and each part below watches just the piece it shows.
    final phase = ref.watch(diyaGameProvider.select((g) => g.phase));
    final notifier = ref.read(diyaGameProvider.notifier);

    // A gust putting a diya out is felt as well as seen.
    ref.listen<DiyaGame>(diyaGameProvider, (prev, next) {
      if (prev != null && next.blownOut > prev.blownOut) {
        ref.read(diwaliFeedbackProvider).both(Haptic.heavy, Sfx.gust);
      }
    });

    // Hidden tab or backgrounded app: pause. Resuming is always explicit.
    if (!motion.active && phase == DiyaGamePhase.playing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifier.pause();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Light the Diyas',
          subtitle: 'Keep every diya glowing at once. Beat the wind!',
        ),
        const SizedBox(height: AppSpacing.md),
        DiwaliCard(
          child: switch (phase) {
            DiyaGamePhase.ready => const _Ready(),
            DiyaGamePhase.playing ||
            DiyaGamePhase.paused => _Playing(onTap: _tap),
            DiyaGamePhase.complete || DiyaGamePhase.timeUp => const _Result(),
          },
        ),
      ],
    );
  }
}

class _Ready extends ConsumerWidget {
  const _Ready();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(diyaGameProvider);
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(diyaGameProvider.notifier);
    final best = ref.watch(diyaBestProvider).value?[game.difficulty];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Difficulty',
          container: true,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final d in DiyaDifficulty.values)
                ChoiceChip(
                  label: Text(d.label),
                  selected: d == game.difficulty,
                  onSelected: (_) => notifier.setDifficulty(d),
                  showCheckmark: false,
                  selectedColor: DiwaliPalette.gold.withValues(
                    alpha: AppOpacity.subtle,
                  ),
                  side: BorderSide(
                    color: d == game.difficulty
                        ? DiwaliPalette.gold
                        : DiwaliPalette.goldBorder,
                  ),
                  labelStyle: text.labelLarge?.copyWith(
                    color: d == game.difficulty
                        ? DiwaliPalette.gold
                        : DiwaliPalette.cream,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          difficultyBlurb(game.difficulty, relaxed: game.relaxed),
          style: text.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        _DiyaGrid(game: game, onTap: null),
        const SizedBox(height: AppSpacing.md),
        Text(
          best == null ? 'Best: —' : 'Best: ${formatResultTime(best)}',
          style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Relaxed mode (no timer, no wind)',
            style: text.bodyMedium,
          ),
          value: game.relaxed,
          activeThumbColor: DiwaliPalette.gold,
          onChanged: (v) => notifier.setRelaxed(value: v),
        ),
        const SizedBox(height: AppSpacing.sm),
        DiwaliButton(
          label: 'Start',
          icon: Icons.play_arrow,
          onPressed: notifier.start,
        ),
      ],
    );
  }
}

class _Playing extends ConsumerWidget {
  const _Playing({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(diyaGameProvider.notifier);
    final paused = ref.watch(
      diyaGameProvider.select((g) => g.phase == DiyaGamePhase.paused),
    );
    final hasWind = ref.watch(diyaGameProvider.select((g) => g.hasWind));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Hud(),
        if (hasWind) ...[
          const SizedBox(height: AppSpacing.sm),
          const _WindBanner(),
        ],
        const SizedBox(height: AppSpacing.md),
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: paused ? AppOpacity.disabled : 1,
              child: IgnorePointer(
                ignoring: paused,
                child: _Board(onTap: onTap),
              ),
            ),
            if (paused)
              Semantics(
                header: true,
                child: Text(
                  'Paused',
                  style: text.headlineSmall?.copyWith(
                    color: DiwaliPalette.gold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (paused)
              DiwaliButton(
                label: 'Resume',
                icon: Icons.play_arrow,
                onPressed: notifier.resume,
              )
            else
              DiwaliButton(
                label: 'Pause',
                icon: Icons.pause,
                kind: DiwaliButtonKind.secondary,
                onPressed: notifier.pause,
              ),
            DiwaliButton(
              label: 'Restart',
              icon: Icons.restart_alt,
              kind: DiwaliButtonKind.tertiary,
              onPressed: notifier.restart,
            ),
          ],
        ),
      ],
    );
  }
}

/// Seconds to show: time left, or time played in relaxed mode. Whole seconds,
/// so the clock changes once a second, not ten times.
int _shownSeconds(DiyaGame g) {
  final remaining = g.remaining;
  return remaining == null
      ? g.elapsed.inSeconds
      : (remaining.inMilliseconds / 1000).ceil();
}

/// The clock, the counter and the progress bar. Rebuilds when the second or
/// the number of lit diyas changes, not on every tick.
class _Hud extends ConsumerWidget {
  const _Hud();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    ref.watch(
      diyaGameProvider.select((g) => (_shownSeconds(g), g.litCount, g.relaxed)),
    );
    final game = ref.read(diyaGameProvider);
    final remaining = game.remaining;
    final shownSeconds = _shownSeconds(game);
    final timeText = remaining == null
        ? formatGameTime(game.elapsed)
        : formatGameTime(remaining, roundUp: true);
    final announce =
        remaining != null &&
        const {30, 10, 5}.contains(shownSeconds) &&
        game.isRunning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            Semantics(
              label: remaining == null
                  ? 'Time played: $shownSeconds seconds'
                  : 'Time left: $shownSeconds seconds',
              liveRegion: announce,
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: DiwaliPalette.gold,
                    size: AppIconSizes.md,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    timeText,
                    style: text.titleLarge?.copyWith(
                      color: DiwaliPalette.cream,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: '${game.litCount} of ${DiyaGame.diyaCount} diyas lit',
              liveRegion: true,
              excludeSemantics: true,
              child: Text(
                '${game.litCount} / ${DiyaGame.diyaCount} lit',
                style: text.titleLarge?.copyWith(color: DiwaliPalette.gold),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.smAll,
          child: LinearProgressIndicator(
            value: game.litCount / DiyaGame.diyaCount,
            minHeight: AppSizes.progressBar,
            color: DiwaliPalette.gold,
            backgroundColor: DiwaliPalette.goldBorder,
          ),
        ),
      ],
    );
  }
}

/// The 12 diyas. Rebuilds only when a diya lights, goes out, is warned or is
/// shielded.
class _Board extends ConsumerWidget {
  const _Board({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      diyaGameProvider.select((g) => (g.litMask, g.warning, g.shielded)),
    );
    return _DiyaGrid(game: ref.read(diyaGameProvider), onTap: onTap);
  }
}

/// Tells the player what the wind is doing. All three messages are laid out
/// at once (only one visible) so the board never jumps under a finger.
class _WindBanner extends ConsumerWidget {
  const _WindBanner();

  static const String calm = 'Calm… for now';
  static const String incoming = 'Gust coming! Tap the shaking diya';
  static const String shielded = 'Shielded!';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final current = ref.watch(
      diyaGameProvider.select(
        (g) => g.warning == null ? calm : (g.shielded ? shielded : incoming),
      ),
    );

    Widget line(String message, Color color, IconData icon) => Visibility(
      visible: current == message,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Row(
        children: [
          Icon(icon, color: color, size: AppIconSizes.sm),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: text.labelLarge?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: switch (current) {
        incoming => 'Wind gust coming. Tap the shaking diya to shield it.',
        shielded => 'Diya shielded from the wind.',
        _ => 'Wind is calm for now.',
      },
      liveRegion: true,
      excludeSemantics: true,
      child: Stack(
        children: [
          line(calm, DiwaliPalette.creamMuted, Icons.air),
          line(incoming, DiwaliPalette.saffron, Icons.air),
          line(shielded, DiwaliPalette.success, Icons.shield),
        ],
      ),
    );
  }
}

class _Result extends ConsumerWidget {
  const _Result();

  /// Height of the area the celebration sparks play in.
  static const double _burstHeight = 140;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final motion = DiwaliMotion.of(context);
    final notifier = ref.read(diyaGameProvider.notifier);
    final game = ref.watch(diyaGameProvider);
    final best = ref.watch(diyaBestProvider).value?[game.difficulty];
    final win = game.isWin;
    final headline = win
        ? 'All ${DiyaGame.diyaCount} diyas are glowing!'
        : 'Time’s up! ${game.litCount} / ${DiyaGame.diyaCount} lit';
    final windy = game.hasWind;
    final stats = [
      if (windy) 'Blown out ${game.blownOut}×',
      if (windy) 'Shielded ${game.shields}×',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (win)
          SizedBox(
            height: _burstHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (motion.animate)
                  const Positioned.fill(child: CelebrationBurst())
                else
                  const Icon(
                    Icons.check_circle,
                    color: DiwaliPalette.success,
                    size: AppIconSizes.hero,
                  ),
                if (motion.animate)
                  const Icon(
                    Icons.auto_awesome,
                    color: DiwaliPalette.gold,
                    size: AppIconSizes.xl,
                  ),
              ],
            ),
          ),
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            headline,
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(
              color: win ? DiwaliPalette.gold : DiwaliPalette.cream,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          win
              ? (game.relaxed
                    ? 'Finished in ${formatResultTime(game.elapsed)}.'
                    : '${game.difficulty.label} · '
                          '${formatResultTime(game.elapsed)}'
                          '${best == null ? '' : ' · Best: ${formatResultTime(best)}'}')
              : (windy
                    ? 'The wind won this time. Try again.'
                    : 'So close. Give it another go.'),
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(color: DiwaliPalette.creamMuted),
        ),
        if (stats.isNotEmpty)
          Text(
            stats,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
          ),
        const SizedBox(height: AppSpacing.md),
        if (win && !game.relaxed) ...[
          ScoreboardCard(game: DeepavaliGame.diya, saving: notifier.saving),
          const SizedBox(height: AppSpacing.md),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            DiwaliButton(
              label: win ? 'Play again' : 'Try again',
              icon: Icons.replay,
              onPressed: notifier.restart,
            ),
            DiwaliButton(
              label: 'Change level',
              kind: DiwaliButtonKind.tertiary,
              onPressed: notifier.toReady,
            ),
          ],
        ),
      ],
    );
  }
}

/// The 12 diyas: 3 columns on narrow widths, otherwise 4. Cells are square so
/// no height depends on text.
class _DiyaGrid extends StatelessWidget {
  const _DiyaGrid({required this.game, required this.onTap});

  final DiyaGame game;

  /// Null makes the grid a non-interactive preview.
  final ValueChanged<int>? onTap;

  /// Below this available width the grid uses three columns.
  static const double _narrow = 280;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < _narrow ? 3 : 4;
      final rows = (DiyaGame.diyaCount / columns).ceil();
      return Column(
        children: [
          for (var r = 0; r < rows; r++) ...[
            if (r > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _DiyaCell(
                        index: r * columns + c,
                        lit: game.isLit(r * columns + c),
                        threatened: game.isThreatened(r * columns + c),
                        shielded: game.isShielded(r * columns + c),
                        onTap: onTap,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    },
  );
}

class _DiyaCell extends StatelessWidget {
  const _DiyaCell({
    required this.index,
    required this.lit,
    required this.threatened,
    required this.shielded,
    required this.onTap,
  });

  final int index;
  final bool lit;

  /// A gust is about to put this diya out.
  final bool threatened;

  /// This diya has been shielded from the coming gust.
  final bool shielded;
  final ValueChanged<int>? onTap;

  /// Flame shake while a gust is coming.
  static const double _shake = 3;

  @override
  Widget build(BuildContext context) {
    final motion = DiwaliMotion.of(context);
    final number = index + 1;
    final art = LayoutBuilder(
      builder: (context, c) => TweenAnimationBuilder<double>(
        tween: Tween<double>(end: lit ? 1 : 0),
        duration: motion.reduceMotion ? Duration.zero : AppDurations.fast,
        curve: Curves.easeOutBack,
        builder: (context, ignite, _) => Center(
          child: DiyaArt(
            width: c.maxWidth * 0.8,
            ignite: ignite,
            clock: (lit || ignite > 0) && motion.animate ? motion.clock : null,
            agitation: threatened ? _shake : 1,
          ),
        ),
      ),
    );
    final borderColor = threatened
        ? DiwaliPalette.saffron
        : shielded
        ? DiwaliPalette.success
        : lit
        ? DiwaliPalette.gold
        : DiwaliPalette.goldBorder;
    // The warning is also shown with an icon, so it never relies on motion.
    final cell = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        color: lit
            ? DiwaliPalette.maroon.withValues(alpha: AppOpacity.strong)
            : DiwaliPalette.night.withValues(alpha: AppOpacity.strong),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: art),
          if (threatened || shielded)
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Icon(
                threatened ? Icons.air : Icons.shield,
                color: borderColor,
                size: AppIconSizes.xs,
              ),
            ),
        ],
      ),
    );
    final tap = onTap;
    if (tap == null) {
      return ExcludeSemantics(child: cell);
    }
    final canTap = !lit || threatened;
    final state = threatened
        ? 'lit, in danger from the wind. Double tap to shield'
        : shielded
        ? 'lit and shielded'
        : lit
        ? 'lit'
        : 'unlit. Double tap to light';
    return Semantics(
      button: true,
      label: 'Diya $number of ${DiyaGame.diyaCount}, $state',
      excludeSemantics: true,
      onTap: canTap ? () => tap(index) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canTap ? () => tap(index) : null,
        child: cell,
      ),
    );
  }
}
