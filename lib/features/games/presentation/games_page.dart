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
                child: Padding(
                  // Bottom space keeps the last box clear of the floating bar.
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl * 3,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < games.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        Expanded(child: _GameBox(entry: games[i])),
                      ],
                    ],
                  ),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(entry.icon, size: 40),
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
