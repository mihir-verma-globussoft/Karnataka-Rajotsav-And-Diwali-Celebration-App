import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Looped background music for the active Flappy Bird game session.
class FlappyBackgroundMusic {
  static const _volume = .32;

  AudioPlayer? _player;
  bool _isPlaying = false;

  /// Starts one loop for an active gameplay attempt. Repeated state updates
  /// are intentionally ignored, so score/ticker rebuilds cannot layer audio.
  Future<void> play() async {
    if (_isPlaying) return;
    try {
      final player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_volume);
      await player.stop();
      await player.play(AssetSource('audio/flappy_bird_music.mp3'));
      _isPlaying = true;
    } on Object catch (error) {
      _isPlaying = false;
      debugPrint('Flappy Bird background music could not play: $error');
    }
  }

  Future<void> pause() async {
    try {
      await _player?.pause();
      _isPlaying = false;
    } on Object {
      // Nothing is playing.
    }
  }

  /// Stops the current attempt, ready for a fresh loop when the player taps
  /// to begin another one.
  Future<void> stop() async {
    try {
      await _player?.stop();
    } on Object {
      // Nothing is playing.
    } finally {
      _isPlaying = false;
    }
  }

  Future<void> dispose() async => _player?.dispose();
}
