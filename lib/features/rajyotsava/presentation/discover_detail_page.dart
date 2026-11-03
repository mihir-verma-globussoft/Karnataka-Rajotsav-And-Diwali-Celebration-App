import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../rajyotsava_providers.dart';
import 'widgets/directions_button.dart';
import 'widgets/rajyotsava_widgets.dart';

/// Detail screen for one Discover Karnataka item.
class DiscoverDetailPage extends ConsumerWidget {
  const DiscoverDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(rajyotsavaContentProvider).discoverItem(id);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Discover Karnataka')),
        body: SafeArea(
          child: ErrorView(
            error: const NotFoundFailure('We could not find that page.'),
            onRetry: () => context.pop(),
            retryLabel: 'Go back',
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SafeArea(
        child: ConstrainedBody(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                margin: EdgeInsets.zero,
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(
                        icon: discoverIcon(item.kind),
                        size: AppSizes.badgeLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        item.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        item.kannadaName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          Chip(
                            avatar: Icon(
                              categoryIcon(item.category),
                              size: AppIconSizes.xs,
                            ),
                            label: Text(item.category.label),
                          ),
                          Chip(
                            avatar: const Icon(
                              Icons.place_outlined,
                              size: AppIconSizes.xs,
                            ),
                            label: Text(item.location),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (item.mapQuery != null) ...[
                const SizedBox(height: AppSpacing.md),
                DirectionsButton(
                  destination: item.mapQuery!,
                  placeName: item.name,
                  expanded: true,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(item.description, style: theme.textTheme.bodyLarge),
              if (item.highlights.isNotEmpty) ...[
                const SectionHeader(title: 'Highlights', kannada: 'ವಿಶೇಷತೆಗಳು'),
                for (final h in item.highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.star,
                          size: AppIconSizes.sm,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(h, style: theme.textTheme.bodyLarge),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
