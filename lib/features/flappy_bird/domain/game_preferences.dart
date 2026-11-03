class GamePreferences {
  const GamePreferences({this.soundEffectsEnabled = true});

  final bool soundEffectsEnabled;

  GamePreferences copyWith({bool? soundEffectsEnabled}) => GamePreferences(
    soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
  );
}

abstract interface class GamePreferencesRepository {
  Future<GamePreferences> load();

  Future<void> save(GamePreferences preferences);
}
