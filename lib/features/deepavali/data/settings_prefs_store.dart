import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_store.dart';

/// [DeepavaliSettingsStore] backed by `shared_preferences`.
class PrefsSettingsStore implements DeepavaliSettingsStore {
  const PrefsSettingsStore();

  // The key keeps its original name so an earlier choice is still honoured.
  static const String _music = 'deepavali.settings.sound';

  @override
  Future<bool?> loadMusic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_music);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveMusic(bool on) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_music, on);
    } on Object {
      // Not being able to remember only means the choice resets next time.
    }
  }
}
