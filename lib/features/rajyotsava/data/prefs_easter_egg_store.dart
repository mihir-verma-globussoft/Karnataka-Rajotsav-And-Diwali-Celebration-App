import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/easter_eggs.dart';

/// [EasterEggStore] in `shared_preferences` (UserDefaults on iOS,
/// SharedPreferences on Android), so discoveries survive restarts. Stored as
/// one JSON map: collectible id -> {at, count}.
class PrefsEasterEggStore implements EasterEggStore {
  const PrefsEasterEggStore();

  static const String _key = 'rajyotsava.easter_eggs.v1';

  @override
  Future<Map<String, Discovery>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return {};
      final json = jsonDecode(raw);
      if (json is! Map) return {};
      return {
        for (final MapEntry(:key, :value) in json.entries)
          '$key': ?Discovery.fromJson(value),
      };
    } on Object {
      // Unreadable data: start a fresh collection rather than crash.
      return {};
    }
  }

  @override
  Future<void> save(Map<String, Discovery> discoveries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        for (final MapEntry(:key, :value) in discoveries.entries)
          key: value.toJson(),
      }),
    );
  }
}
