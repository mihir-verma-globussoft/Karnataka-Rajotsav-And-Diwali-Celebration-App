import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_palette.dart';

enum DiwaliButtonKind { primary, secondary, tertiary }

/// Festive button, at least 48dp tall. Disabled when [onPressed] is null.
class DiwaliButton extends StatelessWidget {
  const DiwaliButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = DiwaliButtonKind.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DiwaliButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppIconSizes.sm),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: text),
      ],
    );
    switch (kind) {
      case DiwaliButtonKind.primary:
        return Opacity(
          opacity: enabled ? 1 : AppOpacity.disabled,
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: const BoxDecoration(
                gradient: DiwaliPalette.cta,
                borderRadius: AppRadius.xlAll,
              ),
              child: InkWell(
                onTap: onPressed,
                borderRadius: AppRadius.xlAll,
                splashColor: DiwaliPalette.night.withValues(
                  alpha: AppOpacity.faint,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.minTouchTarget,
                    minWidth: AppSizes.minTouchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(color: DiwaliPalette.night),
                      child: IconTheme.merge(
                        data: const IconThemeData(color: DiwaliPalette.night),
                        child: Center(widthFactor: 1, child: row),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case DiwaliButtonKind.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: DiwaliPalette.gold,
            side: const BorderSide(color: DiwaliPalette.gold),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: row,
        );
      case DiwaliButtonKind.tertiary:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: DiwaliPalette.saffron),
          child: row,
        );
    }
  }
}
