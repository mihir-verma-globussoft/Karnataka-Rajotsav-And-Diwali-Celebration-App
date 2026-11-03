import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/wish.dart';
import '../domain/wish_store.dart';

/// [WishStore] backed by `shared_preferences`, as one JSON list.
class PrefsWishStore implements WishStore {
  const PrefsWishStore();

  static const String _key = 'deepavali.wall.v1';

  @override
  Future<List<Wish>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      // Damaged entries are skipped, never fatal.
      return [for (final item in decoded) ?Wish.tryParse(item)]
          .take(wallMax)
          .toList();
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> save(List<Wish> wishes) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      _key,
      jsonEncode([for (final w in wishes) w.toJson()]),
    );
    if (!ok) throw StateError('Could not write the wall.');
  }
}
