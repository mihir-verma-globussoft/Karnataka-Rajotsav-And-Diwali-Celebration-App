import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/models.dart';
import '../domain/quiz_scores.dart';
import '../domain/quiz_session.dart';
import '../rajyotsava_providers.dart';
import 'widgets/secret_tap.dart';

/// Multiple-choice Karnataka quiz: one question at a time, feedback after
/// each answer, then a results screen with a review of every answer.
class QuizPage extends ConsumerWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(quizControllerProvider);
    final controller = ref.read(quizControllerProvider.notifier);

    final Widget body;
    if (session.length == 0) {
      body = const EmptyView(
        message: 'No quiz questions yet.',
        icon: Icons.quiz_outlined,
      );
    } else if (session.isFinished) {
      body = _Results(
        session: session,
        saving: controller.saving,
        onRestart: controller.restart,
      );
    } else {
      body = _QuestionView(
        session: session,
        onAnswer: controller.answer,
        onNext: controller.next,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rajyotsava Quiz')),
      body: SafeArea(child: ConstrainedBody(child: body)),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.session,
    required this.onAnswer,
    required this.onNext,
  });

  final QuizSession session;
  final ValueChanged<int> onAnswer;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = session.current!;
    final chosen = session.currentAnswer;
    final isLast = session.index == session.length - 1;

    return ListView(
      // A new list for each question, so it opens at the top rather than
      // where the last one was scrolled to (on small screens, below the
      // question).
      key: ValueKey('quiz-question-${session.index}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Question ${session.index + 1} of ${session.length}',
                style: theme.textTheme.labelLarge,
              ),
            ),
            Text(
              'Score ${session.score}',
              key: const ValueKey('quiz-score'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.smAll,
          child: LinearProgressIndicator(
            value: (session.index + (chosen == null ? 0 : 1)) / session.length,
            minHeight: AppSizes.progressBar,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(question.question, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < question.options.length; i++) ...[
          _OptionTile(
            key: ValueKey('quiz-option-$i'),
            letter: String.fromCharCode(65 + i),
            text: question.options[i],
            state: _optionState(i, chosen, question.answerIndex),
            onTap: chosen == null ? () => onAnswer(i) : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (chosen != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _Feedback(
            question: question,
            correct: chosen == question.answerIndex,
            points: session.pointsFor(session.index),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const ValueKey('quiz-next'),
            onPressed: onNext,
            icon: Icon(isLast ? Icons.emoji_events : Icons.arrow_forward),
            label: Text(isLast ? 'See results' : 'Next question'),
          ),
        ],
      ],
    );
  }

  static _OptionState _optionState(int i, int? chosen, int answer) {
    if (chosen == null) return _OptionState.idle;
    if (i == answer) return _OptionState.correct;
    if (i == chosen) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
    super.key,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground, icon, semantic) = switch (state) {
      _OptionState.idle => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        null,
        '',
      ),
      // Green for right (red would look like a wrong answer on maroon).
      _OptionState.correct => (
        AppColors.accentGreen,
        AppColors.onBanner,
        Icons.check_circle,
        'Correct answer. ',
      ),
      _OptionState.wrong => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.cancel,
        'Your answer, wrong. ',
      ),
      _OptionState.dimmed => (
        scheme.surfaceContainerLow,
        scheme.onSurfaceVariant,
        null,
        '',
      ),
    };

    return Semantics(
      button: onTap != null,
      label: '$semantic$letter. $text',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Text(
                    letter,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                  if (icon != null) Icon(icon, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.question,
    required this.correct,
    required this.points,
  });

  final QuizQuestion question;
  final bool correct;

  /// Points this answer earned.
  final int points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Card(
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                correct
                    ? 'Correct! ಸರಿ ಉತ್ತರ!'
                    : 'Not quite. The answer is ${question.answer}.',
                style: theme.textTheme.titleMedium,
              ),
              if (correct)
                Text(
                  '+$points points',
                  key: const ValueKey('quiz-answer-points'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(question.explanation, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.session,
    required this.saving,
    required this.onRestart,
  });

  final QuizSession session;

  /// The round being sent to the leaderboard.
  final Future<QuizSaveOutcome>? saving;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.md),
        // Secret: tap the trophy 3 times.
        SecretTap(
          taps: 3,
          child: Icon(
            Icons.emoji_events,
            size: AppIconSizes.hero,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${session.points} points',
          key: const ValueKey('quiz-points'),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'You scored ${session.score} of ${session.length}',
          key: const ValueKey('quiz-result'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          quizVerdict(session.score, session.length),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          key: const ValueKey('quiz-restart'),
          onPressed: onRestart,
          icon: const Icon(Icons.replay),
          label: const Text('Play again'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Back to Rajyotsava'),
        ),
        if (saving case final saving?) ...[
          const SizedBox(height: AppSpacing.lg),
          _Leaderboard(saving: saving),
        ],
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text('Your answers', style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < session.length; i++)
          _ReviewTile(
            question: session.questions[i],
            chosen: session.answers[i],
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.question, required this.chosen});

  final QuizQuestion question;
  final int chosen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final correct = chosen == question.answerIndex;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              correct ? Icons.check_circle : Icons.cancel,
              color: correct ? AppColors.accentGreen : scheme.error,
              semanticLabel: correct ? 'Correct' : 'Wrong',
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.question, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.xs),
                  if (!correct)
                    Text(
                      'You said: ${question.options[chosen]}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  Text(
                    'Answer: ${question.answer}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The quiz leaderboard after a round: whether the round was saved, the
/// player's best and rank, and the top players. Hidden when this build has
/// no leaderboard or nobody is signed in.
class _Leaderboard extends ConsumerStatefulWidget {
  const _Leaderboard({required this.saving});

  final Future<QuizSaveOutcome> saving;

  @override
  ConsumerState<_Leaderboard> createState() => _LeaderboardState();
}

typedef _Board = ({
  QuizSaveOutcome outcome,
  QuizStanding? standing,
  List<QuizLeader> leaders,
});

class _LeaderboardState extends ConsumerState<_Leaderboard> {
  late final Future<_Board> _board = _load();

  /// Rows shown on the results screen.
  static const int _top = 10;

  Future<_Board> _load() async {
    final outcome = await widget.saving;
    final scoreboard = ref.read(quizScoreboardProvider);
    if (outcome is QuizNotSaved) {
      return (outcome: outcome, standing: null, leaders: const <QuizLeader>[]);
    }
    final (standing, leaders) = await (
      scoreboard.standing(),
      scoreboard.leaders(limit: _top),
    ).wait;
    return (outcome: outcome, standing: standing, leaders: leaders);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return FutureBuilder<_Board>(
      future: _board,
      builder: (context, snapshot) {
        final board = snapshot.data;
        if (board == null) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (board.outcome is QuizNotSaved) return const SizedBox.shrink();
        final standing = board.standing;
        final status = switch (board.outcome) {
          QuizSaved(isNewBest: true) => 'New personal best!',
          QuizSaved() => 'Saved to the leaderboard.',
          QuizQueued() =>
            'Saved on this phone. It will reach the leaderboard when you '
                'are back online.',
          QuizNotSaved() => '',
        };
        return Card(
          key: const ValueKey('quiz-leaderboard'),
          margin: EdgeInsets.zero,
          color: scheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Leaderboard · ಮುನ್ನಡೆ',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    status,
                    key: const ValueKey('quiz-save-status'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: board.outcome is QuizSaved
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
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
                          '${standing.rounds == 1 ? 'round' : 'rounds'}',
                    ].join(' · '),
                    key: const ValueKey('quiz-standing'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (board.leaders.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  for (final leader in board.leaders)
                    _LeaderRow(leader: leader),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.leader});

  final QuizLeader leader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
              ? scheme.primary.withValues(alpha: AppOpacity.faint)
              : null,
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppSizes.minTouchTarget,
              child: Text(
                '#${leader.rank}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: leader.rank <= 3 ? scheme.primary : null,
                ),
              ),
            ),
            CircleAvatar(
              radius: AppIconSizes.md / 2 + AppSpacing.xs,
              backgroundColor: scheme.surfaceContainerHighest,
              foregroundImage: url == null ? null : NetworkImage(url),
              child: const Icon(Icons.person, size: AppIconSizes.sm),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: leader.isYou ? FontWeight.bold : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('${leader.points}', style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
