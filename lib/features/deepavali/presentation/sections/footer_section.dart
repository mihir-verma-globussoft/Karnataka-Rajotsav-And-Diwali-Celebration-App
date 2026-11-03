import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_palette.dart';
import '../widgets/credits_sheet.dart';
import '../widgets/diwali_button.dart';
import '../widgets/ornament_divider.dart';

/// The end of the page: a short note on dates and customs, and the credits.
class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OrnamentDivider(),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Festival dates follow the calendar set for this app, and customs '
          'differ from region to region and family to family. Facts come from '
          'public sources listed in the credits.',
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: DiwaliPalette.creamMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            DiwaliButton(
              label: 'Credits & licences',
              icon: Icons.favorite_border,
              kind: DiwaliButtonKind.tertiary,
              onPressed: () => unawaited(showCreditsSheet(context)),
            ),
            DiwaliButton(
              label: 'Open-source licences',
              icon: Icons.description_outlined,
              kind: DiwaliButtonKind.tertiary,
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Globus Habba',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
