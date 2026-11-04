import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../deepavali_providers.dart';
import '../../domain/decoration.dart';
import '../../domain/sound.dart';
import '../state/decor_notifier.dart';
import '../state/feedback.dart';
import '../theme/diwali_palette.dart';
import '../theme/diwali_theme.dart';
import '../widgets/diwali_button.dart';
import '../widgets/diwali_motion.dart';
import '../widgets/glow_background.dart';
import '../widgets/house_art.dart';
import '../widgets/object_art.dart';
import '../widgets/picture_capture.dart';

/// Full-screen "decorate your home": add lamps, lanterns and garlands, drag
/// them into place and share the picture.
class DecorateScreen extends StatelessWidget {
  const DecorateScreen({super.key});

  @override
  Widget build(BuildContext context) => Theme(
    data: DiwaliTheme.data,
    child: const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: DiwaliMotionScope(child: _DecorateBody()),
    ),
  );
}

class _DecorateBody extends ConsumerStatefulWidget {
  const _DecorateBody();

  @override
  ConsumerState<_DecorateBody> createState() => _DecorateBodyState();
}

class _DecorateBodyState extends ConsumerState<_DecorateBody> {
  final GlobalKey _boundary = GlobalKey(debugLabel: 'decorate');
  bool _exporting = false;

  /// Widest the house picture is drawn.
  static const double _maxSide = 420;

  Future<void> _confirmClear() async {
    final notifier = ref.read(decorProvider.notifier);
    final clear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear the house?'),
        content: const Text('All decorations will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep them'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear ?? false) notifier.clear();
  }

  Future<void> _share() async {
    final sharer = ref.read(imageSharerProvider);
    if (sharer == null || _exporting) return;
    setState(() => _exporting = true);
    await shareBoundaryPicture(
      sharer: sharer,
      boundary: _boundary,
      fileName: 'my-decorated-home.png',
      text: 'My Deepavali home',
      messenger: ScaffoldMessenger.maybeOf(context),
      onRetry: () => unawaited(_share()),
    );
    if (mounted) setState(() => _exporting = false);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(decorProvider);
    final notifier = ref.read(decorProvider.notifier);
    final text = Theme.of(context).textTheme;
    final canShare = ref.watch(imageSharerProvider) != null;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: GlowBackground()),
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBody(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            onPressed: _back,
                            icon: const Icon(Icons.arrow_back),
                          ),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                'Decorate your home',
                                style: text.titleLarge?.copyWith(
                                  color: DiwaliPalette.gold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        state.isEmpty
                            ? 'Tap a decoration below to add it, then drag it '
                                  'where you like.'
                            : 'Drag a decoration to move it. Tap one to select '
                                  'it.',
                        style: text.bodyMedium?.copyWith(
                          color: DiwaliPalette.creamMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: _maxSide),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: AppRadius.lgAll,
                              child: _Canvas(
                                state: state,
                                boundaryKey: _boundary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Semantics(
                        label: 'Decorations',
                        container: true,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final kind in DecorKind.values)
                              _PaletteButton(
                                kind: kind,
                                onTap: state.isFull
                                    ? null
                                    : () {
                                        ref
                                            .read(diwaliFeedbackProvider)
                                            .both(Haptic.selection, Sfx.tap);
                                        notifier.add(kind);
                                      },
                              ),
                          ],
                        ),
                      ),
                      if (state.isFull)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            'The house is full. Remove something to add more.',
                            textAlign: TextAlign.center,
                            style: text.bodySmall?.copyWith(
                              color: DiwaliPalette.saffron,
                            ),
                          ),
                        ),
                      if (state.selected != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _SelectedControls(
                          kind: state.selected!.kind,
                          onNudge: notifier.nudge,
                          onRemove: notifier.removeSelected,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          DiwaliButton(
                            label: 'Clear',
                            icon: Icons.restart_alt,
                            kind: DiwaliButtonKind.tertiary,
                            onPressed: state.isEmpty
                                ? null
                                : () => unawaited(_confirmClear()),
                          ),
                          if (canShare)
                            DiwaliButton(
                              label: _exporting ? 'Preparing…' : 'Share image',
                              icon: Icons.ios_share,
                              onPressed: state.isEmpty || _exporting
                                  ? null
                                  : _share,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The house with its decorations. Each decoration can be dragged. Only the
/// house and decorations are inside the capture boundary: the gold selection
/// ring is drawn over it, so shared pictures never show it.
class _Canvas extends ConsumerWidget {
  const _Canvas({required this.state, required this.boundaryKey});

  final DecorState state;
  final GlobalKey boundaryKey;

  /// A decoration's side as a fraction of the picture.
  static const double _itemScale = 0.2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(decorProvider.notifier);
    return LayoutBuilder(
      builder: (context, c) {
        final side = c.maxWidth;
        final item = side * _itemScale;
        final selected = state.selected;
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                key: boundaryKey,
                child: Stack(
                  children: [
                    const Positioned.fill(child: HouseArt()),
                    for (final d in state.items)
                      Positioned(
                        key: ValueKey(d.id),
                        left: d.x * side - item / 2,
                        top: d.y * side - item / 2,
                        width: item,
                        height: item,
                        child: Semantics(
                          button: true,
                          selected: d.id == state.selectedId,
                          label:
                              '${d.kind.label} decoration'
                              '${d.id == state.selectedId ? ', selected' : ''}',
                          excludeSemantics: true,
                          onTap: () => notifier.select(d.id),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => notifier.select(d.id),
                            onPanStart: (_) => notifier.select(d.id),
                            onPanUpdate: (u) {
                              final current = ref
                                  .read(decorProvider)
                                  .byId(d.id);
                              if (current == null) return;
                              notifier.moveTo(
                                d.id,
                                current.x + u.delta.dx / side,
                                current.y + u.delta.dy / side,
                              );
                            },
                            child: ObjectArt(id: d.kind.id, revealed: true),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (selected != null)
              Positioned(
                left: selected.x * side - item / 2,
                top: selected.y * side - item / 2,
                width: item,
                height: item,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: DiwaliPalette.gold),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({required this.kind, required this.onTap});

  final DecorKind kind;
  final VoidCallback? onTap;

  /// Size of the little picture on a palette button.
  static const double _art = 40;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: 'Add ${kind.label}',
    excludeSemantics: true,
    onTap: onTap,
    child: Opacity(
      opacity: onTap == null ? AppOpacity.disabled : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.minTouchTarget,
            minHeight: AppSizes.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: _art,
                  child: ObjectArt(id: kind.id, revealed: true),
                ),
                Text(kind.label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Arrow buttons and Remove for the selected decoration, so everything done
/// by dragging can also be done with taps.
class _SelectedControls extends StatelessWidget {
  const _SelectedControls({
    required this.kind,
    required this.onNudge,
    required this.onRemove,
  });

  final DecorKind kind;
  final ValueChanged<DecorDirection> onNudge;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    Widget arrow(DecorDirection d, IconData icon, String label) => IconButton(
      tooltip: 'Move $label',
      onPressed: () => onNudge(d),
      icon: Icon(icon),
      constraints: const BoxConstraints(
        minWidth: AppSizes.minTouchTarget,
        minHeight: AppSizes.minTouchTarget,
      ),
    );
    return Column(
      children: [
        Text(
          'Selected: ${kind.label}',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: DiwaliPalette.gold),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            arrow(DecorDirection.left, Icons.arrow_back, 'left'),
            arrow(DecorDirection.up, Icons.arrow_upward, 'up'),
            arrow(DecorDirection.down, Icons.arrow_downward, 'down'),
            arrow(DecorDirection.right, Icons.arrow_forward, 'right'),
            DiwaliButton(
              label: 'Remove',
              icon: Icons.delete_outline,
              kind: DiwaliButtonKind.tertiary,
              onPressed: onRemove,
            ),
          ],
        ),
      ],
    );
  }
}
