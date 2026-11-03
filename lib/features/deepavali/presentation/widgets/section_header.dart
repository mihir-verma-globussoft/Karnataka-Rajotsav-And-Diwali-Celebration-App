import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_palette.dart';
import 'ornament_divider.dart';

/// Ornament divider, gold title and a one-line subtitle.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OrnamentDivider(),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.headlineSmall?.copyWith(
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
      ],
    );
  }
}
