import 'package:supabase_flutter/supabase_flutter.dart';

import 'hunt_connection.dart';

/// The player signed in to the main app, read from its own database.
class MainAppPlayer implements HuntPlayerSource {
  const MainAppPlayer(this._mainApp);

  final SupabaseClient _mainApp;

  @override
  String? get currentId => _mainApp.auth.currentUser?.id;

  /// shortcut: read once, when their game player is created, so renaming in the
  /// main app does not reach the leaderboard; send it on each load if that matters.
  @override
  Future<String> name() async {
    final user = _mainApp.auth.currentUser;
    if (user == null) return 'Player';
    try {
      final row = await _mainApp
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .single();
      final username = row['username'] as String?;
      if (username != null && username.trim().isNotEmpty) return username;
    } on Exception {
      // The leaderboard name is not worth blocking the game over.
    }
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fallback = metadata['full_name'] ?? metadata['name'];
    return fallback is String && fallback.trim().isNotEmpty
        ? fallback
        : 'Player';
  }
}
