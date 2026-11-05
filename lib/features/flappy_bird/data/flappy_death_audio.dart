import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// One-shot audio played when the player's bird loses a life.
class FlappyDeathAudio {
  AudioPlayer? _player;

  Future<void> play() async {
    try {
      final player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.stop();
      await player.play(AssetSource('audio/flappy_bird_death.mp3'));
      await player.onPlayerComplete.first;
    } on Object catch (error) {
      debugPrint('Flappy Bird death audio could not play: $error');
    }
  }

  Future<void> dispose() async => _player?.dispose();
}
