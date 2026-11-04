import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/feature_module.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../games_providers.dart';

/// Games tab: one rounded box per game, stacked vertically. The boxes come
/// from features that register an entry with `group: FeatureGroups.games`.
/// Background music plays while the Games tab is active and visible.
class GamesPage extends ConsumerStatefulWidget {
  const GamesPage({super.key});

  @override
  ConsumerState<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends ConsumerState<GamesPage> {
  late final AppLifecycleListener _lifecycle;
  late final GamesAudioController _audioController;
  var _foreground = true;

  @override
  void initState() {
    super.initState();
    _audioController = ref.read(gamesAudioStateProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        _report();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _report();
  }

  void _report() {
    final visible =
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _audioController.setTabVisible(visible);
      }
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    final controller = _audioController;
    scheduleMicrotask(() => controller.setTabVisible(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final games = [
      for (final m in ref.watch(featureModulesProvider))
        if (m.entry?.group == FeatureGroups.games) m.entry!,
    ]..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        actions: const [_GamesAudioMuteButton()],
      ),
      body: SafeArea(
        child: games.isEmpty
            ? const EmptyView(
                message: 'No games yet.',
                icon: Icons.sports_esports_outlined,
              )
            : ConstrainedBody(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Boxes share the screen height equally, but never
                    // shrink below their content: with large text or a
                    // short screen the list scrolls instead of overflowing.
                    const padding = EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      // Keeps the last box clear of the floating bar.
                      AppSizes.floatingBarClearance,
                    );
                    final share =
                        (constraints.maxHeight -
                            padding.vertical -
                            AppSpacing.md * (games.length - 1)) /
                        games.length;
                    return ListView.separated(
                      padding: padding,
                      itemCount: games.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) => ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: share.clamp(
                            AppSizes.minTouchTarget,
                            double.infinity,
                          ),
                        ),
                        child: _GameBox(entry: games[i]),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _GamesAudioMuteButton extends ConsumerWidget {
  const _GamesAudioMuteButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(gamesAudioStateProvider);
    if (!audioState.available) return const SizedBox.shrink();
    final muted = audioState.muted;
    return IconButton(
      key: const ValueKey('games-audio-mute'),
      tooltip: muted ? 'Play audio' : 'Mute audio',
      isSelected: muted,
      onPressed: ref.read(gamesAudioStateProvider.notifier).toggleMute,
      icon: const Icon(Icons.volume_up),
      selectedIcon: const Icon(Icons.volume_off),
    );
  }
}

class _GameBox extends ConsumerWidget {
  const _GameBox({required this.entry});

  final FeatureEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final controller = ref.read(gamesAudioStateProvider.notifier);
          controller.setRouteActive(false);
          try {
            await context.push(entry.path);
          } finally {
            controller.setRouteActive(true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(entry.icon, size: AppIconSizes.lg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: theme.textTheme.titleLarge),
                    Text(
                      entry.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
