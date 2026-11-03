import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/content/destinations.dart';
import '../theme/diwali_palette.dart';
import 'diwali_sheet.dart';

/// Lists the attribution for every bundled photo.
Future<void> showPhotoCreditsSheet(BuildContext context) =>
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
              'Photo credits',
              style: text.titleLarge?.copyWith(color: DiwaliPalette.gold),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Some photographs are from Wikimedia Commons and used under the '
            'licences shown. The others were supplied by the app team.',
            style: text.bodyMedium?.copyWith(color: DiwaliPalette.creamMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final d in destinations)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: text.titleSmall?.copyWith(
                      color: DiwaliPalette.cream,
                    ),
                  ),
                  Text(
                    '${d.photo.author} · ${d.photo.license}',
                    style: text.bodyMedium,
                  ),
                  if (!d.photo.isSupplied)
                    Text(
                      d.photo.sourceUrl,
                      style: text.bodySmall?.copyWith(
                        color: DiwaliPalette.saffron,
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
