import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/games_audio.dart';

/// [GamesAudio] playing an audio file bundled in the app, so it works offline.
class AssetGamesAudio implements GamesAudio {
  AssetGamesAudio(this.assetPath);

  /// Path relative to `assets/`, e.g. `audio/games_theme.mp3`.
  final String assetPath;

  AudioPlayer? _player;
  final _playback = StreamController<GamesAudioPlayback>.broadcast();
  StreamSubscription<PlayerState>? _states;

  @override
  Future<bool> isAvailable() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().contains('assets/$assetPath');
    } on Object {
      return false;
    }
  }

  /// Created on first play, only once the file is known to exist.
  Future<AudioPlayer> _ready() async {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _player = player;
    _states = player.onPlayerStateChanged.listen(
      (state) => _playback.add(switch (state) {
        PlayerState.playing => GamesAudioPlayback.playing,
        PlayerState.paused || PlayerState.stopped => GamesAudioPlayback.paused,
        PlayerState.completed => GamesAudioPlayback.ended,
        PlayerState.disposed => GamesAudioPlayback.other,
      }),
    );
    final iOS = defaultTargetPlatform == TargetPlatform.iOS;
    await player.setAudioContext(
      AudioContextConfig(
        respectSilence: iOS,
        focus: iOS
            ? AudioContextConfigFocus.gain
            : AudioContextConfigFocus.mixWithOthers,
      ).build(),
    );
    // Background theme loops while on the Games tab; keeps file loaded to resume.
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setSource(AssetSource(assetPath));
    return player;
  }

  @override
  Future<void> play() async {
    try {
      await (await _ready()).resume();
    } on Object catch (error) {
      debugPrint('Games audio could not play: $error');
      _playback.add(GamesAudioPlayback.other);
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player?.pause();
    } on Object {
      // Nothing playing.
    }
  }

  @override
  Stream<GamesAudioPlayback> get playback => _playback.stream;

  Future<void> dispose() async {
    await _states?.cancel();
    await _player?.dispose();
    await _playback.close();
  }
}
