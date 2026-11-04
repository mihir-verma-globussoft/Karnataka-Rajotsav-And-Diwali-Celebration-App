import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/models.dart';
import '../rajyotsava_providers.dart';
import 'widgets/discover_card.dart';
import 'widgets/rajyotsava_photo.dart';
import 'widgets/rajyotsava_widgets.dart';

/// Discover Karnataka: places, food, culture and people, filterable by
/// category. Tapping a card opens its detail screen.
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  /// Selected filter; null shows everything.
  DiscoverCategory? _category;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(rajyotsavaContentProvider).discover;
    final items = _category == null
        ? all
        : all.where((i) => i.category == _category).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Karnataka'),
        actions: const [PhotoCreditsButton()],
      ),
      body: SafeArea(
        child: ConstrainedBody(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    _filterChip(null, 'All', Icons.apps),
                    for (final c in DiscoverCategory.values)
                      _filterChip(c, c.label, categoryIcon(c)),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyView(
                        message: 'Nothing here yet.',
                        icon: Icons.explore_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.lg,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) =>
                            DiscoverCard(item: items[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(DiscoverCategory? category, String label, IconData icon) =>
      Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          key: ValueKey('discover-filter-$label'),
          avatar: Icon(icon, size: AppIconSizes.xs),
          label: Text(label),
          selected: _category == category,
          onSelected: (_) => setState(() => _category = category),
        ),
      );
}
