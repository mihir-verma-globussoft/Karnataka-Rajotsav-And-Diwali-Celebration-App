/// The Games tab's background theme music.
abstract interface class GamesAudio {
  /// Whether the audio file is bundled and available in the asset bundle.
  Future<bool> isAvailable();

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Playback changes reported by the underlying player.
  Stream<GamesAudioPlayback> get playback;
}

enum GamesAudioPlayback { playing, paused, ended, other }

/// Playback and visibility state for the Games tab's background audio.
class GamesAudioState {
  const GamesAudioState({
    this.available = false,
    this.muted = false,
    this.tabVisible = false,
    this.routeActive = true,
    this.playing = false,
  });

  /// False when no audio file is bundled.
  final bool available;

  /// The user turned the audio off with the mute button.
  final bool muted;

  /// The Games tab is on screen (selected tab and app in foreground).
  final bool tabVisible;

  /// True when the user is on the Games overview list; false when a game
  /// sub-route (e.g. Flappy Bird) is pushed on top.
  final bool routeActive;

  /// The player reports it is currently playing.
  final bool playing;

  /// Whether the theme song should be playing right now.
  bool get shouldPlay => available && tabVisible && routeActive && !muted;

  GamesAudioState copyWith({
    bool? available,
    bool? muted,
    bool? tabVisible,
    bool? routeActive,
    bool? playing,
  }) => GamesAudioState(
    available: available ?? this.available,
    muted: muted ?? this.muted,
    tabVisible: tabVisible ?? this.tabVisible,
    routeActive: routeActive ?? this.routeActive,
    playing: playing ?? this.playing,
  );
}
