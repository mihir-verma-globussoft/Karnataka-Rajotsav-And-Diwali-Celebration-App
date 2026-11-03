/// The sound played when the player is caught. Presentation depends on this,
/// never on an audio plugin.
abstract interface class GameOverAudio {
  /// Plays the clip (twice in a row). Never throws: a failure to play must
  /// not affect the game.
  Future<void> play();

  /// Cuts the sound short, e.g. when the player restarts.
  Future<void> stop();

  Future<void> dispose();
}
