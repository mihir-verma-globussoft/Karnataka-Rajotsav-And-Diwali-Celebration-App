import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';

/// The game's own database, separate from the main app's. Its publishable key
/// is meant to ship in apps: the database rules are what protect it.
const huntDatabaseUrl = String.fromEnvironment(
  'HUNT_SUPABASE_URL',
  defaultValue: 'https://jxpedobynwyxdwjlqjwk.supabase.co',
);
const huntDatabaseKey = String.fromEnvironment(
  'HUNT_SUPABASE_KEY',
  defaultValue: 'sb_publishable_7VC8VUkW_bAhGoiSFzMu6w_3Bwgztjc',
);

/// Who is signed in to the main app.
abstract interface class HuntPlayerSource {
  String? get currentId;

  Future<String> name();
}

/// Gives each main app account its own player in the game's database, without
/// asking them for anything. The player is kept on the phone, so points survive
/// restarts and a shared phone keeps each person's score apart.
class HuntConnection {
  HuntConnection(this._client, this._player);

  static String _key(String mainUser) => 'ar_hunt.session.$mainUser';

  final SupabaseClient _client;
  final HuntPlayerSource _player;
  String? _connectedAs;
  Future<void>? _connecting;
  StreamSubscription<AuthState>? _changes;

  Future<void> ready() async {
    final mainUser = _player.currentId;
    if (mainUser == null) {
      throw const UnexpectedFailure('Please sign in to play.');
    }
    if (_connectedAs == mainUser && _client.auth.currentSession != null) return;
    await (_connecting ??= _connect(mainUser).whenComplete(() {
      _connecting = null;
    }));
  }

  Future<void> dispose() async => _changes?.cancel();

  Future<void> _connect(String mainUser) async {
    _connectedAs = null;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key(mainUser));
    var connected = false;
    if (saved != null) {
      try {
        await _client.auth.recoverSession(saved);
        connected = true;
      } on AuthRetryableFetchException {
        // Only the network failed. A new player here would lose their points.
        rethrow;
      } on AuthException {
        // The server no longer knows this session, so it cannot be recovered.
      }
    }
    if (!connected) {
      await _client.auth.signInAnonymously(
        data: {'name': await _player.name()},
      );
    }
    _connectedAs = mainUser;
    await _keep(prefs, _client.auth.currentSession);
    // Tokens refresh by themselves while the app runs; keep the newest one.
    _changes ??= _client.auth.onAuthStateChange.listen(
      (change) => unawaited(_keep(prefs, change.session)),
    );
  }

  Future<void> _keep(SharedPreferences prefs, Session? session) async {
    final mainUser = _connectedAs;
    if (session == null || mainUser == null) return;
    await prefs.setString(_key(mainUser), jsonEncode(session.toJson()));
  }
}
