import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/asset_background_song.dart';
import 'data/bundled_rajyotsava_content.dart';
import 'data/easter_egg_collectibles.dart';
import 'data/geolocator_location_service.dart';
import 'data/prefs_easter_egg_store.dart';
import 'data/sensor_shake_source.dart';
import 'data/tts_kannada_speaker.dart';
import 'data/url_external_links.dart';
import 'domain/background_song.dart';
import 'domain/easter_eggs.dart';
import 'domain/external_links.dart';
import 'domain/kannada_speaker.dart';
import 'domain/location.dart';
import 'domain/models.dart';
import 'domain/nearby.dart';
import 'domain/quiz_deck.dart';
import 'domain/quiz_session.dart';
import 'domain/shake.dart';

/// All module content. Bundled in the app; override in tests.
final rajyotsavaContentProvider = Provider<RajyotsavaContent>(
  (ref) => bundledRajyotsavaContent,
);

/// Kannada text-to-speech. Kept alive by the Learn Kannada screen and
/// disposed (stopping any speech) when it closes. Override in tests.
final kannadaSpeakerProvider = Provider.autoDispose<KannadaSpeaker>((ref) {
  final speaker = TtsKannadaSpeaker();
  ref.onDispose(speaker.stop);
  return speaker;
});

/// Opens maps for directions and YouTube for songs. Override in tests.
final externalLinksProvider = Provider<ExternalLinks>(
  (ref) => const UrlExternalLinks(),
);

/// The Rajyotsava tab's song, "Huttidare Kannada Naadalli Huttabeku"
/// (Dr. Rajkumar, Aakasmika, 1993). The recording is copyrighted (Akash
/// Audio), so it is not in the repository: add a licensed copy at
/// `assets/audio/huttidare_kannada.mp3`. Until then the tab has no song.
const String rajyotsavaSongAsset = 'audio/huttidare_kannada.mp3';

/// The tab's song. Override in tests with a fake.
final backgroundSongProvider = Provider<BackgroundSong>((ref) {
  final song = AssetBackgroundSong(rajyotsavaSongAsset);
  ref.onDispose(song.dispose);
  return song;
});

/// Plays the song only while the Rajyotsava tab is on screen and the person
/// has not muted it. Other tabs have their own music.
final rajyotsavaSongProvider =
    NotifierProvider<RajyotsavaSongController, SongState>(
      RajyotsavaSongController.new,
    );

class RajyotsavaSongController extends Notifier<SongState> {
  StreamSubscription<SongPlayback>? _subscription;

  /// A play request is waiting for the player to start.
  var _starting = false;

  /// The song played to the end (or the system stopped it) during this
  /// visit; it plays again on the next visit, not on every state change.
  var _done = false;

  @override
  SongState build() {
    final song = ref.watch(backgroundSongProvider);
    _subscription = song.playback.listen(_onPlayback);
    ref.onDispose(() => _subscription?.cancel());
    unawaited(_checkAvailable(song));
    return const SongState();
  }

  Future<void> _checkAvailable(BackgroundSong song) async {
    final available = await song.isAvailable();
    if (!ref.mounted || !available) return;
    state = state.copyWith(available: true);
    _apply();
  }

  /// Called by the tab when it appears or disappears.
  void setTabVisible(bool visible) {
    // The tab may report after the app (and this controller) has closed.
    if (!ref.mounted || state.tabVisible == visible) return;
    if (visible) _done = false;
    state = state.copyWith(tabVisible: visible);
    _apply();
  }

  /// The mute button: turns the song off, or back on.
  void toggleMute() {
    state = state.copyWith(muted: !state.muted);
    _apply();
  }

  /// Pauses the song while a Kannada wish is read aloud.
  void holdForVoice(bool hold) {
    if (state.heldForVoice == hold) return;
    state = state.copyWith(heldForVoice: hold);
    _apply();
  }

  void _apply() {
    final song = ref.read(backgroundSongProvider);
    if (state.shouldPlay && !state.playing && !_starting && !_done) {
      _starting = true;
      unawaited(song.play());
    } else if (!state.shouldPlay && (state.playing || _starting)) {
      unawaited(song.pause());
    }
  }

  void _onPlayback(SongPlayback playback) {
    switch (playback) {
      case SongPlayback.playing:
        _starting = false;
        state = state.copyWith(playing: true);
        // Muted or left the tab while it was starting: pause it again.
        _apply();
      case SongPlayback.paused:
        _starting = false;
        // Paused by the system (a call, headphones out) while it should be
        // playing: wait for the next visit instead of fighting the system.
        if (state.shouldPlay) _done = true;
        state = state.copyWith(playing: false);
      case SongPlayback.ended:
        _done = true;
        state = state.copyWith(playing: false);
      case SongPlayback.other:
        _starting = false;
    }
  }
}

/// Device location. Override in tests with a fake.
final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

/// The "Use my location" flow on the Near me screen. Location is asked for
/// only when the person taps the button, and is kept only while the screen
/// is open.
final nearbyControllerProvider =
    NotifierProvider.autoDispose<NearbyController, NearbyState>(
      NearbyController.new,
    );

class NearbyController extends Notifier<NearbyState> {
  @override
  NearbyState build() => const NearbyState(NearbyStatus.idle);

  Future<void> locate() async {
    if (state.status == NearbyStatus.locating) return;
    state = const NearbyState(NearbyStatus.locating);
    final result = await ref.read(locationServiceProvider).currentLocation();
    if (!ref.mounted) return;
    state = switch (result) {
      LocationFound(:final point) => NearbyState(NearbyStatus.found, point),
      LocationDenied() => const NearbyState(NearbyStatus.denied),
      LocationDeniedForever() => const NearbyState(NearbyStatus.deniedForever),
      LocationServicesOff() => const NearbyState(NearbyStatus.servicesOff),
      LocationUnavailable() => const NearbyState(NearbyStatus.unavailable),
    };
  }

  Future<void> openAppSettings() =>
      ref.read(locationServiceProvider).openAppSettings();

  Future<void> openLocationSettings() =>
      ref.read(locationServiceProvider).openLocationSettings();
}

/// How long the tab's ambient motion (confetti, fireworks, toran, flag)
/// runs each time the tab appears. Null keeps it going for as long as the
/// tab is on screen (it still pauses on other tabs, on sub-screens, in the
/// background and with Reduce Motion). Tests set a finite time so
/// `pumpAndSettle` can finish (see test/helpers.dart).
final rajyotsavaAmbientDurationProvider = Provider<Duration?>((ref) => null);

/// Detected shakes of the device. Override in tests with a fake source.
final shakeSourceProvider = Provider<ShakeSource>(
  (ref) => const SensorShakeSource(),
);

/// The hidden Karnataka collectibles. Override in tests.
final collectiblesProvider = Provider<List<Collectible>>(
  (ref) => karnatakaCollectibles,
);

/// Where discoveries are saved. Override in tests with an in-memory store.
final easterEggStoreProvider = Provider<EasterEggStore>(
  (ref) => const PrefsEasterEggStore(),
);

/// Random source for picking collectibles. Override in tests.
final easterEggRandomProvider = Provider<Random>((ref) => Random());

/// The person's discovered collectibles (id -> discovery), loaded from the
/// store. Every way of finding an easter egg (shake, hidden taps) goes
/// through [EasterEggManager.discover], so the no-repeat rule always holds.
final easterEggManagerProvider =
    AsyncNotifierProvider<EasterEggManager, Map<String, Discovery>>(
      EasterEggManager.new,
    );

class EasterEggManager extends AsyncNotifier<Map<String, Discovery>> {
  /// The discovery in progress, so simultaneous triggers reveal one card.
  Future<Reveal>? _pending;

  @override
  Future<Map<String, Discovery>> build() =>
      ref.read(easterEggStoreProvider).load();

  /// Reveals a collectible not found before (chosen at random) and saves it
  /// at once; when all are found, reveals [CollectionComplete]. Calls made
  /// while one is in progress get the same reveal.
  Future<Reveal> discover() => _pending ??= _discover().whenComplete(() {
    _pending = null;
  });

  Future<Reveal> _discover() async {
    final found = Map.of(await future);
    final pick = pickUndiscovered(
      ref.read(collectiblesProvider),
      found.keys.toSet(),
      ref.read(easterEggRandomProvider),
    );
    if (pick == null) return const CollectionComplete();
    found[pick.id] = Discovery(
      discoveredAt: ref.read(rajyotsavaClockProvider)(),
    );
    state = AsyncData(Map.unmodifiable(found));
    try {
      await ref.read(easterEggStoreProvider).save(found);
    } on Object {
      // Shown anyway; it is saved again with the next discovery.
    }
    return NewCollectible(pick);
  }
}

/// Current time, for the Rajyotsava countdown. Override in tests.
final rajyotsavaClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Random source for shuffling quiz questions. Override with a seeded
/// [Random] in tests.
final quizRandomProvider = Provider<Random>((ref) => Random());

/// Deals balanced, non-repeating quiz rounds. Kept for the whole app run,
/// so leaving and reopening the quiz continues the same deck.
final quizDeckProvider = Provider<QuizDeck>(
  (ref) => QuizDeck(
    ref.watch(rajyotsavaContentProvider).quiz,
    ref.watch(quizRandomProvider),
  ),
);

/// The quiz in progress. Disposed when the quiz screen closes; the next
/// visit deals a fresh round from [quizDeckProvider].
final quizControllerProvider =
    NotifierProvider.autoDispose<QuizController, QuizSession>(
      QuizController.new,
    );

class QuizController extends Notifier<QuizSession> {
  /// Questions asked per round.
  static const int questionsPerRound = 10;

  @override
  QuizSession build() => _newRound();

  QuizSession _newRound() {
    final random = ref.read(quizRandomProvider);
    return QuizSession([
      // Options are shuffled too, so answers move around between rounds.
      for (final q in ref.read(quizDeckProvider).deal(questionsPerRound))
        q.withOptionOrder(
          List.generate(q.options.length, (i) => i)..shuffle(random),
        ),
    ]);
  }

  void answer(int option) => state = state.answer(option);

  void next() => state = state.next();

  /// A new round with questions not asked yet.
  void restart() => state = _newRound();
}
