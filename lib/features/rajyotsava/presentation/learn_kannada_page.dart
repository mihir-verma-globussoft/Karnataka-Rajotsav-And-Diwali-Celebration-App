import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/models.dart';
import '../rajyotsava_providers.dart';
import 'widgets/listen_button.dart';
import 'widgets/rajyotsava_widgets.dart';
import 'widgets/secret_tap.dart';

/// Learn Kannada: alphabet, everyday phrases and numbers, in three tabs,
/// each with a Kannada voice-over.
class LearnKannadaPage extends ConsumerWidget {
  const LearnKannadaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(rajyotsavaContentProvider);
    // Keeps the speaker alive while this screen is open; leaving the screen
    // disposes it, which stops any speech.
    ref.watch(kannadaSpeakerProvider);
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

    SliverGrid grid(List<KannadaLetter> letters, _LetterTone tone) =>
        SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent:
                AppSizes.gridTileMaxWidth *
                scale.clamp(AppTextScale.min, AppTextScale.max),
            mainAxisExtent: tileHeight,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
          ),
          itemCount: letters.length,
          itemBuilder: (context, i) =>
              _LetterTile(letters: letters, index: i, tone: tone),
        );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList.list(
            children: [
              // Secret: tap the heading 5 times.
              const SecretTap(
                child: SectionHeader(title: 'Vowels', kannada: 'ಸ್ವರಗಳು'),
              ),
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
          sliver: grid(vowels, _LetterTone.vowel),
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
          sliver: grid(consonants, _LetterTone.consonant),
        ),
      ],
    );
  }
}

/// Which colour family a letter tile uses: the Kannada flag's yellow for
/// vowels and red for consonants.
enum _LetterTone { vowel, consonant }

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letters,
    required this.index,
    required this.tone,
  });

  /// The whole group, so the sheet can step to the previous and next letter.
  final List<KannadaLetter> letters;
  final int index;
  final _LetterTone tone;

  KannadaLetter get letter => letters[index];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (tone) {
      _LetterTone.vowel => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      _LetterTone.consonant => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };
    return Semantics(
      button: true,
      label: '${letter.letter}, sounds like ${letter.sound}',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            // Grows to fit the letter and scrolls on short screens
            // (landscape, large text) instead of overflowing.
            isScrollControlled: true,
            builder: (_) =>
                _LetterSheet(letters: letters, start: index, tone: tone),
          ),
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
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    letter.sound,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foreground,
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

/// Full-width sheet showing one letter large, with Listen and arrows to the
/// previous and next letter of the same group.
class _LetterSheet extends StatefulWidget {
  const _LetterSheet({
    required this.letters,
    required this.start,
    required this.tone,
  });

  final List<KannadaLetter> letters;
  final int start;
  final _LetterTone tone;

  @override
  State<_LetterSheet> createState() => _LetterSheetState();
}

class _LetterSheetState extends State<_LetterSheet> {
  late int _index = widget.start;

  void _go(int step) =>
      setState(() => _index = (_index + step) % widget.letters.length);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final letter = widget.letters[_index];
    final (ring, onRing) = switch (widget.tone) {
      _LetterTone.vowel => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      _LetterTone.consonant => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };
    return SafeArea(
      child: SingleChildScrollView(
        child: SizedBox(
          // Material 3 sheets shrink to their content unless it asks for the
          // full width.
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.tone == _LetterTone.vowel
                      ? 'Vowel · ಸ್ವರ'
                      : 'Consonant · ವ್ಯಂಜನ',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Previous letter',
                      onPressed: () => _go(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: AppDurations.fast,
                          child: DecoratedBox(
                            key: ValueKey(letter.letter),
                            decoration: BoxDecoration(
                              color: ring,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Text(
                                letter.letter,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: onRing,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Next letter',
                      onPressed: () => _go(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sounds like "${letter.sound}"',
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  '${_index + 1} of ${widget.letters.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ListenButton(text: letter.letter, label: 'Listen'),
                ),
              ],
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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
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
            ListenButton(text: phrase.kannada),
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
                ListenButton(text: n.word),
              ],
            ),
          ),
        );
      },
    );
  }
}
