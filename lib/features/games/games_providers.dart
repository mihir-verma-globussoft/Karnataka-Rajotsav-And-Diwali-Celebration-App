import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/asset_games_audio.dart';
import 'domain/games_audio.dart';

/// Asset path for the games theme song.
const String gamesThemeAudioAsset = 'audio/games_theme.mp3';

/// The Games tab's audio service. Override in tests with a fake.
final gamesAudioProvider = Provider<GamesAudio>((ref) {
  final audio = AssetGamesAudio(gamesThemeAudioAsset);
  ref.onDispose(audio.dispose);
  return audio;
});

/// Controls playback of the Games tab's background theme music.
final gamesAudioStateProvider =
    NotifierProvider<GamesAudioController, GamesAudioState>(
      GamesAudioController.new,
    );

class GamesAudioController extends Notifier<GamesAudioState> {
  StreamSubscription<GamesAudioPlayback>? _subscription;
  var _starting = false;

  @override
  GamesAudioState build() {
    final audio = ref.watch(gamesAudioProvider);
    _subscription = audio.playback.listen(_onPlayback);
    ref.onDispose(() => _subscription?.cancel());
    unawaited(_checkAvailable(audio));
    return const GamesAudioState();
  }

  Future<void> _checkAvailable(GamesAudio audio) async {
    final available = await audio.isAvailable();
    if (!ref.mounted || !available) return;
    state = state.copyWith(available: true);
    _apply();
  }

  /// Called when the Games tab becomes visible or hidden.
  void setTabVisible(bool visible) {
    if (!ref.mounted || state.tabVisible == visible) return;
    state = state.copyWith(tabVisible: visible);
    _apply();
  }

  /// Called when navigating into a game (false) or returning to games list (true).
  void setRouteActive(bool active) {
    if (!ref.mounted || state.routeActive == active) return;
    state = state.copyWith(routeActive: active);
    _apply();
  }

  /// Mute button toggle.
  void toggleMute() {
    state = state.copyWith(muted: !state.muted);
    _apply();
  }

  void _apply() {
    final audio = ref.read(gamesAudioProvider);
    if (state.shouldPlay && !state.playing && !_starting) {
      _starting = true;
      unawaited(audio.play());
    } else if (!state.shouldPlay && (state.playing || _starting)) {
      unawaited(audio.pause());
    }
  }

  void _onPlayback(GamesAudioPlayback playback) {
    switch (playback) {
      case GamesAudioPlayback.playing:
        _starting = false;
        state = state.copyWith(playing: true);
        _apply();
      case GamesAudioPlayback.paused:
        _starting = false;
        state = state.copyWith(playing: false);
      case GamesAudioPlayback.ended:
        state = state.copyWith(playing: false);
      case GamesAudioPlayback.other:
        _starting = false;
    }
  }
}
