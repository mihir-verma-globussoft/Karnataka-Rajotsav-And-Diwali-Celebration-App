class GamePreferences {
  const GamePreferences({
    this.soundEffectsEnabled = true,
    this.backgroundMusicEnabled = true,
  });

  final bool soundEffectsEnabled;
  final bool backgroundMusicEnabled;

  GamePreferences copyWith({
    bool? soundEffectsEnabled,
    bool? backgroundMusicEnabled,
  }) => GamePreferences(
    soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
    backgroundMusicEnabled:
        backgroundMusicEnabled ?? this.backgroundMusicEnabled,
  );
}

abstract interface class GamePreferencesRepository {
  Future<GamePreferences> load();

  Future<void> save(GamePreferences preferences);
}
