import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../rajyotsava_providers.dart';
import 'widgets/directions_button.dart';
import 'widgets/discover_card.dart';
import 'widgets/rajyotsava_photo.dart';
import 'widgets/rajyotsava_widgets.dart';

/// What one district is famous for, with links to related Discover items.
class DistrictPage extends ConsumerWidget {
  const DistrictPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(rajyotsavaContentProvider);
    final district = content.district(id);
    if (district == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Near me')),
        body: SafeArea(
          child: ErrorView(
            error: const NotFoundFailure('We could not find that district.'),
            onRetry: () => context.pop(),
            retryLabel: 'Go back',
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final places = content.placesIn(district.id);
    final related = [
      for (final itemId in district.discoverIds) ?content.discoverItem(itemId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(district.name),
        actions: const [PhotoCreditsButton()],
      ),
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
                      const IconBadge(
                        icon: Icons.location_city,
                        size: AppSizes.badgeLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        district.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        district.kannadaName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        district.knownFor,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Chip(
                        avatar: const Icon(
                          Icons.account_balance_outlined,
                          size: AppIconSizes.xs,
                        ),
                        label: Text('Headquarters: ${district.headquarters}'),
                      ),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: 'Famous for', kannada: 'ಪ್ರಸಿದ್ಧಿ'),
              for (final line in district.famous)
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
                        child: Text(line, style: theme.textTheme.bodyLarge),
                      ),
                    ],
                  ),
                ),
              if (places.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Places to visit',
                  kannada: 'ನೋಡಬೇಕಾದ ಸ್ಥಳಗಳು',
                ),
                Text(
                  'Directions open in your maps app, starting from where you '
                  'are. If location is off, the maps app asks where to start.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final place in places)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    color: scheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.xs,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          RajyotsavaPhoto(
                            asset: content.photos.place(
                              district.id,
                              place.name,
                            ),
                            fallbackIcon: Icons.place_outlined,
                            size: AppSizes.badge,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              place.name,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          DirectionsButton(
                            destination: place.mapQuery,
                            placeName: place.name,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (related.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Discover more',
                  kannada: 'ಇನ್ನಷ್ಟು ತಿಳಿಯಿರಿ',
                ),
                for (final item in related) DiscoverCard(item: item),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
