import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/models.dart';
import '../rajyotsava_providers.dart';
import 'widgets/rajyotsava_widgets.dart';

/// Kannada Cinema: famous actors and actresses and their best-known films.
/// Tapping a film searches for it on YouTube.
class CinemaPage extends ConsumerStatefulWidget {
  const CinemaPage({super.key});

  @override
  ConsumerState<CinemaPage> createState() => _CinemaPageState();
}

class _CinemaPageState extends ConsumerState<CinemaPage> {
  /// Selected filter; null shows everyone.
  StarRole? _role;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(rajyotsavaContentProvider).filmStars;
    final stars = _role == null
        ? all
        : all.where((s) => s.role == _role).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kannada Cinema')),
      body: SafeArea(
        child: ConstrainedBody(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    const SectionHeader(
                      title: 'Stars of Sandalwood',
                      kannada: 'ಕನ್ನಡ ಚಿತ್ರರಂಗ',
                    ),
                    Text(
                      'Tap a film to find it on YouTube.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _filter(null, 'All'),
                        for (final role in StarRole.values)
                          _filter(role, role.label),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                sliver: SliverList.builder(
                  itemCount: stars.length,
                  itemBuilder: (context, i) => _StarCard(star: stars[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filter(StarRole? role, String label) => ChoiceChip(
    key: ValueKey('cinema-filter-$label'),
    label: Text(label),
    selected: _role == role,
    onSelected: (_) => setState(() => _role = role),
  );
}

class _StarCard extends ConsumerWidget {
  const _StarCard({required this.star});

  final FilmStar star;

  Future<void> _watch(BuildContext context, WidgetRef ref, Film film) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ref
        .read(externalLinksProvider)
        .openYouTubeSearch('${film.title} ${film.year} Kannada movie');
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open YouTube.')),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(
                  icon: star.role == StarRole.actor
                      ? Icons.person
                      : Icons.person_outline,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(star.name, style: theme.textTheme.titleMedium),
                      Text(
                        star.kannadaName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      if (star.knownAs.isNotEmpty)
                        Text(
                          star.knownAs,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(star.about, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Famous films',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final film in star.films)
                  ActionChip(
                    avatar: const Icon(Icons.movie, size: AppIconSizes.xs),
                    label: Text('${film.title} (${film.year})'),
                    tooltip: 'Find ${film.title} on YouTube',
                    onPressed: () => _watch(context, ref, film),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
