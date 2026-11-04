import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/easter_eggs.dart';
import '../rajyotsava_providers.dart';
import 'widgets/collectible_card.dart';
import 'widgets/collectible_reveal.dart';

/// Karnataka Secrets: every hidden collectible, found or not. Found cards
/// show their photo and open again as the 3D card; the rest are locked
/// silhouettes that keep their name a secret.
class CollectionPage extends ConsumerStatefulWidget {
  const CollectionPage({super.key});

  @override
  ConsumerState<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends ConsumerState<CollectionPage> {
  /// Null shows every category.
  EggCategory? _category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(collectiblesProvider);
    final found = ref.watch(easterEggManagerProvider).value ?? const {};
    final shown = [
      for (final c in all)
        if (_category == null || c.category == _category) c,
    ];
    final foundCount = all.where((c) => found.containsKey(c.id)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Karnataka Secrets')),
      body: SafeArea(
        child: ConstrainedBody(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Semantics(
                label: '$foundCount of ${all.length} secrets found',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ಕರ್ನಾಟಕದ ರಹಸ್ಯಗಳು',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '$foundCount / ${all.length} found',
                      key: const ValueKey('collection-progress'),
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: AppRadius.smAll,
                      child: LinearProgressIndicator(
                        value: all.isEmpty ? 0 : foundCount / all.length,
                        minHeight: AppSizes.progressBar,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                foundCount == all.length
                    ? 'You found them all. Tap a card to look at it again.'
                    : 'Shake your phone on any Rajyotsava screen to find '
                          'one. Some are hidden behind secret taps too.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _filter(null, 'All'),
                  for (final category in EggCategory.values)
                    _filter(category, category.label),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      (constraints.maxWidth /
                              (AppSizes.collectibleTileMinWidth +
                                  AppSpacing.sm))
                          .floor()
                          .clamp(1, 4);
                  final width =
                      (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final c in shown)
                        SizedBox(
                          width: width,
                          child: found.containsKey(c.id)
                              ? _FoundTile(
                                  collectible: c,
                                  timesFound: found[c.id]!.count,
                                )
                              : _LockedTile(category: c.category),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filter(EggCategory? category, String label) => ChoiceChip(
    key: ValueKey('collection-filter-${category?.name ?? 'all'}'),
    label: Text(label),
    selected: _category == category,
    onSelected: (_) => setState(() => _category = category),
  );
}

class _FoundTile extends ConsumerWidget {
  const _FoundTile({required this.collectible, required this.timesFound});

  final Collectible collectible;
  final int timesFound;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photo = ref
        .watch(rajyotsavaContentProvider)
        .photos
        .byKey(collectible.photoKey);
    final legendary = collectible.rarity == EggRarity.legendary;
    return Semantics(
      button: true,
      label: '${collectible.title}, ${collectible.rarity.label}. Open card.',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: () => showCollectibleReveal(
          context,
          reveal: NewCollectible(collectible),
          photo: photo,
          revisit: true,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: CollectibleCard.aspectRatio,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(
                    color: legendary
                        ? AppColors.kannadaYellow
                        : AppColors.kannadaRed,
                    width: AppSpacing.xs / 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: photo == null
                      ? _Silhouette(category: collectible.category, lit: true)
                      : Image.asset(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _Silhouette(
                            category: collectible.category,
                            lit: true,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(collectible.title, style: theme.textTheme.titleSmall),
            Text(
              collectible.kannadaTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedTile extends StatelessWidget {
  const _LockedTile({required this.category});

  final EggCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Locked ${category.label} secret',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: CollectibleCard.aspectRatio,
            child: ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: _Silhouette(category: category, lit: false),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '? ? ?',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            category.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card-shaped stand-in: the category's symbol, with a lock when the
/// card has not been found.
class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.category, required this.lit});

  final EggCategory category;
  final bool lit;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: lit ? AppColors.bannerTop : AppColors.glassLow,
      border: lit ? null : Border.all(color: AppColors.glassBorder),
      borderRadius: AppRadius.mdAll,
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          switch (category) {
            EggCategory.personality => Icons.person,
            EggCategory.place => Icons.account_balance,
            EggCategory.culture => Icons.theater_comedy,
            EggCategory.nature => Icons.landscape,
          },
          size: AppIconSizes.hero,
          color: lit
              ? AppColors.kannadaYellow
              : AppColors.onNight.withValues(alpha: AppOpacity.faint),
        ),
        if (!lit)
          const Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Icon(
              Icons.lock,
              size: AppIconSizes.md,
              color: AppColors.onNightMuted,
            ),
          ),
      ],
    ),
  );
}
