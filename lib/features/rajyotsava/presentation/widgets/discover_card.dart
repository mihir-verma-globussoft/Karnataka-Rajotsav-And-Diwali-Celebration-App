import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/models.dart';
import '../../rajyotsava_providers.dart';
import '../../rajyotsava_routes.dart';
import 'rajyotsava_photo.dart';
import 'rajyotsava_widgets.dart';

/// List card for a Discover Karnataka item; opens its detail page.
class DiscoverCard extends ConsumerWidget {
  const DiscoverCard({required this.item, super.key});

  final DiscoverItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RajyotsavaRoutes.discoverItem(item.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              RajyotsavaPhoto(
                asset: ref
                    .watch(rajyotsavaContentProvider)
                    .photos
                    .discoverItem(item.id),
                fallbackIcon: discoverIcon(item.kind),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleMedium),
                    Text(
                      item.kannadaName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.tagline,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
