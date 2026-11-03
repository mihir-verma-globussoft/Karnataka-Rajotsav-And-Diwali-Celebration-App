import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/models.dart';
import '../domain/quiz_session.dart';
import '../rajyotsava_providers.dart';

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
      body = _Results(session: session, onRestart: controller.restart);
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
      _OptionState.correct => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
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
  const _Feedback({required this.question, required this.correct});

  final QuizQuestion question;
  final bool correct;

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
  const _Results({required this.session, required this.onRestart});

  final QuizSession session;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.md),
        Icon(
          Icons.emoji_events,
          size: AppIconSizes.hero,
          color: scheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
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
              color: correct ? scheme.primary : scheme.error,
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
