/// Persists the best quiz score. Implementations must not throw; a failure
/// just means "no best score stored".
abstract interface class QuizStore {
  Future<int?> bestScore();
  Future<void> saveBestScore(int score);
}
