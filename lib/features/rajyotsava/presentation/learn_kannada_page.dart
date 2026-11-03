import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/models.dart';
import '../rajyotsava_providers.dart';
import 'widgets/rajyotsava_widgets.dart';

/// Learn Kannada: alphabet, everyday phrases and numbers, in three tabs.
class LearnKannadaPage extends ConsumerWidget {
  const LearnKannadaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(rajyotsavaContentProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Learn Kannada'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Alphabet'),
              Tab(text: 'Phrases'),
              Tab(text: 'Numbers'),
            ],
          ),
        ),
        body: SafeArea(
          child: ConstrainedBody(
            child: TabBarView(
              children: [
                _AlphabetTab(
                  vowels: content.vowels,
                  consonants: content.consonants,
                ),
                _PhrasesTab(phrases: content.phrases),
                _NumbersTab(numbers: content.numbers),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlphabetTab extends StatelessWidget {
  const _AlphabetTab({required this.vowels, required this.consonants});

  final List<KannadaLetter> vowels;
  final List<KannadaLetter> consonants;

  @override
  Widget build(BuildContext context) {
    // Tiles grow with the text size so large text never overflows.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final tileHeight = AppSpacing.lg + AppSizes.gridTileBaseHeight * scale;

    SliverGrid grid(List<KannadaLetter> letters) => SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent:
            AppSizes.gridTileMaxWidth *
            scale.clamp(AppTextScale.min, AppTextScale.max),
        mainAxisExtent: tileHeight,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: letters.length,
      itemBuilder: (context, i) => _LetterTile(letter: letters[i]),
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList.list(
            children: [
              const SectionHeader(title: 'Vowels', kannada: 'ಸ್ವರಗಳು'),
              Text(
                'Tap a letter to see it larger.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: grid(vowels),
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(title: 'Consonants', kannada: 'ವ್ಯಂಜನಗಳು'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          sliver: grid(consonants),
        ),
      ],
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({required this.letter});

  final KannadaLetter letter;

  void _showLarge(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                letter.letter,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sounds like "${letter.sound}"',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${letter.letter}, sounds like ${letter.sound}',
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showLarge(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    letter.letter,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    letter.sound,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhrasesTab extends StatelessWidget {
  const _PhrasesTab({required this.phrases});

  final List<KannadaPhrase> phrases;

  @override
  Widget build(BuildContext context) {
    // Flatten into headers and phrases so the list can be built lazily.
    final rows = <Object>[];
    for (final category in PhraseCategory.values) {
      final inCategory = phrases.where((p) => p.category == category);
      if (inCategory.isEmpty) continue;
      rows
        ..add(category)
        ..addAll(inCategory);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: rows.length,
      itemBuilder: (context, i) => switch (rows[i]) {
        final PhraseCategory c => SectionHeader(
          title: c.label,
          kannada: c.kannada,
        ),
        final KannadaPhrase p => _PhraseCard(phrase: p),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({required this.phrase});

  final KannadaPhrase phrase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(phrase.kannada, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              phrase.pronunciation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              phrase.meaning,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumbersTab extends StatelessWidget {
  const _NumbersTab({required this.numbers});

  final List<KannadaNumber> numbers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: numbers.length,
      itemBuilder: (context, i) {
        final n = numbers[i];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.leadingLabel,
                  ),
                  child: Text(
                    n.numeral,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.word, style: theme.textTheme.titleLarge),
                      Text(
                        n.pronunciation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text('${n.value}', style: theme.textTheme.titleLarge),
              ],
            ),
          ),
        );
      },
    );
  }
}
