import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';

/// Whether the hero intro has been seen on this device. Not autoDispose: the
/// tab stays mounted for the life of the app.
class IntroSeenNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(deepavaliStoreProvider).introSeen();

  Future<void> markSeen() async {
    if (state.value ?? false) return;
    state = const AsyncData(true);
    await ref.read(deepavaliStoreProvider).markIntroSeen();
  }
}

final introSeenProvider = AsyncNotifierProvider<IntroSeenNotifier, bool>(
  IntroSeenNotifier.new,
);
