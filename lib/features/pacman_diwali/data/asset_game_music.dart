import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../domain/game_music.dart';

/// [GameMusic] that loops a bundled song. Failing to play (no sound hardware,
/// missing file) never affects the game.
class AssetGameMusic implements GameMusic {
  AssetGameMusic({this.assetPath = 'audio/pyar_ka_signal.mp3'});

  /// Path relative to `assets/`.
  final String assetPath;

  AudioPlayer? _player;

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
    await player.setReleaseMode(ReleaseMode.loop);
    return player;
  }

  @override
  Future<void> start() async {
    try {
      final player = await _ready();
      await player.stop();
      await player.play(AssetSource(assetPath));
    } on Object catch (error) {
      debugPrint('Game music could not play: $error');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player?.stop();
    } on Object {
      // Nothing playing.
    }
  }

  @override
  Future<void> dispose() async {
    final player = _player;
    _player = null;
    try {
      await player?.dispose();
    } on Object {
      // Already gone.
    }
  }
}
