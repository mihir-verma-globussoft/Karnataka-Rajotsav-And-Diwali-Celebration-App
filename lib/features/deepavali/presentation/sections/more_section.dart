import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_providers.dart';
import '../../deepavali_routes.dart';
import '../../domain/content/destinations.dart';
import '../../domain/content/guess_objects.dart';
import '../../domain/festival_dates.dart';
import '../../domain/festival_status.dart';
import '../../domain/quiz_session.dart';
import '../../domain/recommendation.dart';
import '../../domain/sound.dart';
import '../../domain/wish.dart';
import '../state/feedback.dart';
import '../state/guess_notifier.dart';
import '../state/recommend_notifier.dart';
import '../state/wall_notifier.dart';
import '../theme/diwali_palette.dart';
import '../widgets/destination_image.dart';
import '../widgets/diwali_button.dart';
import '../widgets/diwali_card.dart';
import '../widgets/diwali_motion.dart';
import '../widgets/diwali_sheet.dart';
import '../widgets/diya_art.dart';
import '../widgets/object_art.dart';
import '../widgets/quiz_option_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/timeline_stepper.dart';
import '../widgets/wish_sheets.dart';
import 'countdown_section.dart' show formatCivilDate;

const List<String> _letters = ['A', 'B', 'C', 'D'];

/// Three extras: a wall of wishes, a silhouette guessing game and the
/// five-day timeline.
class MoreSection extends StatelessWidget {
  const MoreSection({this.dates = deepavaliDates, super.key});

  final FestivalDates dates;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader(
        title: 'More to Explore',
        subtitle: 'Wishes, games, timeline, photos and more',
      ),
      const SizedBox(height: AppSpacing.md),
      const _WallCard(),
      const SizedBox(height: AppSpacing.md),
      const _GuessCard(),
      const SizedBox(height: AppSpacing.md),
      _TimelineCard(dates: dates),
      const SizedBox(height: AppSpacing.md),
      const _RecommendCard(),
      const SizedBox(height: AppSpacing.md),
      const _LaunchCard(
        title: 'Decorate your home',
        description:
            'Add diyas, lanterns, garlands and rangoli to a house, drag them '
            'into place and share the picture.',
        buttonLabel: 'Start decorating',
        icon: Icons.home_outlined,
        route: DeepavaliRoutes.decorate,
      ),
      const SizedBox(height: AppSpacing.md),
      const _LaunchCard(
        title: 'Photo booth',
        description:
            'Take or choose a photo, add a Deepavali frame and share it. Your '
            'photo stays on this phone unless you share it.',
        buttonLabel: 'Open photo booth',
        icon: Icons.photo_camera_outlined,
        route: DeepavaliRoutes.photoBooth,
      ),
    ],
  );
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.titleMedium?.copyWith(
              color: DiwaliPalette.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

// ───────────────────────── Diya wall ─────────────────────────

/// Diyas shown on the card; the rest are in "View all".
const int _wallPreview = 12;

class _WallCard extends ConsumerWidget {
  const _WallCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final wall = ref.watch(wallProvider);
    final wishes = wall.value?.wishes ?? const <Wish>[];
    return DiwaliCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(
            'Virtual Diya Wall',
            subtitle:
                'Write a wish and light a diya. Your wall is saved on this '
                'phone only.',
          ),
          if (wall.isLoading)
            Text(
              'Opening your wall…',
              style: text.bodyLarge?.copyWith(color: DiwaliPalette.creamMuted),
            )
          else if (wishes.isEmpty)
            Text(
              'Light the first diya.',
              style: text.bodyLarge?.copyWith(color: DiwaliPalette.cream),
            )
          else ...[
            _WishGrid(wishes: wishes.take(_wallPreview).toList()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              wishes.length == 1 ? '1 wish' : '${wishes.length} wishes',
              style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              DiwaliButton(
                label: 'Light a diya',
                icon: Icons.local_fire_department_outlined,
                onPressed: () => unawaited(showAddWishSheet(context)),
              ),
              if (wishes.length > _wallPreview)
                DiwaliButton(
                  label: 'View all ${wishes.length}',
                  kind: DiwaliButtonKind.tertiary,
                  onPressed: () => unawaited(
                    showDiwaliSheet<void>(
                      context,
                      builder: (_) => _AllWishesSheet(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllWishesSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishes = ref.watch(wallProvider).value?.wishes ?? const <Wish>[];
    // Sheets open above the page, outside its motion scope, so this one
    // brings its own.
    return DiwaliMotionScope(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'All wishes (${wishes.length})',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: DiwaliPalette.gold),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _WishGrid(wishes: wishes),
          ],
        ),
      ),
    );
  }
}

class _WishGrid extends StatelessWidget {
  const _WishGrid({required this.wishes});

  final List<Wish> wishes;

  /// Narrowest a diya tile is allowed to be.
  static const double _minTile = 64;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = (c.maxWidth / (_minTile + AppSpacing.sm)).floor().clamp(
        4,
        6,
      );
      final tile = (c.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final wish in wishes)
            SizedBox.square(
              dimension: tile,
              child: _WishDiya(key: ValueKey(wish.id), wish: wish),
            ),
        ],
      );
    },
  );
}

class _WishDiya extends StatelessWidget {
  const _WishDiya({required this.wish, super.key});

  final Wish wish;

  @override
  Widget build(BuildContext context) {
    final motion = DiwaliMotion.of(context);
    return Semantics(
      button: true,
      label:
          'Wish: ${wish.text}${wish.from.isEmpty ? '' : ', from ${wish.from}'}. '
          'Double tap to read.',
      excludeSemantics: true,
      onTap: () => unawaited(showWishSheet(context, wish)),
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: () => unawaited(showWishSheet(context, wish)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            color: DiwaliPalette.maroon.withValues(alpha: AppOpacity.strong),
            border: Border.all(color: DiwaliPalette.goldBorder),
          ),
          child: LayoutBuilder(
            // A new diya ignites; the others just glow.
            builder: (context, c) => TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: motion.reduceMotion ? Duration.zero : AppDurations.slow,
              curve: Curves.easeOut,
              builder: (context, ignite, _) => Center(
                child: DiyaArt(
                  width: c.maxWidth * 0.7,
                  ignite: ignite,
                  clock: motion.animate ? motion.clock : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────── Guess the object ─────────────────────

class _GuessCard extends ConsumerWidget {
  const _GuessCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(guessProvider);
    return DiwaliCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle('Guess the Diwali object'),
          if (session == null)
            const _GuessPoster()
          else if (session.finished)
            _GuessResult(session: session)
          else
            _GuessRound(session: session),
        ],
      ),
    );
  }
}

class _GuessPoster extends ConsumerWidget {
  const _GuessPoster();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Name $guessRounds festive objects from their silhouettes.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.md),
      DiwaliButton(
        label: 'Start guessing',
        icon: Icons.help_outline,
        onPressed: ref.read(guessProvider.notifier).start,
      ),
    ],
  );
}

class _GuessRound extends ConsumerWidget {
  const _GuessRound({required this.session});

  final QuizSession session;

  /// Largest side of the picture.
  static const double _artMax = 180;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(guessProvider.notifier);
    final item = session.current;
    final chosen = session.currentAnswer;
    final answered = chosen != null;
    final correct = answered && chosen == item.correctIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Round ${session.index + 1} of ${session.total}',
          style: text.labelLarge?.copyWith(color: DiwaliPalette.saffron),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _artMax),
            child: ObjectArt(id: item.question.id, revealed: answered),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          header: true,
          child: Text(
            item.question.prompt,
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(color: DiwaliPalette.cream),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          inMutuallyExclusiveGroup: true,
          child: Column(
            children: [
              for (var i = 0; i < item.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: QuizOptionTile(
                    letter: _letters[i],
                    label: item.options[i],
                    state: !answered
                        ? QuizOptionState.idle
                        : i == item.correctIndex
                        ? QuizOptionState.correct
                        : i == chosen
                        ? QuizOptionState.wrong
                        : QuizOptionState.dimmed,
                    onTap: answered
                        ? null
                        : () {
                            notifier.answer(i);
                            ref
                                .read(diwaliFeedbackProvider)
                                .both(
                                  Haptic.selection,
                                  i == item.correctIndex
                                      ? Sfx.correct
                                      : Sfx.wrong,
                                );
                          },
                  ),
                ),
            ],
          ),
        ),
        RevealSize(
          child: answered
              ? Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correct
                            ? 'Yes, it’s a ${item.correctOption}!'
                            : 'Not quite. It’s a ${item.correctOption}.',
                        style: text.titleSmall?.copyWith(
                          color: correct
                              ? DiwaliPalette.success
                              : DiwaliPalette.error,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(item.question.explanation, style: text.bodyMedium),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            DiwaliButton(
              label: 'Quit',
              kind: DiwaliButtonKind.tertiary,
              onPressed: notifier.quit,
            ),
            DiwaliButton(
              label: session.isLast ? 'See results' : 'Next',
              icon: session.isLast ? Icons.flag : Icons.arrow_forward,
              onPressed: answered
                  ? () {
                      notifier.next();
                      final done = ref.read(guessProvider);
                      if (done != null &&
                          done.finished &&
                          done.tier == QuizTier.dazzler) {
                        ref
                            .read(diwaliFeedbackProvider)
                            .both(Haptic.medium, Sfx.win);
                      }
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _GuessResult extends ConsumerWidget {
  const _GuessResult({required this.session});

  final QuizSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(guessProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            'You got ${session.score} of ${session.total}',
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(color: DiwaliPalette.gold),
          ),
        ),
        Text(
          '“${session.tier.title}”',
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(color: DiwaliPalette.creamMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            DiwaliButton(
              label: 'Play again',
              icon: Icons.replay,
              onPressed: notifier.start,
            ),
            DiwaliButton(
              label: 'Back',
              kind: DiwaliButtonKind.tertiary,
              onPressed: notifier.quit,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────── Timeline ───────────────────────

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({required this.dates});

  final FestivalDates dates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(deepavaliNowProvider)();
    final status = FestivalStatus.at(now, dates);
    return DiwaliCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            'Festival timeline',
            subtitle: status.today == null
                ? 'Five days, one festival. Tap a day to read about it.'
                : 'Today is ${status.today!.title}. Tap a day to read about it.',
          ),
          TimelineStepper(
            dates: dates,
            today: status.today,
            onTap: (day) => unawaited(
              showDiwaliSheet<void>(
                context,
                builder: (_) => _DaySheet(day: day, date: dates.civilDate(day)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.day, required this.date});

  final FestivalDay day;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              day.title,
              style: text.titleLarge?.copyWith(color: DiwaliPalette.gold),
            ),
          ),
          Text(
            '${day.alsoKnownAs} · ${formatCivilDate(date)}',
            style: text.bodyMedium?.copyWith(color: DiwaliPalette.saffron),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(day.summary, style: text.bodyLarge),
        ],
      ),
    );
  }
}

// ───────────────────── Which city is for you ─────────────────────

class _RecommendCard extends ConsumerWidget {
  const _RecommendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(recommendProvider);
    final notifier = ref.read(recommendProvider.notifier);
    return DiwaliCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle('Which city is for you?'),
          if (flow == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Answer ${recommendQuestions.length} quick questions and we '
                  'will suggest the Deepavali city that suits you.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                DiwaliButton(
                  label: 'Find my city',
                  icon: Icons.travel_explore,
                  onPressed: notifier.start,
                ),
              ],
            )
          else if (flow.isDone)
            _RecommendResult(result: flow.result!)
          else
            _RecommendQuestionView(flow: flow),
        ],
      ),
    );
  }
}

class _RecommendQuestionView extends ConsumerWidget {
  const _RecommendQuestionView({required this.flow});

  final RecommendFlow flow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(recommendProvider.notifier);
    final q = flow.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Question ${flow.index + 1} of ${flow.total}',
          style: text.labelLarge?.copyWith(color: DiwaliPalette.saffron),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          header: true,
          child: Text(
            q.prompt,
            style: text.titleMedium?.copyWith(color: DiwaliPalette.cream),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: QuizOptionTile(
              letter: _letters[i],
              label: q.options[i].label,
              state: QuizOptionState.idle,
              onTap: () {
                ref.read(diwaliFeedbackProvider).haptic(Haptic.selection);
                notifier.answer(i);
              },
            ),
          ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.sm,
          children: [
            DiwaliButton(
              label: 'Cancel',
              kind: DiwaliButtonKind.tertiary,
              onPressed: notifier.reset,
            ),
            if (flow.answers.isNotEmpty)
              DiwaliButton(
                label: 'Previous',
                icon: Icons.arrow_back,
                kind: DiwaliButtonKind.tertiary,
                onPressed: notifier.back,
              ),
          ],
        ),
      ],
    );
  }
}

class _RecommendResult extends ConsumerWidget {
  const _RecommendResult({required this.result});

  final Recommendation result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final d = destinationById(result.destinationId)!;
    final notifier = ref.read(recommendProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your Deepavali city is…',
          style: text.labelLarge?.copyWith(color: DiwaliPalette.saffron),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: DestinationImage(
              destination: d,
              decodeWidth: AppSizes.photoDecodeWidth,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            d.name,
            style: text.headlineSmall?.copyWith(
              color: DiwaliPalette.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '${d.state} · ${d.tagline}',
          style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
        ),
        if (result.reasons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Because you chose:', style: text.labelLarge),
          for (final reason in result.reasons)
            Text('• $reason', style: text.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            DiwaliButton(
              label: 'Read about ${d.name}',
              icon: Icons.arrow_forward,
              onPressed: () => unawaited(
                context.push<void>(DeepavaliRoutes.destinationPath(d.id)),
              ),
            ),
            DiwaliButton(
              label: 'Start again',
              kind: DiwaliButtonKind.tertiary,
              onPressed: notifier.start,
            ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────── Full-screen extras ─────────────────────

class _LaunchCard extends StatelessWidget {
  const _LaunchCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) => DiwaliCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardTitle(title, subtitle: description),
        Align(
          alignment: Alignment.centerLeft,
          child: DiwaliButton(
            label: buttonLabel,
            icon: icon,
            onPressed: () => unawaited(context.push<void>(route)),
          ),
        ),
      ],
    ),
  );
}
