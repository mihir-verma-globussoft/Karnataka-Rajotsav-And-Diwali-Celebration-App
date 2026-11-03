import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_palette.dart';

/// Festive card: surface gradient with a gold hairline border.
class DiwaliCard extends StatelessWidget {
  const DiwaliCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Label for tappable cards; read instead of the child text when set.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Ink(
      decoration: BoxDecoration(
        gradient: DiwaliPalette.card,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: DiwaliPalette.goldBorder),
      ),
      child: Padding(padding: padding, child: child),
    );
    final card = Material(
      type: MaterialType.transparency,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              splashColor: DiwaliPalette.gold.withValues(
                alpha: AppOpacity.faint,
              ),
              highlightColor: DiwaliPalette.gold.withValues(
                alpha: AppOpacity.pressed,
              ),
              child: content,
            ),
    );
    if (onTap == null || semanticLabel == null) return card;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: card,
    );
  }
}
