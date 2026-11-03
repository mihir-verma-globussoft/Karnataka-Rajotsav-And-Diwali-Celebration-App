import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_providers.dart';
import '../../domain/greeting.dart';
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
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final d in GreetingDesign.values)
                      _DesignThumb(
                        design: d,
                        selected: d == card.design,
                        onTap: () => notifier.setDesign(d),
                      ),
                  ],
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

  /// Width of a thumbnail (its height follows the card's 4:5 shape).
  static const double _width = 56;

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
              child: SizedBox(
                width: _width,
                child: AspectRatio(
                  aspectRatio: GreetingCardView.aspect,
                  child: GreetingBackground(design: design),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
