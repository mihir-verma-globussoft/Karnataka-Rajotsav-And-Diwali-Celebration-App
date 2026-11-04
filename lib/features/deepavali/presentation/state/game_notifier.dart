import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';
import '../../domain/deepavali_scores.dart';
import '../../domain/diya_game.dart';

/// Fastest winning time per difficulty. Not autoDispose: the tab stays
/// mounted for the life of the app.
class DiyaBestNotifier extends AsyncNotifier<Map<DiyaDifficulty, Duration>> {
  @override
  Future<Map<DiyaDifficulty, Duration>> build() async {
    final store = ref.read(diyaGameStoreProvider);
    final best = <DiyaDifficulty, Duration>{};
    for (final d in DiyaDifficulty.values) {
      final t = await store.bestTime(d);
      if (t != null) best[d] = t;
    }
    return best;
  }

  /// Records [time] if it beats the best for [difficulty]. Returns true for a
  /// new best.
  Future<bool> submit(DiyaDifficulty difficulty, Duration time) async {
    final current = await future;
    final old = current[difficulty];
    if (old != null && time >= old) return false;
    state = AsyncData({...current, difficulty: time});
    await ref.read(diyaGameStoreProvider).saveBestTime(difficulty, time);
    return true;
  }
}

final diyaBestProvider =
    AsyncNotifierProvider<DiyaBestNotifier, Map<DiyaDifficulty, Duration>>(
      DiyaBestNotifier.new,
    );

/// What a tap did.
enum DiyaTap { none, lit, shielded }

/// Drives [DiyaGame]: owns the play clock and the polling timer.
///
/// Play time is accumulated from a monotonic clock only while playing, so
/// pausing (or the tab being hidden) stops the game cleanly and jank cannot
/// drift the timer. The timer exists only while playing.
class DiyaGameNotifier extends Notifier<DiyaGame> {
  static const Duration _poll = Duration(milliseconds: 100);

  Timer? _timer;
  String _roundId = '';
  DateTime _startedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// The won game being sent to the leaderboard, once there is one. Null
  /// after a loss and in relaxed mode, which are not ranked.
  Future<ScoreSaveOutcome>? get saving => _saving;
  Future<ScoreSaveOutcome>? _saving;

  Duration _banked = Duration.zero;
  Duration? _segmentStart;

  @override
  DiyaGame build() {
    ref.onDispose(_stopTimer);
    return const DiyaGame();
  }

  Duration get _now => ref.read(diyaGameClockProvider)();

  void _begin() {
    // Games that could not be sent last time go now.
    unawaited(ref.read(deepavaliScoreboardProvider).sendPending());
    _saving = null;
    _roundId = newRoundId(Random.secure());
    _startedAt = ref.read(deepavaliNowProvider)();
    _banked = Duration.zero;
    _segmentStart = _now;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_poll, (_) => _tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Duration _played() {
    final start = _segmentStart;
    return start == null ? _banked : _banked + (_now - start);
  }

  void _bank() {
    _banked = _played();
    _segmentStart = null;
  }

  void _tick() {
    if (!state.isRunning) return;
    _apply(state.tick(_played()));
  }

  /// Applies [next] and handles the side effects of entering a final phase.
  void _apply(DiyaGame next) {
    final wasRunning = state.isRunning;
    state = next;
    if (wasRunning && next.isFinished) {
      _bank();
      _stopTimer();
      if (next.isWin && !next.relaxed) {
        unawaited(
          ref
              .read(diyaBestProvider.notifier)
              .submit(next.difficulty, next.elapsed),
        );
        _saving = ref
            .read(deepavaliScoreboardProvider)
            .save(
              GameRound(
                id: _roundId,
                game: DeepavaliGame.diya,
                points: DeepavaliPoints.forDiya(
                  difficulty: next.difficulty,
                  elapsed: next.elapsed,
                ),
                duration: next.elapsed,
                startedAt: _startedAt,
              ),
            );
      }
    }
  }

  int get _seed => ref.read(diyaGameSeedProvider)();

  void start() {
    if (state.phase != DiyaGamePhase.ready) return;
    state = state.start(seed: _seed);
    _begin();
  }

  void restart() {
    _stopTimer();
    state = state.restart(seed: _seed);
    _begin();
  }

  void toReady() {
    if (state.isRunning || state.phase == DiyaGamePhase.paused) return;
    state = state.toReady();
  }

  void setRelaxed({required bool value}) {
    if (state.isRunning || state.phase == DiyaGamePhase.paused) return;
    state = state.toReady(relaxed: value);
  }

  void setDifficulty(DiyaDifficulty value) {
    if (state.isRunning || state.phase == DiyaGamePhase.paused) return;
    state = state.toReady(difficulty: value);
  }

  /// Taps diya [index]: lights it, or shields it from a coming gust.
  DiyaTap tap(int index) {
    if (!state.isRunning) return DiyaTap.none;
    // Bring the clock (and the wind) up to date first so the tap is judged
    // against the right moment.
    final timed = state.tick(_played());
    final next = timed.tap(index);
    if (identical(next, timed)) {
      _apply(timed);
      return DiyaTap.none;
    }
    _apply(next);
    return next.shields > timed.shields ? DiyaTap.shielded : DiyaTap.lit;
  }

  void pause() {
    if (!state.isRunning) return;
    _tick();
    if (!state.isRunning) return;
    _bank();
    _stopTimer();
    state = state.pause();
  }

  void resume() {
    if (state.phase != DiyaGamePhase.paused) return;
    state = state.resume();
    _segmentStart = _now;
    _startTimer();
  }
}

final diyaGameProvider = NotifierProvider<DiyaGameNotifier, DiyaGame>(
  DiyaGameNotifier.new,
);
