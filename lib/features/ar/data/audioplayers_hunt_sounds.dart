import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../domain/hunt_repository.dart';

/// [HuntSounds] backed by `audioplayers`, playing files bundled in the app.
class AudioplayersHuntSounds implements HuntSounds {
  AudioplayersHuntSounds({@visibleForTesting this._newMusicPlayer});

  /// The Deepavali song, so the app carries only one copy of it.
  static const musicAsset = 'deepavali/audio/music.mp3';

  final Future<AudioPlayer> Function()? _newMusicPlayer;
  AudioPlayer? _player;

  // Separate, so the win sound can ring out over the start of the song. A
  // Future, so starting twice while it loads still makes only one player.
  late final Future<AudioPlayer> _music = (_newMusicPlayer ?? _newPlayer)();
  bool _musicWanted = false;

  @override
  Future<void> found() => _play('ar/audio/diya_light.mp3');

  @override
  Future<void> allFound() => _play('ar/audio/win.mp3');

  @override
  Future<void> startMusic() async {
    _musicWanted = true;
    try {
      final player = await _music;
      await player.setReleaseMode(ReleaseMode.loop);
      if (_musicWanted) await player.play(AssetSource(musicAsset));
      // The page closed while the song was loading.
      if (!_musicWanted) await player.stop();
    } on Object {
      // The party still shows without its song.
    }
  }

  @override
  Future<void> stopMusic() async {
    _musicWanted = false;
    try {
      await (await _music).stop();
    } on Object {
      // Nothing is playing, then.
    }
  }

  Future<void> _play(String asset) async {
    try {
      final player = _player ??= await _newPlayer();
      await player.stop();
      await player.play(AssetSource(asset));
    } on Object {
      // A sound is never essential: the find still shows on screen.
    }
  }

  /// iPhone: follows the silent switch. Android: mixes with the player's own
  /// music instead of stopping it.
  Future<AudioPlayer> _newPlayer() async {
    final iOS = defaultTargetPlatform == TargetPlatform.iOS;
    final player = AudioPlayer();
    await player.setAudioContext(
      AudioContextConfig(
        respectSilence: iOS,
        focus: iOS
            ? AudioContextConfigFocus.gain
            : AudioContextConfigFocus.mixWithOthers,
      ).build(),
    );
    return player;
  }
}
