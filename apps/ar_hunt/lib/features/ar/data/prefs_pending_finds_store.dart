import 'package:shared_preferences/shared_preferences.dart';

import '../domain/hunt_repository.dart';

/// [PendingFindsStore] backed by `shared_preferences`, kept per player so a
/// shared phone never credits a find to the wrong person.
class PrefsPendingFindsStore implements PendingFindsStore {
  const PrefsPendingFindsStore(this._userId);

  final String _userId;

  String get _key => 'ar_hunt.pending_finds.$_userId';

  @override
  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  @override
  Future<void> add(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = {...?prefs.getStringList(_key), itemId};
    await prefs.setStringList(_key, ids.toList());
  }

  @override
  Future<void> remove(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? const <String>[];
    await prefs.setStringList(_key, [
      for (final id in ids)
        if (id != itemId) id,
    ]);
  }
}
