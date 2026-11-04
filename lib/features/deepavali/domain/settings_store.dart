/// Keeps the background-song on/off choice between launches. Implementations must not
/// throw: a failure just means "nothing stored".
abstract interface class DeepavaliSettingsStore {
  /// Null if the person never chose.
  Future<bool?> loadMusic();
  Future<void> saveMusic(bool on);
}
