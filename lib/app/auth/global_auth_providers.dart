import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/flappy_bird/domain/auth_repository.dart';
import '../../features/flappy_bird/domain/player.dart';
import '../../features/flappy_bird/domain/player_repository.dart';
import '../../features/flappy_bird/flappy_bird_providers.dart';

export '../../features/flappy_bird/domain/auth_repository.dart';
export '../../features/flappy_bird/domain/player.dart';
export '../../features/flappy_bird/domain/player_repository.dart';

/// Global application authentication repository.
final globalAuthRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(flappyAuthRepositoryProvider),
);

/// Global application player repository (profiles and avatars).
final globalPlayerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => ref.watch(playerRepositoryProvider),
);

/// Global player authentication and profile state stream.
final globalAuthStateProvider = StreamProvider<PlayerProfile?>(
  (ref) => ref.watch(globalAuthRepositoryProvider).watchPlayer(),
);
