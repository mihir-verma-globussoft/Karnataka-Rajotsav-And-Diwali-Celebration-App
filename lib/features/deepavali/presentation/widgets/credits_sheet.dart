import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/content/credits.dart';
import '../theme/diwali_palette.dart';
import 'diwali_sheet.dart';

/// Opens the sheet that credits every photo, sound, typeface and source used
/// in the Deepavali tab.
Future<void> showCreditsSheet(BuildContext context) =>
    showDiwaliSheet<void>(context, builder: (_) => const _CreditsSheet());

class _CreditsSheet extends StatelessWidget {
  const _CreditsSheet();

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
              'Credits & licences',
              style: text.titleLarge?.copyWith(color: DiwaliPalette.gold),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Thank you to everyone whose work appears in this tab.',
            style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
          ),
          for (final group in creditGroups) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text(
                group.heading,
                style: text.titleMedium?.copyWith(color: DiwaliPalette.saffron),
              ),
            ),
            if (group.note != null)
              Text(
                group.note!,
                style: text.bodySmall?.copyWith(
                  color: DiwaliPalette.creamMuted,
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            for (final entry in group.entries) _Entry(entry: entry),
          ],
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.entry});

  final CreditEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.title, style: text.titleSmall),
            Text('${entry.by} · ${entry.licence}', style: text.bodyMedium),
            if (entry.source != null)
              Text(
                entry.source!,
                style: text.bodySmall?.copyWith(color: DiwaliPalette.saffron),
              ),
          ],
        ),
      ),
    );
  }
}
