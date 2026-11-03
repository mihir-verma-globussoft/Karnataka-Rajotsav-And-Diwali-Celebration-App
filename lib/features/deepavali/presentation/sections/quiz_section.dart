import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/content/quiz_questions.dart';
import '../../domain/quiz_session.dart';
import '../../domain/sound.dart';
import '../state/feedback.dart';
import '../state/quiz_notifier.dart';
import '../theme/diwali_palette.dart';
import '../widgets/celebration_burst.dart';
import '../widgets/diwali_button.dart';
import '../widgets/diwali_card.dart';
import '../widgets/diwali_motion.dart';
import '../widgets/quiz_option_tile.dart';
import '../widgets/section_header.dart';

const List<String> _letters = ['A', 'B', 'C', 'D'];

/// Inline quiz: poster, ten questions with instant feedback, then results.
class QuizSection extends ConsumerWidget {
  const QuizSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(quizProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Deepavali Quiz',
          subtitle: 'Test what you know',
        ),
        const SizedBox(height: AppSpacing.md),
        DiwaliCard(
          child: session == null
              ? const _Poster()
              : session.finished
              ? _Results(session: session)
              : _Question(session: session),
        ),
      ],
    );
  }
}

class _Poster extends ConsumerWidget {
  const _Poster();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final best = ref.watch(quizBestProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$quizLength questions about the festival, its stories, food and '
          'customs. Takes about three minutes.',
          style: text.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          best == null ? 'Best: —' : 'Best: $best / $quizLength',
          style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        DiwaliButton(
          label: 'Start quiz',
          icon: Icons.quiz_outlined,
          onPressed: ref.read(quizProvider.notifier).start,
        ),
      ],
    );
  }
}

class _Question extends ConsumerWidget {
  const _Question({required this.session});

  final QuizSession session;

  Future<void> _confirmQuit(BuildContext context, WidgetRef ref) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave the quiz?'),
        content: const Text('Your answers so far will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave ?? false) ref.read(quizProvider.notifier).quit();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(quizProvider.notifier);
    final item = session.current;
    final chosen = session.currentAnswer;
    final answered = chosen != null;
    final correct = answered && chosen == item.correctIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Question ${session.index + 1} of ${session.total}',
          excludeSemantics: true,
          child: Text(
            'Question ${session.index + 1} of ${session.total}',
            style: text.labelLarge?.copyWith(color: DiwaliPalette.saffron),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.smAll,
          child: LinearProgressIndicator(
            value: (session.index + (answered ? 1 : 0)) / session.total,
            minHeight: AppSizes.progressBar,
            color: DiwaliPalette.gold,
            backgroundColor: DiwaliPalette.goldBorder,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            item.question.prompt,
            style: text.titleMedium?.copyWith(color: DiwaliPalette.cream),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          correct
                              ? 'Correct!'
                              : 'Not quite. The answer is '
                                    '${item.correctOption}.',
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
              onPressed: () => _confirmQuit(context, ref),
            ),
            DiwaliButton(
              label: session.isLast ? 'See results' : 'Next',
              icon: session.isLast ? Icons.flag : Icons.arrow_forward,
              onPressed: answered
                  ? () {
                      notifier.next();
                      final done = ref.read(quizProvider);
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

class _Results extends ConsumerWidget {
  const _Results({required this.session});

  final QuizSession session;

  /// Height of the area the celebration sparks play in.
  static const double _burstHeight = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final motion = DiwaliMotion.of(context);
    final notifier = ref.read(quizProvider.notifier);
    final best = ref.watch(quizBestProvider).value;
    final celebrate = session.tier == QuizTier.dazzler;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _burstHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (celebrate && motion.animate)
                const Positioned.fill(child: CelebrationBurst()),
              const Icon(
                Icons.emoji_events,
                color: DiwaliPalette.gold,
                size: AppIconSizes.hero,
              ),
            ],
          ),
        ),
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            'You scored ${session.score} / ${session.total}',
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(color: DiwaliPalette.gold),
          ),
        ),
        Text(
          '“${session.tier.title}”'
          '${best == null ? '' : ' · Best: $best / ${session.total}'}',
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(color: DiwaliPalette.creamMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < session.total; i++)
          _ReviewRow(session: session, question: i),
        const SizedBox(height: AppSpacing.sm),
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.session, required this.question});

  final QuizSession session;
  final int question;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final item = session.items[question];
    final ok = session.isCorrect(question);
    final chosen = session.answers[question];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? DiwaliPalette.success : DiwaliPalette.error,
            size: AppIconSizes.sm,
            semanticLabel: ok ? 'Correct' : 'Incorrect',
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.question.prompt, style: text.bodyMedium),
                if (!ok)
                  Text(
                    'Your answer: '
                    '${chosen == null ? '—' : item.options[chosen]}. '
                    'Correct: ${item.correctOption}.',
                    style: text.bodySmall?.copyWith(
                      color: DiwaliPalette.creamMuted,
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
