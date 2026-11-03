import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/background_song.dart';

/// [BackgroundSong] playing an audio file bundled in the app, so it works
/// offline. The file must be a recording the team has the rights to use.
class AssetBackgroundSong implements BackgroundSong {
  AssetBackgroundSong(this.assetPath);

  /// Path relative to `assets/`, e.g. `audio/huttidare_kannada.mp3`.
  final String assetPath;

  AudioPlayer? _player;
  final _playback = StreamController<SongPlayback>.broadcast();
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
        PlayerState.playing => SongPlayback.playing,
        PlayerState.paused || PlayerState.stopped => SongPlayback.paused,
        PlayerState.completed => SongPlayback.ended,
        PlayerState.disposed => SongPlayback.other,
      }),
    );
    final iOS = defaultTargetPlatform == TargetPlatform.iOS;
    await player.setAudioContext(
      AudioContextConfig(
        // iPhone: the "ambient" category follows the silent switch and
        // already mixes with other apps' audio. Android: media volume (its
        // respectSilence would use ringtone volume), mixed with other audio
        // instead of stopping the person's own music.
        respectSilence: iOS,
        focus: iOS
            ? AudioContextConfigFocus.gain
            : AudioContextConfigFocus.mixWithOthers,
      ).build(),
    );
    // Play once per visit; keep the file loaded to resume after a pause.
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(assetPath));
    return player;
  }

  @override
  Future<void> play() async {
    try {
      await (await _ready()).resume();
    } on Object catch (error) {
      debugPrint('Rajyotsava song could not play: $error');
      _playback.add(SongPlayback.other);
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
  Stream<SongPlayback> get playback => _playback.stream;

  Future<void> dispose() async {
    await _states?.cancel();
    await _player?.dispose();
    await _playback.close();
  }
}
