/// Reads Kannada text aloud with the device's text-to-speech voice.
abstract interface class KannadaSpeaker {
  /// Whether a Kannada voice is installed. Call before [speak].
  Future<bool> isAvailable();

  /// Speaks [text], interrupting anything already being spoken.
  Future<void> speak(String text);

  Future<void> stop();
}
