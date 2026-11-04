import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../providers.dart';

/// Why this name cannot be used, or null if it is fine. The shared `profiles`
/// table only accepts 3 to 24 characters.
String? huntNameProblem(String name) {
  final length = name.trim().length;
  if (length < 3) return 'Please enter at least 3 letters.';
  if (length > 24) return 'Please keep it to 24 letters or fewer.';
  return null;
}

/// Players join with just a name. Supabase anonymous sign-in gives each phone
/// its own private identity, so scores still cannot be written for someone
/// else. Only this standalone app needs this: the main app has its own login.
class HuntAuth {
  HuntAuth(this._config);

  final AppConfig _config;

  bool get _configured =>
      _config.hasSupabase && Supabase.instance.isInitialized;

  /// Null means this phone has not joined yet.
  Stream<Session?> watchSession() async* {
    if (!_configured) {
      yield null;
      return;
    }
    final auth = Supabase.instance.client.auth;
    yield auth.currentSession;
    await for (final event in auth.onAuthStateChange) {
      yield event.session;
    }
  }

  Future<void> join(String name) async {
    if (!_configured) {
      throw const UnexpectedFailure(
        'This build is not connected to the hunt server.',
      );
    }
    try {
      // The `handle_new_user` database trigger makes the profile from `name`.
      await Supabase.instance.client.auth.signInAnonymously(
        data: {'name': name.trim()},
      );
    } on AuthException catch (error) {
      throw UnexpectedFailure(
        error.code == 'anonymous_provider_disabled'
            ? 'Joining is switched off on the server. '
                  'Please tell the organiser.'
            : 'Could not join. Check your connection and try again.',
        error,
      );
    }
  }
}

final huntAuthProvider = Provider<HuntAuth>(
  (ref) => HuntAuth(ref.watch(appConfigProvider)),
);

final huntSessionProvider = StreamProvider<Session?>(
  (ref) => ref.watch(huntAuthProvider).watchSession(),
);
