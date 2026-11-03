import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/sound.dart';

/// [DeepavaliAudio] backed by `audioplayers`, playing files bundled in the app
/// (so it works offline). No player is created until its sound is first
/// needed, and none at all if a file is missing.
class AudioplayersDeepavaliAudio implements DeepavaliAudio {
  AudioplayersDeepavaliAudio();

  /// Effects are kept quiet; they sit over the music.
  static const double _effectVolume = 0.8;

  /// The song is a gentle background.
  static const double _musicVolume = 0.45;

  static const AppLogger _log = AppLogger();

  AudioCatalog? _catalog;
  AudioPlayer? _music;
  final Map<Sfx, AudioPlayer> _effects = {};

  @override
  Future<AudioCatalog> catalog() async {
    final known = _catalog;
    if (known != null) return known;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return _catalog = AudioCatalog.fromAssets(manifest.listAssets());
    } on Object {
      return _catalog = const AudioCatalog();
    }
  }

  /// iPhone: the "ambient" category follows the silent switch and mixes with
  /// other apps. Android: media volume, mixed with other audio instead of
  /// stopping the person's own music.
  AudioContext get _context {
    final iOS = defaultTargetPlatform == TargetPlatform.iOS;
    return AudioContextConfig(
      respectSilence: iOS,
      focus: iOS
          ? AudioContextConfigFocus.gain
          : AudioContextConfigFocus.mixWithOthers,
    ).build();
  }

  /// `assets/x/y.mp3` to the `x/y.mp3` that [AssetSource] expects.
  static String _relative(String key) => key.replaceFirst('assets/', '');

  @override
  Future<void> playEffect(Sfx sfx) async {
    try {
      final path = (await catalog()).effects[sfx];
      if (path == null) return;
      var player = _effects[sfx];
      if (player == null) {
        player = AudioPlayer();
        _effects[sfx] = player;
        await player.setAudioContext(_context);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
      }
      await player.stop();
      await player.play(AssetSource(_relative(path)), volume: _effectVolume);
    } on Object catch (error) {
      _log.warning('Deepavali sound ${sfx.name} could not play', error);
    }
  }

  Future<AudioPlayer?> _musicPlayer() async {
    final existing = _music;
    if (existing != null) return existing;
    final path = (await catalog()).music;
    if (path == null) return null;
    final player = AudioPlayer();
    _music = player;
    await player.setAudioContext(_context);
    // Loops while the tab is open and the person has sound on.
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(_musicVolume);
    await player.setSource(AssetSource(_relative(path)));
    return player;
  }

  /// What the song should be doing. Play and pause requests can arrive faster
  /// than the player can act on them (mute, unmute, mute...), so each request
  /// only records the wish and the commands run one after another; the latest
  /// wish always wins.
  bool _wantMusic = false;
  Future<void> _musicQueue = Future<void>.value();

  Future<void> _requestMusic({required bool play}) {
    _wantMusic = play;
    return _musicQueue = _musicQueue.then((_) => _applyMusic());
  }

  /// How long to wait before checking that a resume really started playing.
  static const Duration _verifyAfter = Duration(milliseconds: 500);

  Future<void> _applyMusic() async {
    try {
      if (!_wantMusic) {
        await _music?.pause();
        return;
      }
      final player = await _musicPlayer();
      if (player == null) return;
      if (player.state != PlayerState.playing) await player.resume();
      // A resume that did not take (the player was still settling) is tried
      // once more, unless the wish has changed meanwhile.
      await Future<void>.delayed(_verifyAfter);
      if (_wantMusic && player.state != PlayerState.playing) {
        await player.resume();
      }
    } on Object catch (error) {
      _log.warning('Deepavali music could not play', error);
    }
  }

  @override
  Future<void> playMusic() => _requestMusic(play: true);

  @override
  Future<void> pauseMusic() => _requestMusic(play: false);

  @override
  Future<void> dispose() async {
    try {
      await _music?.dispose();
      for (final p in _effects.values) {
        await p.dispose();
      }
    } on Object {
      // Already released.
    }
  }
}
