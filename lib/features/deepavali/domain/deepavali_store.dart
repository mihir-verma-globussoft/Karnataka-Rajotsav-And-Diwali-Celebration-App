/// Small persisted state for the Deepavali tab. Implementations must never
/// throw to callers they cannot recover from; presentation treats failures as
/// "not stored".
abstract interface class DeepavaliStore {
  Future<bool> introSeen();
  Future<void> markIntroSeen();
}
