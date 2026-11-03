/// The Rajyotsava tab's song, played from an audio file bundled in the app.
abstract interface class BackgroundSong {
  /// Whether the audio file is bundled. False until a licensed recording is
  /// added at `assets/audio/` (see assets/audio/README.md).
  Future<bool> isAvailable();

  Future<void> play();

  Future<void> pause();

  /// Playback changes reported by the player.
  Stream<SongPlayback> get playback;
}

enum SongPlayback { playing, paused, ended, other }

/// What the tab's song should be doing.
class SongState {
  const SongState({
    this.available = false,
    this.muted = false,
    this.tabVisible = false,
    this.heldForVoice = false,
    this.playing = false,
  });

  /// False when no audio file is bundled.
  final bool available;

  /// The person turned the song off with the mute button. Remembered while
  /// the app is open.
  final bool muted;

  /// The Rajyotsava tab is on screen (not another tab, not a sub-screen,
  /// app in the foreground).
  final bool tabVisible;

  /// Paused while a Kannada wish is read aloud.
  final bool heldForVoice;

  /// The player reports it is playing.
  final bool playing;

  /// Whether the song should be playing right now.
  bool get shouldPlay => available && tabVisible && !muted && !heldForVoice;

  SongState copyWith({
    bool? available,
    bool? muted,
    bool? tabVisible,
    bool? heldForVoice,
    bool? playing,
  }) => SongState(
    available: available ?? this.available,
    muted: muted ?? this.muted,
    tabVisible: tabVisible ?? this.tabVisible,
    heldForVoice: heldForVoice ?? this.heldForVoice,
    playing: playing ?? this.playing,
  );
}
