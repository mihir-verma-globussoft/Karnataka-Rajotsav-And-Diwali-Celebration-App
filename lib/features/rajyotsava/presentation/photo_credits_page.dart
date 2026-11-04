import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../rajyotsava_providers.dart';
import 'widgets/rajyotsava_photo.dart';

/// Lists who took each photo in the Rajyotsava section and its licence, as
/// the Creative Commons licences require. All photos are from Wikimedia
/// Commons.
class PhotoCreditsPage extends ConsumerWidget {
  const PhotoCreditsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = ref
        .watch(rajyotsavaContentProvider)
        .photos
        .credits
        .entries
        .toList();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Photo credits')),
      body: SafeArea(
        child: ConstrainedBody(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: credits.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Photos are from Wikimedia Commons and are used under '
                    'the licences shown. Thank you to every photographer.',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }
              final MapEntry(key: asset, value: credit) = credits[i - 1];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RajyotsavaPhoto(
                        asset: asset,
                        fallbackIcon: Icons.photo_outlined,
                        size: AppSizes.badge,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              credit.title,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              '${credit.author} · ${credit.license}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SelectableText(
                              credit.source,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
