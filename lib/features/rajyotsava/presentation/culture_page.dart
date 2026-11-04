import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/models.dart';
import '../rajyotsava_providers.dart';
import 'widgets/rajyotsava_widgets.dart';
import 'widgets/secret_tap.dart';

/// Songs & Folk Arts: Kannada patriotic and folk songs and Karnataka's folk
/// art forms, each with a short explanation and a YouTube search.
class CulturePage extends ConsumerWidget {
  const CulturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final culture = ref.watch(rajyotsavaContentProvider).culture;
    List<CultureEntry> of(CultureKind kind) =>
        culture.where((c) => c.kind == kind).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          // Secret: long-press the title.
          title: const SecretTap(
            longPress: true,
            child: Text('Songs & Folk Arts'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Songs'),
              Tab(text: 'Folk arts'),
            ],
          ),
        ),
        body: SafeArea(
          child: ConstrainedBody(
            child: TabBarView(
              children: [
                _CultureList(
                  entries: of(CultureKind.song),
                  intro: 'Patriotic and folk songs sung on Rajyotsava.',
                ),
                _CultureList(
                  entries: of(CultureKind.art),
                  intro: 'Traditional dance, theatre and music of Karnataka.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CultureList extends StatelessWidget {
  const _CultureList({required this.entries, required this.intro});

  final List<CultureEntry> entries;
  final String intro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: entries.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '$intro "Watch on YouTube" opens a search, so you can choose '
              'an official or favourite version.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return _CultureCard(entry: entries[i - 1]);
      },
    );
  }
}

class _CultureCard extends ConsumerWidget {
  const _CultureCard({required this.entry});

  final CultureEntry entry;

  Future<void> _watch(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ref
        .read(externalLinksProvider)
        .openYouTubeSearch(entry.searchQuery);
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
                  icon: entry.kind == CultureKind.song
                      ? Icons.music_note
                      : Icons.theater_comedy,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: theme.textTheme.titleMedium),
                      Text(
                        entry.kannadaTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.credit,
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
            Text(entry.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label: 'Watch ${entry.title} on YouTube',
              excludeSemantics: true,
              child: OutlinedButton.icon(
                onPressed: () => _watch(context, ref),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Watch on YouTube'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
