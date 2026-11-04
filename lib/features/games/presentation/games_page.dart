import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/feature_module.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';

/// Games tab: one rounded box per game, stacked vertically. The boxes come
/// from features that register an entry with `group: FeatureGroups.games`.
class GamesPage extends ConsumerWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = [
      for (final m in ref.watch(featureModulesProvider))
        if (m.entry?.group == FeatureGroups.games) m.entry!,
    ]..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: SafeArea(
        child: games.isEmpty
            ? const EmptyView(
                message: 'No games yet.',
                icon: Icons.sports_esports_outlined,
              )
            : ConstrainedBody(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Boxes share the screen height equally, but never
                    // shrink below their content: with large text or a
                    // short screen the list scrolls instead of overflowing.
                    const padding = EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      // Keeps the last box clear of the floating bar.
                      AppSizes.floatingBarClearance,
                    );
                    final share =
                        (constraints.maxHeight -
                            padding.vertical -
                            AppSpacing.md * (games.length - 1)) /
                        games.length;
                    return ListView.separated(
                      padding: padding,
                      itemCount: games.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) => ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: share.clamp(
                            AppSizes.minTouchTarget,
                            double.infinity,
                          ),
                        ),
                        child: _GameBox(entry: games[i]),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _GameBox extends StatelessWidget {
  const _GameBox({required this.entry});

  final FeatureEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(entry.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(entry.icon, size: AppIconSizes.lg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: theme.textTheme.titleLarge),
                    Text(
                      entry.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
