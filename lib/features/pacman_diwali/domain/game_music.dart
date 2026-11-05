/// The song that plays while a Pac-Man game is being played. Presentation
/// depends on this, never on an audio plugin.
abstract interface class GameMusic {
  /// Starts the song from the beginning and repeats it. Never throws: a
  /// failure to play must not affect the game.
  Future<void> start();

  /// Stops the song, e.g. when the player is caught.
  Future<void> stop();

  Future<void> dispose();
}
