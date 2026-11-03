import 'package:shared_preferences/shared_preferences.dart';

import '../domain/quiz_store.dart';

/// [QuizStore] backed by `shared_preferences`.
class PrefsQuizStore implements QuizStore {
  const PrefsQuizStore();

  static const String _bestKey = 'deepavali.quiz.best_score';

  @override
  Future<int?> bestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_bestKey);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveBestScore(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey, score);
    } on Object {
      // Losing a best score is harmless.
    }
  }
}
