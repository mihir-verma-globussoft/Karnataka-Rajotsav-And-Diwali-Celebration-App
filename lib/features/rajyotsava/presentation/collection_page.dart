import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/easter_eggs.dart';
import '../rajyotsava_providers.dart';
import 'widgets/collectible_card.dart';
import 'widgets/collectible_reveal.dart';
import 'widgets/rajyotsava_widgets.dart';

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
              if (foundCount < all.length) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    key: const ValueKey('collection-hint'),
                    onPressed: _showHint,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Need a hint?'),
                  ),
                ),
              ],
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

  /// Which hint "Need a hint?" opens on next, so each press moves on.
  var _nextHint = 0;

  void _showHint() {
    final hints = ref.read(easterEggHintsProvider);
    if (hints.isEmpty) return;
    final start = _nextHint % hints.length;
    _nextHint = start + 1;
    ref.read(hapticsProvider).tap();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      // The section's colours on a plain sheet, so the sheet is one colour
      // up to its drag handle.
      builder: (_) => Theme(
        data: RajyotsavaTheme.data,
        child: _HintSheet(hints: hints, start: start),
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

/// One hint at a time; "Next hint" moves through them all and wraps round.
class _HintSheet extends ConsumerStatefulWidget {
  const _HintSheet({required this.hints, required this.start});

  final List<EggHint> hints;
  final int start;

  @override
  ConsumerState<_HintSheet> createState() => _HintSheetState();
}

class _HintSheetState extends ConsumerState<_HintSheet> {
  late var _index = widget.start;

  void _next() {
    ref.read(hapticsProvider).selection();
    setState(() => _index = (_index + 1) % widget.hints.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = widget.hints[_index];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  size: AppIconSizes.lg,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Hint ${_index + 1} of ${widget.hints.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Column(
                  key: ValueKey(_index),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hint.kannada,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(hint.english, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                if (widget.hints.length > 1)
                  FilledButton.icon(
                    key: const ValueKey('hint-next'),
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next hint'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
