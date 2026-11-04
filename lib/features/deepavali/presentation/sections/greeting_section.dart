import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_providers.dart';
import '../../domain/greeting.dart';
import '../../domain/sound.dart';
import '../state/feedback.dart';
import '../state/greeting_notifier.dart';
import '../theme/diwali_palette.dart';
import '../widgets/customize_card_sheet.dart';
import '../widgets/diwali_button.dart';
import '../widgets/diwali_card.dart';
import '../widgets/greeting_card_view.dart';
import '../widgets/picture_capture.dart';
import '../widgets/section_header.dart';

/// Pick a design, write a wish and share the card as a picture.
class GreetingSection extends ConsumerStatefulWidget {
  const GreetingSection({super.key});

  @override
  ConsumerState<GreetingSection> createState() => _GreetingSectionState();
}

class _GreetingSectionState extends ConsumerState<GreetingSection> {
  final GlobalKey _boundary = GlobalKey(debugLabel: 'greeting');
  bool _exporting = false;

  /// Widest the card is drawn.
  static const double _maxCardWidth = 340;

  /// Widest a design thumbnail is drawn.
  static const double _maxThumbWidth = 76;

  Future<void> _share() async {
    final sharer = ref.read(imageSharerProvider);
    if (sharer == null || _exporting) return;
    setState(() => _exporting = true);
    await shareBoundaryPicture(
      sharer: sharer,
      boundary: _boundary,
      fileName: 'deepavali-greeting.png',
      text: greetingShareText,
      messenger: ScaffoldMessenger.maybeOf(context),
      onRetry: () => unawaited(_share()),
    );
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final card = ref.watch(greetingProvider);
    final notifier = ref.read(greetingProvider.notifier);
    final canShare = ref.watch(imageSharerProvider) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Greeting Card',
          subtitle: 'Create and share a wish',
        ),
        const SizedBox(height: AppSpacing.md),
        DiwaliCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxCardWidth),
                  child: RepaintBoundary(
                    key: _boundary,
                    child: GreetingCardView(card: card),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                label: 'Card design',
                container: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < GreetingDesign.values.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxThumbWidth,
                          ),
                          child: _DesignThumb(
                            design: GreetingDesign.values[i],
                            selected: GreetingDesign.values[i] == card.design,
                            onTap: () {
                              ref
                                  .read(diwaliFeedbackProvider)
                                  .both(Haptic.selection, Sfx.tap);
                              notifier.setDesign(GreetingDesign.values[i]);
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // The thumbnails already announce which design is selected.
              ExcludeSemantics(
                child: Text(
                  card.design.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: DiwaliPalette.gold),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  DiwaliButton(
                    label: 'Customise message',
                    icon: Icons.edit_outlined,
                    kind: DiwaliButtonKind.secondary,
                    onPressed: () => unawaited(showCustomizeCardSheet(context)),
                  ),
                  if (canShare)
                    DiwaliButton(
                      label: _exporting ? 'Preparing…' : 'Share card',
                      icon: Icons.ios_share,
                      onPressed: _exporting ? null : _share,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesignThumb extends StatelessWidget {
  const _DesignThumb({
    required this.design,
    required this.selected,
    required this.onTap,
  });

  final GreetingDesign design;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: selected ? '${design.label}, selected' : design.label,
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selected ? DiwaliPalette.gold : DiwaliPalette.goldBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: ClipRRect(
              borderRadius: AppRadius.smAll,
              child: AspectRatio(
                aspectRatio: GreetingCardView.aspect,
                child: GreetingBackground(design: design),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
