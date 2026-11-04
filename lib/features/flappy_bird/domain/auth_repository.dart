import 'player.dart';

abstract interface class AuthRepository {
  Stream<PlayerProfile?> watchPlayer();

  Future<PlayerProfile?> currentPlayer();

  Future<PlayerProfile> signInWithGoogle();

  Future<void> signOut();

  Future<void> deleteAccount();
}

class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

class AuthConfigurationException implements Exception {
  const AuthConfigurationException(this.message);

  final String message;
}
