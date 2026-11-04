import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Looped background music for the active Flappy Bird game session.
class FlappyBackgroundMusic {
  static const _volume = .32;

  AudioPlayer? _player;

  Future<void> play() async {
    try {
      final player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_volume);
      await player.setSource(AssetSource('audio/flappy_bird_music.mp3'));
      await player.resume();
    } on Object catch (error) {
      debugPrint('Flappy Bird background music could not play: $error');
    }
  }

  Future<void> pause() async {
    try {
      await _player?.pause();
    } on Object {
      // Nothing is playing.
    }
  }

  Future<void> dispose() async => _player?.dispose();
}
