import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/state_views.dart';
import '../ar_feature.dart';
import '../ar_providers.dart';
import '../domain/hunt_models.dart';
import '../domain/hunt_rules.dart';
import 'state/hunt_notifier.dart';
import 'widgets/ar_camera_view.dart';
import 'widgets/hunt_widgets.dart';

/// The hunt itself: the live camera with the score and heat meter over it.
class HuntPage extends ConsumerWidget {
  const HuntPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    resizeToAvoidBottomInset: false,
    body: AsyncValueView<HuntSnapshot>(
      value: ref.watch(huntSnapshotProvider),
      onRetry: () => ref.invalidate(huntSnapshotProvider),
      data: (snapshot) => _HuntBody(snapshot: snapshot),
    ),
  );
}

class _HuntBody extends ConsumerStatefulWidget {
  const _HuntBody({required this.snapshot});

  final HuntSnapshot snapshot;

  @override
  ConsumerState<_HuntBody> createState() => _HuntBodyState();
}

class _HuntBodyState extends ConsumerState<_HuntBody> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(() {
        if (mounted) ref.read(huntProvider.notifier).begin(widget.snapshot);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(huntProvider.notifier);
    final phase = ref.watch(huntProvider.select((state) => state.phase));
    final failure = ref.watch(huntProvider.select((state) => state.failure));
    if (failure != null) {
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
        ArCameraView(placing: false, onScene: notifier.attach),
        GestureDetector(
          key: const ValueKey('ar-tap-layer'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) =>
              notifier.tap(details.localPosition.dx, details.localPosition.dy),
        ),
        SafeArea(
          child: switch (phase) {
            HuntPhase.scanning => const _ScanningHud(),
            HuntPhase.hunting => const _HuntingHud(),
            HuntPhase.finished => const _FinishedHud(),
          },
        ),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(huntProvider.select((state) => state.points));
    final found = ref.watch(huntProvider.select((state) => state.foundCount));
    final total = ref.watch(huntProvider.select((state) => state.totalCount));
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton.filledTonal(
            tooltip: 'Leave the hunt',
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ArChip(icon: Icons.star, label: '$points pts'),
                ArChip(icon: Icons.search, label: '$found/$total found'),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filledTonal(
            tooltip: 'Scan a poster again',
            icon: const Icon(Icons.center_focus_weak),
            onPressed: ref.read(huntProvider.notifier).rescan,
          ),
        ],
      ),
    );
  }
}

class _ScanningHud extends ConsumerWidget {
  const _ScanningHud();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(huntProvider);
    return Column(
      children: [
        const _TopBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ArMessageBanner(message: state.message),
        ),
        Expanded(
          child: ScanOverlay(
            progress: state.lockProgress,
            tooFar: state.posterTooFar,
            tracking: state.tracking,
            title: 'Posters look like these, one on each start point.',
          ),
        ),
      ],
    );
  }
}

class _HuntingHud extends ConsumerWidget {
  const _HuntingHud();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(huntProvider.select((state) => state.message));
    return Column(
      children: [
        const _TopBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ArMessageBanner(message: message),
        ),
        const Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              reverse: true,
              padding: EdgeInsets.all(AppSpacing.md),
              child: _HeatPanel(),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeatPanel extends ConsumerWidget {
  const _HeatPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(huntProvider);
    final textTheme = Theme.of(context).textTheme;
    final hint = trackingHint(state.tracking);
    final heat = state.heat;
    final bearing = state.bearing;
    final hasNearest = heat != null;
    final nearby =
        bearing != null &&
        state.nearestDistance != null &&
        state.nearestDistance! <= huntVisibleRadiusMetres;
    return ArPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) ...[
            Text(
              hint,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.onArPanel),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (hasNearest)
            Row(
              children: [
                if (nearby)
                  Transform.rotate(
                    angle: bearing,
                    child: const Icon(
                      Icons.navigation,
                      color: AppColors.diwaliGold,
                      semanticLabel: 'Direction to the nearest item',
                    ),
                  )
                else
                  const Icon(
                    Icons.device_thermostat,
                    color: AppColors.diwaliGold,
                  ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      heat.label,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.onArPanel,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              state.leftHere == 0
                  ? _elsewhere(ref)
                  : 'Walk around to find what is hidden here.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.onArPanel),
            ),
          if (hasNearest && state.nearestHint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Clue: ${state.nearestHint}',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.onArPanel),
            ),
          ],
          if (state.canCollect) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: const ValueKey('collect-nearest'),
              onPressed: ref.read(huntProvider.notifier).collectNearest,
              icon: const Icon(Icons.pan_tool_alt_outlined),
              label: Text('Collect this ${state.nearestKind?.label ?? 'item'}'),
            ),
          ],
        ],
      ),
    );
  }

  String _elsewhere(WidgetRef ref) {
    final next = ref.read(huntProvider.notifier).nextZone();
    return next == null
        ? 'All found here.'
        : 'All found here. Head to ${next.label} and scan its poster.';
  }
}

class _FinishedHud extends ConsumerWidget {
  const _FinishedHud();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(huntProvider);
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ArPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.celebration,
                size: AppIconSizes.hero,
                color: AppColors.diwaliGold,
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                header: true,
                child: Text(
                  'You found them all!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.onArPanel,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                state.message ??
                    'Happy Rajyotsava and happy Deepavali. '
                        'You scored ${state.points} points.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.onArPanel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  final router = GoRouter.of(context);
                  ref.invalidate(huntLeadersProvider);
                  router.pop();
                  router.push<void>(ArRoutes.celebration).ignore();
                },
                child: const Text('See the leaderboard'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
