import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import 'data/audioplayers_deepavali_audio.dart';
import 'data/deepavali_prefs_store.dart';
import 'data/diya_game_prefs_store.dart';
import 'data/image_picker_photo_picker.dart';
import 'data/quiz_prefs_store.dart';
import 'data/settings_prefs_store.dart';
import 'data/share_plus_image_sharer.dart';
import 'data/supabase_deepavali_scoreboard.dart';
import 'data/wish_prefs_store.dart';
import 'domain/deepavali_scores.dart';
import 'domain/deepavali_store.dart';
import 'domain/diya_game_store.dart';
import 'domain/image_sharer.dart';
import 'domain/photo_booth.dart';
import 'domain/quiz_store.dart';
import 'domain/settings_store.dart';
import 'domain/sound.dart';
import 'domain/wish_store.dart';

/// Persistence for the tab. Override in tests with a fake.
final deepavaliStoreProvider = Provider<DeepavaliStore>(
  (ref) => const PrefsDeepavaliStore(),
);

/// Current time source. Override in tests for deterministic countdowns.
final deepavaliNowProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Best-time persistence for the diya game. Override in tests.
final diyaGameStoreProvider = Provider<DiyaGameStore>(
  (ref) => const PrefsDiyaGameStore(),
);

/// Monotonic play clock for the diya game: time since an arbitrary start.
/// Override in tests with a controllable clock.
final diyaGameClockProvider = Provider<Duration Function()>((ref) {
  final watch = Stopwatch()..start();
  return () => watch.elapsed;
});

/// Best-score persistence for the quiz. Override in tests.
final quizStoreProvider = Provider<QuizStore>((ref) => const PrefsQuizStore());

/// Seed for each new quiz run. Override in tests for a fixed run.
final quizSeedProvider = Provider<int Function()>(
  (ref) =>
      () => DateTime.now().microsecondsSinceEpoch,
);

/// Seed for each new diya game, so gusts differ run to run. Override in tests
/// for a fixed game.
final diyaGameSeedProvider = Provider<int Function()>(
  (ref) =>
      () => DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
);

/// Seed for the rangoli Random button. Override in tests for a fixed design.
final rangoliSeedProvider = Provider<int Function()>(
  (ref) =>
      () => DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
);

/// Shares pictures made in the tab (rangoli and greeting cards). Null hides
/// the Share buttons; tests override it with a fake.
final imageSharerProvider = Provider<ImageSharer?>(
  (ref) => const SharePlusImageSharer(),
);

/// Persistence for the diya wall. Override in tests.
final wishStoreProvider = Provider<WishStore>((ref) => const PrefsWishStore());

/// Takes or chooses photos for the photo booth. Override in tests.
final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => const ImagePickerPhotoPicker(),
);

/// Remembers whether the song is muted. Override in tests.
final deepavaliSettingsStoreProvider = Provider<DeepavaliSettingsStore>(
  (ref) => const PrefsSettingsStore(),
);

/// Plays the tab's sounds. Created on first use and released with the app.
/// Override in tests with a fake.
final deepavaliAudioProvider = Provider<DeepavaliAudio>((ref) {
  final audio = AudioplayersDeepavaliAudio();
  ref.onDispose(() => unawaited(audio.dispose()));
  return audio;
});

/// Which audio files are bundled; sound controls hide if there are none.
final audioCatalogProvider = FutureProvider<AudioCatalog>(
  (ref) => ref.watch(deepavaliAudioProvider).catalog(),
);

/// The online leaderboards for the Deepavali games on the app's shared games
/// backend, when this build has one; without it the games work offline as
/// before. Override in tests.
final deepavaliScoreboardProvider = Provider<DeepavaliScoreboard>((ref) {
  final client = ref.watch(appConfigProvider).hasSupabase
      ? _initializedSupabaseClient()
      : null;
  if (client == null) return const NoDeepavaliScoreboard();
  return SupabaseDeepavaliScoreboard(
    client,
    now: ref.watch(deepavaliNowProvider),
  );
});

/// The Supabase client, or null when Supabase was not initialized (startup
/// failed, or a test). `Supabase.instance` throws an [AssertionError] in
/// debug builds when it is not initialized; a game must never crash for
/// that, it just has no online scores.
SupabaseClient? _initializedSupabaseClient() {
  try {
    final supabase = Supabase.instance;
    return supabase.isInitialized ? supabase.client : null;
  } on AssertionError {
    return null;
  }
}
