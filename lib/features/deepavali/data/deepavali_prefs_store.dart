import 'package:shared_preferences/shared_preferences.dart';

import '../domain/deepavali_store.dart';

/// [DeepavaliStore] backed by `shared_preferences` (key-value, on device).
class PrefsDeepavaliStore implements DeepavaliStore {
  const PrefsDeepavaliStore();

  static const String _introSeenKey = 'deepavali.intro_seen';

  @override
  Future<bool> introSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_introSeenKey) ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> markIntroSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introSeenKey, true);
    } on Object {
      // Not being able to remember only means the intro may play again.
    }
  }
}
