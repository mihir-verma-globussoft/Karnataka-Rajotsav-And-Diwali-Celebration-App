import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';
import '../../domain/sound.dart';
import '../state/settings_notifier.dart';
import 'diwali_motion.dart';

/// Plays the background song only while the Deepavali tab is on screen, the
/// app is in front, the song is not muted and a song file is bundled. Pausing keeps the
/// place, so it carries on where it left off.
///
/// It touches no audio code at all when the song is muted or not bundled.
class DeepavaliMusic extends ConsumerStatefulWidget {
  const DeepavaliMusic({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DeepavaliMusic> createState() => _DeepavaliMusicState();
}

class _DeepavaliMusicState extends ConsumerState<DeepavaliMusic> {
  bool _playing = false;

  /// Kept from the first time music starts, so it can be paused when this
  /// widget goes away (a `ref` must not be used while unmounting).
  DeepavaliAudio? _audio;

  @override
  void dispose() {
    if (_playing) unawaited(_audio?.pauseMusic());
    super.dispose();
  }

  void _sync({required bool shouldPlay}) {
    if (shouldPlay == _playing) return;
    _playing = shouldPlay;
    final audio = ref.read(deepavaliAudioProvider);
    _audio = audio;
    unawaited(shouldPlay ? audio.playMusic() : audio.pauseMusic());
  }

  @override
  Widget build(BuildContext context) {
    final active = DiwaliMotion.of(context).active;
    final music = ref.watch(diwaliSettingsProvider.select((s) => s.music));
    // Reading the catalogue only loads the asset list, never a player.
    final hasMusic = ref.watch(audioCatalogProvider).value?.hasMusic ?? false;
    final shouldPlay = active && music && hasMusic;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync(shouldPlay: shouldPlay);
    });
    return widget.child;
  }
}
