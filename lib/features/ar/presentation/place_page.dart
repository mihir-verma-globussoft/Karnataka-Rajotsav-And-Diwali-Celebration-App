import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/state_views.dart';
import '../ar_providers.dart';
import '../domain/hunt_models.dart';
import '../domain/hunt_rules.dart';
import 'state/place_notifier.dart';
import 'widgets/ar_camera_view.dart';
import 'widgets/hunt_widgets.dart';

/// The admin's placing tool: stand where an item should go and tap the spot.
/// The server refuses anyone who is not an admin, whatever this screen shows.
class PlacePage extends ConsumerWidget {
  const PlacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    resizeToAvoidBottomInset: false,
    body: AsyncValueView<HuntSnapshot>(
      value: ref.watch(huntSnapshotProvider),
      onRetry: () => ref.invalidate(huntSnapshotProvider),
      data: (snapshot) => snapshot.isAdmin
          ? _PlaceBody(snapshot: snapshot)
          : const EmptyView(
              message: 'Only hunt admins can place items.',
              icon: Icons.lock_outline,
            ),
    ),
  );
}

class _PlaceBody extends ConsumerStatefulWidget {
  const _PlaceBody({required this.snapshot});

  final HuntSnapshot snapshot;

  @override
  ConsumerState<_PlaceBody> createState() => _PlaceBodyState();
}

class _PlaceBodyState extends ConsumerState<_PlaceBody> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(() {
        if (mounted) ref.read(placeProvider.notifier).begin(widget.snapshot);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(placeProvider.notifier);
    final state = ref.watch(placeProvider);
    if (state.failure != null) {
      return SafeArea(
        child: ErrorView(
          error: const UnexpectedFailure(
            'AR could not start on this phone. Please go back and try again.',
          ),
          onRetry: () => context.pop(),
          retryLabel: 'Go back',
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ArCameraView(placing: true, onScene: notifier.attach),
        GestureDetector(
          key: const ValueKey('ar-tap-layer'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) =>
              notifier.tap(details.localPosition.dx, details.localPosition.dy),
        ),
        SafeArea(
          child: Padding(
            // The keyboard covers the camera instead of resizing it.
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              children: [
                _PlaceTopBar(state: state),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: ArMessageBanner(message: state.message),
                ),
                Expanded(
                  child: state.scanning
                      ? ScanOverlay(
                          progress: state.lockProgress,
                          tooFar: state.posterTooFar,
                          tracking: state.tracking,
                          title:
                              'Items are saved against this poster, so stick '
                              'it up first and leave it there.',
                        )
                      : Align(
                          alignment: Alignment.bottomCenter,
                          child: SingleChildScrollView(
                            reverse: true,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: ArPanel(child: _panelFor(state)),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _panelFor(PlaceViewState state) {
    if (state.draft != null) return const _DraftPanel();
    if (state.selected != null) return const _SelectedPanel();
    return const _IdlePanel();
  }
}

class _PlaceTopBar extends ConsumerWidget {
  const _PlaceTopBar({required this.state});

  final PlaceViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = state.zone;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton.filledTonal(
            tooltip: 'Finish placing',
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Center(
              child: ArChip(
                icon: Icons.place_outlined,
                label: zone == null
                    ? 'Scan a poster'
                    : '${zone.label}: ${state.items.length} placed',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filledTonal(
            tooltip: 'Use another poster',
            icon: const Icon(Icons.center_focus_weak),
            onPressed: ref.read(placeProvider.notifier).rescan,
          ),
        ],
      ),
    );
  }
}

class _KindPicker extends ConsumerWidget {
  const _KindPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(placeProvider.select((state) => state.kind));
    return SegmentedButton<HuntItemKind>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: HuntItemKind.diya,
          label: Text('Diya'),
          icon: HuntItemArt(HuntItemKind.diya, size: AppIconSizes.xs),
        ),
        ButtonSegment(
          value: HuntItemKind.flag,
          label: Text('Flag'),
          icon: HuntItemArt(HuntItemKind.flag, size: AppIconSizes.xs),
        ),
      ],
      selected: {kind},
      onSelectionChanged: (selection) =>
          ref.read(placeProvider.notifier).setKind(selection.first),
    );
  }
}

class _IdlePanel extends ConsumerWidget {
  const _IdlePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(placeProvider);
    final text = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.onArPanel);
    final tracking = trackingHint(state.tracking);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _KindPicker(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          tracking ??
              'Tap a table, shelf or wall to place a ${state.kind.label}. '
                  'Tap one you placed to remove it.',
          style: text,
        ),
      ],
    );
  }
}

class _DraftPanel extends ConsumerStatefulWidget {
  const _DraftPanel();

  @override
  ConsumerState<_DraftPanel> createState() => _DraftPanelState();
}

class _DraftPanelState extends ConsumerState<_DraftPanel> {
  final _hint = TextEditingController();

  @override
  void dispose() {
    _hint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeProvider);
    final notifier = ref.read(placeProvider.notifier);
    final text = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.onArPanel);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _KindPicker(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          state.draft?.onSurface ?? true
              ? 'Happy with this spot? Tap somewhere else to move it.'
              : 'Nothing to rest on there, so it is floating about a metre '
                    'ahead and will stay exactly there. Tap something nearby '
                    'to rest it on that instead.',
          style: text,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Size: ${(state.scale * 100).round()}%', style: text),
        Slider(
          key: const ValueKey('draft-size'),
          value: state.scale,
          min: huntItemMinScale,
          max: huntItemMaxScale,
          divisions: huntItemScaleSteps,
          label: '${(state.scale * 100).round()}%',
          semanticFormatterCallback: (value) => '${(value * 100).round()}%',
          onChanged: state.saving ? null : notifier.setScale,
        ),
        TextField(
          controller: _hint,
          maxLength: 120,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Clue for players (optional)',
            hintText: 'Near the coffee machine',
          ),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton(
              onPressed: state.saving ? null : notifier.cancelDraft,
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('save-draft'),
              onPressed: state.saving
                  ? null
                  : () => notifier.saveDraft(_hint.text),
              child: Text(state.saving ? 'Saving…' : 'Save here'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectedPanel extends ConsumerWidget {
  const _SelectedPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(placeProvider);
    final notifier = ref.read(placeProvider.notifier);
    final item = state.selected;
    if (item == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.onArPanel);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Remove this ${item.kind.label}? Points already earned from it stay.',
          style: text,
        ),
        if (item.hint != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('Clue: ${item.hint}', style: text),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton(
              onPressed: state.saving ? null : notifier.clearSelection,
              child: const Text('Keep it'),
            ),
            FilledButton(
              key: const ValueKey('remove-selected'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: state.saving ? null : notifier.removeSelected,
              child: Text(state.saving ? 'Removing…' : 'Remove'),
            ),
          ],
        ),
      ],
    );
  }
}
