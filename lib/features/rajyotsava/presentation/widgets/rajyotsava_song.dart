import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../rajyotsava_providers.dart';

/// Tells the song controller whether the Rajyotsava tab is on screen: the
/// selected tab, with no sub-screen on top and the app in the foreground.
/// Switching to another tab, opening a sub-screen or leaving the app pauses
/// the song.
class RajyotsavaSongScope extends ConsumerStatefulWidget {
  const RajyotsavaSongScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RajyotsavaSongScope> createState() =>
      _RajyotsavaSongScopeState();
}

class _RajyotsavaSongScopeState extends ConsumerState<RajyotsavaSongScope> {
  late final AppLifecycleListener _lifecycle;
  late final RajyotsavaSongController _song;
  var _foreground = true;

  @override
  void initState() {
    super.initState();
    _song = ref.read(rajyotsavaSongProvider.notifier);
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
    // Visibility.of: the shell hides inactive tabs with Visibility.
    // isCurrentOf: false while a sub-screen is pushed on top.
    final visible =
        _foreground &&
        Visibility.of(context) &&
        (ModalRoute.isCurrentOf(context) ?? true);
    // Providers cannot change while widgets are building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _song.setTabVisible(visible);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    final song = _song;
    scheduleMicrotask(() => song.setTabVisible(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Mute button for the tab's song, at the top right of the banner. Hidden
/// when no song file is bundled.
class SongMuteButton extends ConsumerWidget {
  const SongMuteButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rajyotsavaSongProvider);
    if (!state.available) return const SizedBox.shrink();
    final muted = state.muted;
    return IconButton(
      key: const ValueKey('song-mute'),
      tooltip: muted ? 'Play song' : 'Mute song',
      isSelected: muted,
      onPressed: ref.read(rajyotsavaSongProvider.notifier).toggleMute,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.onBanner.withValues(alpha: AppOpacity.faint),
      ),
      icon: const Icon(Icons.volume_up, color: AppColors.onBanner),
      selectedIcon: const Icon(Icons.volume_off, color: AppColors.onBanner),
    );
  }
}

/// "Now playing" credit on the banner, shown while the song plays.
class SongNowPlaying extends ConsumerWidget {
  const SongNowPlaying({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rajyotsavaSongProvider);
    if (!state.available || !state.playing) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.onBanner.withValues(alpha: AppOpacity.secondaryText),
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.music_note, size: AppIconSizes.xs, color: style?.color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Huttidare Kannada Naadalli Huttabeku · Dr. Rajkumar',
              key: const ValueKey('song-now-playing'),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
