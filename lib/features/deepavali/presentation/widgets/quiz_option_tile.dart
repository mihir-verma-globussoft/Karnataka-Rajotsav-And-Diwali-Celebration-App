import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_palette.dart';

/// Animates the explanation open, or just shows it when motion is reduced
/// ([AnimatedSize] asserts with a zero duration).
class RevealSize extends StatelessWidget {
  const RevealSize({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSize(
          duration: AppDurations.fast,
          alignment: Alignment.topCenter,
          child: child,
        );
}

enum QuizOptionState { idle, correct, wrong, dimmed }

class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    required this.letter,
    required this.label,
    required this.state,
    required this.onTap,
    super.key,
  });

  final String letter;
  final String label;
  final QuizOptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = switch (state) {
      QuizOptionState.correct => DiwaliPalette.success,
      QuizOptionState.wrong => DiwaliPalette.error,
      _ => DiwaliPalette.gold,
    };
    final marked =
        state == QuizOptionState.correct || state == QuizOptionState.wrong;
    final status = switch (state) {
      QuizOptionState.correct => ', correct answer',
      QuizOptionState.wrong => ', your answer, incorrect',
      _ => '',
    };
    return Semantics(
      button: true,
      selected:
          state == QuizOptionState.wrong || state == QuizOptionState.correct,
      label: 'Option $letter: $label$status',
      excludeSemantics: true,
      onTap: onTap,
      child: Opacity(
        opacity: state == QuizOptionState.dimmed ? AppOpacity.strong : 1,
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              color: marked
                  ? color.withValues(alpha: AppOpacity.faint)
                  : DiwaliPalette.night.withValues(alpha: AppOpacity.strong),
              border: Border.all(
                color: marked ? color : DiwaliPalette.goldBorder,
              ),
            ),
            child: InkWell(
              borderRadius: AppRadius.mdAll,
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: AppIconSizes.md,
                        ),
                        child: Text(
                          letter,
                          textAlign: TextAlign.center,
                          style: text.titleSmall?.copyWith(color: color),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(label, style: text.bodyMedium)),
                      if (marked) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          state == QuizOptionState.correct
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: color,
                          size: AppIconSizes.md,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
