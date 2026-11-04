import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_providers.dart';
import '../../domain/rangoli_geometry.dart';
import '../../domain/sound.dart';
import '../state/feedback.dart';
import '../state/rangoli_notifier.dart';
import '../theme/diwali_palette.dart';
import '../theme/rangoli_palette.dart';
import '../widgets/diwali_button.dart';
import '../widgets/diwali_card.dart';
import '../widgets/picture_capture.dart';
import '../widgets/rangoli_canvas.dart';
import '../widgets/section_header.dart';

/// Tap a shape to colour it; symmetry mirrors it round the mandala.
class RangoliSection extends ConsumerStatefulWidget {
  const RangoliSection({super.key});

  @override
  ConsumerState<RangoliSection> createState() => _RangoliSectionState();
}

class _RangoliSectionState extends ConsumerState<RangoliSection> {
  final GlobalKey _boundary = GlobalKey(debugLabel: 'rangoli');
  bool _exporting = false;

  Future<void> _confirmReset() async {
    final notifier = ref.read(rangoliProvider.notifier);
    if (ref.read(rangoliProvider).isEmpty) return;
    final clear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear your rangoli?'),
        content: const Text('You can bring it back with Undo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear ?? false) notifier.reset();
  }

  Future<void> _share() async {
    final sharer = ref.read(imageSharerProvider);
    if (sharer == null || _exporting) return;
    setState(() => _exporting = true);
    await shareBoundaryPicture(
      sharer: sharer,
      boundary: _boundary,
      fileName: 'my-rangoli.png',
      text: 'My Deepavali rangoli',
      messenger: ScaffoldMessenger.maybeOf(context),
      onRetry: () => unawaited(_share()),
    );
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rangoliProvider);
    final notifier = ref.read(rangoliProvider.notifier);
    final text = Theme.of(context).textTheme;
    final canShare = ref.watch(imageSharerProvider) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Rangoli Studio',
          subtitle: 'Tap a shape to colour it',
        ),
        const SizedBox(height: AppSpacing.md),
        DiwaliCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RangoliCanvas(
                cells: state.cells,
                onCell: (i) {
                  ref
                      .read(diwaliFeedbackProvider)
                      .both(Haptic.selection, Sfx.tap);
                  notifier.tapCell(i);
                },
                boundaryKey: _boundary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  state.isEmpty
                      ? 'Tap a shape to begin.'
                      : '${state.paintedCount} of '
                            '${RangoliGeometry.cellCount} shapes coloured.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: DiwaliPalette.creamMuted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PaletteRow(
                selected: state.colour,
                onSelect: (c) {
                  ref.read(diwaliFeedbackProvider).haptic(Haptic.selection);
                  notifier.select(c);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Symmetry', style: text.bodyMedium),
                subtitle: Text(
                  state.symmetry
                      ? 'Each tap colours four matching shapes'
                      : 'Each tap colours one shape',
                  style: text.bodySmall?.copyWith(
                    color: DiwaliPalette.creamMuted,
                  ),
                ),
                value: state.symmetry,
                activeThumbColor: DiwaliPalette.gold,
                onChanged: (v) => notifier.setSymmetry(on: v),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  DiwaliButton(
                    label: 'Random',
                    icon: Icons.casino_outlined,
                    kind: DiwaliButtonKind.secondary,
                    onPressed: () {
                      ref
                          .read(diwaliFeedbackProvider)
                          .both(Haptic.light, Sfx.tap);
                      notifier.randomize();
                    },
                  ),
                  DiwaliButton(
                    label: 'Undo',
                    icon: Icons.undo,
                    kind: DiwaliButtonKind.secondary,
                    onPressed: state.canUndo ? notifier.undo : null,
                  ),
                  DiwaliButton(
                    label: 'Reset',
                    icon: Icons.restart_alt,
                    kind: DiwaliButtonKind.tertiary,
                    onPressed: state.isEmpty
                        ? null
                        : () => unawaited(_confirmReset()),
                  ),
                  if (canShare)
                    DiwaliButton(
                      label: _exporting ? 'Preparing…' : 'Share image',
                      icon: Icons.ios_share,
                      onPressed: state.isEmpty || _exporting ? null : _share,
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

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.selected, required this.onSelect});

  final int? selected;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Colour palette',
    container: true,
    child: Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < RangoliPalette.colours.length; i++)
          _Swatch(
            label: RangoliPalette.colours[i].name,
            color: RangoliPalette.colours[i].color,
            selected: selected == i,
            onTap: () => onSelect(i),
          ),
        _Swatch(
          label: 'Eraser',
          color: null,
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
      ],
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// Null draws the eraser.
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: selected ? '$label, selected' : label,
    excludeSemantics: true,
    onTap: onTap,
    child: InkResponse(
      onTap: onTap,
      radius: AppSizes.minTouchTarget / 2,
      child: SizedBox.square(
        dimension: AppSizes.minTouchTarget,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? DiwaliPalette.gold : AppColors.transparent,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color ?? DiwaliPalette.surfaceHigh,
                  border: Border.all(color: DiwaliPalette.goldBorder),
                ),
                child: SizedBox.square(
                  dimension: AppIconSizes.md,
                  child: color == null
                      ? const Icon(
                          Icons.close,
                          size: AppIconSizes.xs,
                          color: DiwaliPalette.cream,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
