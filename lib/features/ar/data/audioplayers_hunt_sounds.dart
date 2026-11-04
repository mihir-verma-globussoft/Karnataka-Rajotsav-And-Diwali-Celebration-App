import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../domain/hunt_repository.dart';

/// [HuntSounds] backed by `audioplayers`, playing files bundled in the app.
class AudioplayersHuntSounds implements HuntSounds {
  AudioplayersHuntSounds();

  AudioPlayer? _player;

  @override
  Future<void> found() => _play('ar/audio/diya_light.mp3');

  @override
  Future<void> allFound() => _play('ar/audio/win.mp3');

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
