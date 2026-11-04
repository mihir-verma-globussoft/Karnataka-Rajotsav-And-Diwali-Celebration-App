import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/auth_repository.dart';
import '../domain/player.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._client,
    this._webClientId,
    this._iosClientId,
    this._logger,
  );

  final SupabaseClient _client;
  final String _webClientId;
  final String _iosClientId;
  final AppLogger _logger;
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _googleInitialized = false;

  static const _identityScopes = <String>['openid', 'email', 'profile'];

  @override
  Stream<PlayerProfile?> watchPlayer() async* {
    yield await currentPlayer();
    await for (final event in _client.auth.onAuthStateChange) {
      if (event.session?.user == null) {
        yield null;
      } else {
        yield await _loadProfile(event.session!.user.id);
      }
    }
  }

  @override
  Future<PlayerProfile?> currentPlayer() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _loadProfile(user.id);
  }

  @override
  Future<PlayerProfile> signInWithGoogle() async {
    try {
      await _initializeGoogle();
      if (!_google.supportsAuthenticate()) {
        throw const AuthConfigurationException(
          'Google sign-in is unavailable on this platform.',
        );
      }
      final account = await _google.authenticate(scopeHint: _identityScopes);
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const UnexpectedFailure('Google did not return an ID token.');
      }
      final email = account.email;
      if (email.isEmpty) {
        throw const UnexpectedFailure(
          'Google did not provide an email address for this account.',
        );
      }
      final authorization =
          await account.authorizationClient.authorizationForScopes(
            _identityScopes,
          ) ??
          await account.authorizationClient.authorizeScopes(_identityScopes);
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
      final user = response.user;
      if (user == null) {
        throw const UnexpectedFailure('Sign-in did not create a session.');
      }
      try {
        return await _loadProfile(user.id);
      } on Object catch (error, stackTrace) {
        _logger.error(
          'Supabase session created but player profile could not be loaded',
          error,
          stackTrace,
        );
        throw const UnexpectedFailure(
          'Your account signed in, but its player profile is unavailable. '
          'Please retry. If this continues, contact support.',
        );
      }
    } on GoogleSignInException catch (error, stackTrace) {
      _logger.error(
        'Google sign-in failed (${error.code.name})',
        error,
        stackTrace,
      );
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const AuthConfigurationException(
          'Google sign-in is not configured for this app build. '
          'Install the latest APK and try again.',
        );
      }
      if (error.code == GoogleSignInExceptionCode.interrupted) {
        throw UnexpectedFailure(
          'Google sign-in was interrupted. Please try once more.',
          error,
        );
      }
      throw UnexpectedFailure(
        'Google sign-in failed. Please try again.',
        error,
      );
    } on AuthException catch (error, stackTrace) {
      _logger.error(
        'Supabase Google authentication failed: ${error.code ?? error.message}',
        error,
        stackTrace,
      );
      final detail = error.code ?? error.message;
      throw UnexpectedFailure(
        'Supabase rejected Google sign-in ($detail). '
        'Check the Supabase Google provider configuration and retry.',
        error,
      );
    } on PostgrestException catch (error, stackTrace) {
      _logger.error(
        'Player profile query failed (${error.code})',
        error,
        stackTrace,
      );
      throw UnexpectedFailure(
        'Your account signed in, but its player profile could not be loaded '
        '(${error.code ?? 'database error'}).',
        error,
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    await _initializeGoogle();
    await _google.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _client.storage.from('player-avatars').remove([
          '$userId/character-avatar',
        ]);
      } on Object catch (error, stackTrace) {
        _logger.error('Player avatar cleanup failed', error, stackTrace);
      }
    }
    await _client.rpc<void>('delete_own_account');
    try {
      await _initializeGoogle();
      await _google.disconnect();
    } on Object catch (error, stackTrace) {
      // The Supabase account is already deleted. Best-effort Google cleanup
      // must not leave the local Supabase session behind.
      _logger.error('Google credential revocation failed', error, stackTrace);
    }
    await _client.auth.signOut();
  }

  Future<void> _initializeGoogle() async {
    if (_googleInitialized) return;
    await _google.initialize(
      clientId:
          defaultTargetPlatform == TargetPlatform.iOS && _iosClientId.isNotEmpty
          ? _iosClientId
          : null,
      serverClientId: _webClientId,
    );
    _googleInitialized = true;
  }

  Future<PlayerProfile> _loadProfile(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select(
            'id, username, email, avatar_url, character_avatar_url, created_at',
          )
          .eq('id', userId)
          .single();
      return _profileFromRow(row);
    } on PostgrestException catch (error) {
      throw UnexpectedFailure(
        'Your player profile could not be loaded.',
        error,
      );
    }
  }
}

PlayerProfile _profileFromRow(Map<String, dynamic> row) => PlayerProfile(
  id: row['id'] as String,
  username: row['username'] as String,
  email: row['email'] as String?,
  avatarUrl: row['avatar_url'] as String?,
  characterAvatarUrl: row['character_avatar_url'] as String?,
  createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
);
