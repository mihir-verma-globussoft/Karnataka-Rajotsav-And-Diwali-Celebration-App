import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/pacman_diwali_tokens.dart';
import '../domain/game_over_audio.dart';

/// [GameOverAudio] with the "faaahh" played when the player is caught: the bundled clip twice in a
/// row, at full volume. Failing to play (no sound hardware, missing file)
/// never affects the game.
class AssetGameOverAudio implements GameOverAudio {
  AssetGameOverAudio({
    this.assetPath = 'audio/FAAAHH High Pitched Meme Sound Effect.mp3',
    this.times = 2,
  });

  /// Path relative to `assets/`.
  final String assetPath;

  /// How many times the clip repeats.
  final int times;

  AudioPlayer? _player;
  bool _stopped = false;

  Future<AudioPlayer> _ready() async {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _player = player;
    final iOS = defaultTargetPlatform == TargetPlatform.iOS;
    await player.setAudioContext(
      AudioContextConfig(
        // iPhone follows the silent switch; Android uses media volume.
        respectSilence: iOS,
        focus: AudioContextConfigFocus.gain,
      ).build(),
    );
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(1);
    return player;
  }

  @override
  Future<void> play() async {
    _stopped = false;
    try {
      final player = await _ready();
      for (var i = 0; i < times && !_stopped; i++) {
        // Listen before starting so a short clip cannot finish unnoticed.
        final finished = player.onPlayerComplete.first
            .then<void>((_) {})
            .timeout(PacmanDurations.soundTimeout, onTimeout: () {});
        await player.play(AssetSource(assetPath));
        await finished;
      }
    } on Object catch (error) {
      debugPrint('Game over sound could not play: $error');
    }
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    try {
      await _player?.stop();
    } on Object {
      // Nothing playing.
    }
  }

  @override
  Future<void> dispose() async {
    _stopped = true;
    final player = _player;
    _player = null;
    try {
      await player?.dispose();
    } on Object {
      // Already gone.
    }
  }
}
