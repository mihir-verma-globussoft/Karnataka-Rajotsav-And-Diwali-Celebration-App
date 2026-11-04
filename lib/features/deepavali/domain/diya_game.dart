import 'dart:math';

/// Where the "Light the Diyas" game is.
enum DiyaGamePhase { ready, playing, paused, complete, timeUp }

/// How the wind behaves: gusts blow out one lit diya at a time, with a
/// warning first. Gusts come faster the longer the game runs.
class WindSpec {
  const WindSpec({
    required this.firstGust,
    required this.interval,
    required this.shrink,
    required this.minInterval,
    required this.warning,
  });

  /// When the first gust lands.
  final Duration firstGust;

  /// Gap between the first and second gust.
  final Duration interval;

  /// Each later gap is the previous one times this (0..1).
  final double shrink;

  /// Gaps never get shorter than this.
  final Duration minInterval;

  /// How long before a gust the threatened diya starts shaking. Tapping it in
  /// this window shields it.
  final Duration warning;

  /// Gap after the [gustsSoFar]th gust.
  Duration gapAfter(int gustsSoFar) {
    final micros = interval.inMicroseconds * pow(shrink, gustsSoFar);
    final clamped = max(micros, minInterval.inMicroseconds.toDouble());
    return Duration(microseconds: clamped.round());
  }
}

/// Difficulty levels. Gentle is the original no-wind game.
enum DiyaDifficulty {
  gentle('Gentle', Duration(seconds: 45), null),
  breezy(
    'Breezy',
    Duration(seconds: 20),
    WindSpec(
      firstGust: Duration(milliseconds: 2500),
      interval: Duration(milliseconds: 800),
      shrink: 0.98,
      minInterval: Duration(milliseconds: 600),
      warning: Duration(milliseconds: 500),
    ),
  ),
  stormy(
    'Stormy',
    Duration(seconds: 16),
    WindSpec(
      firstGust: Duration(milliseconds: 1500),
      interval: Duration(milliseconds: 550),
      shrink: 0.98,
      minInterval: Duration(milliseconds: 420),
      warning: Duration(milliseconds: 380),
    ),
  );

  const DiyaDifficulty(this.label, this.limit, this.wind);

  final String label;

  /// Time allowed (unless relaxed mode is on).
  final Duration limit;

  /// Null means no wind.
  final WindSpec? wind;
}

/// Pure, immutable state machine for the diya game. Every method returns the
/// new state; illegal moves return `this` unchanged, so callers never need to
/// guard.
///
/// ```
/// ready -> playing <-> paused
///           playing -> complete | timeUp
/// complete | timeUp | playing | paused -> restart() -> playing
/// ```
///
/// You win by having all diyas lit at the same moment. With wind on, gusts
/// blow out one lit diya at a time; the diya about to go out shakes for a
/// moment first, and tapping it then shields it from that gust.
///
/// Time is the *total played time* handed in by the caller from a monotonic
/// source ([tick]); the game never counts down by itself, so a janky frame
/// cannot make the timer drift. Gust targets come from a seeded generator, so
/// the same seed always plays out the same way.
class DiyaGame {
  const DiyaGame({
    this.phase = DiyaGamePhase.ready,
    this.lit = const <int>{},
    this.elapsed = Duration.zero,
    this.relaxed = false,
    this.difficulty = DiyaDifficulty.breezy,
    this.seed = 0,
    this.nextGust = Duration.zero,
    this.gustCount = 0,
    this.warning,
    this.shielded = false,
    this.lightings = 0,
    this.blownOut = 0,
    this.shields = 0,
  });

  /// Number of diyas on the board.
  static const int diyaCount = 12;

  final DiyaGamePhase phase;

  /// Indexes (0..[diyaCount]-1) of the lit diyas.
  final Set<int> lit;

  /// Total time played so far (paused time excluded).
  final Duration elapsed;

  /// Relaxed mode has no timer and no wind: an accommodation for people who
  /// need longer.
  final bool relaxed;
  final DiyaDifficulty difficulty;
  final int seed;

  /// When the next gust lands.
  final Duration nextGust;

  /// Gusts that have passed (blown, shielded or skipped).
  final int gustCount;

  /// The lit diya the next gust will hit, while its warning shows.
  final int? warning;

  /// The warned diya has been shielded from the coming gust.
  final bool shielded;

  /// Times a diya was lit by tapping.
  final int lightings;

  /// Diyas the wind has put out.
  final int blownOut;

  /// Gusts defeated by shielding.
  final int shields;

  int get litCount => lit.length;

  /// The lit diyas as bits, so "has the board changed?" is one int compare.
  int get litMask => lit.fold(0, (mask, i) => mask | (1 << i));

  bool isLit(int index) => lit.contains(index);

  /// Null in relaxed mode.
  Duration? get limit => relaxed ? null : difficulty.limit;

  /// Null when this game has no wind.
  WindSpec? get wind => relaxed ? null : difficulty.wind;
  bool get hasWind => wind != null;

  /// Time left, never negative; null in relaxed mode.
  Duration? get remaining {
    final l = limit;
    if (l == null) return null;
    final left = l - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// A gust is about to hit [index] and it has not been shielded.
  bool isThreatened(int index) => warning == index && !shielded;
  bool isShielded(int index) => warning == index && shielded;

  bool get isRunning => phase == DiyaGamePhase.playing;
  bool get isFinished =>
      phase == DiyaGamePhase.complete || phase == DiyaGamePhase.timeUp;

  /// Won: every diya lit at once.
  bool get isWin => phase == DiyaGamePhase.complete;

  DiyaGame _copy({
    DiyaGamePhase? phase,
    Set<int>? lit,
    Duration? elapsed,
    bool? relaxed,
    DiyaDifficulty? difficulty,
    Duration? nextGust,
    int? gustCount,
    int? Function()? warning,
    bool? shielded,
    int? lightings,
    int? blownOut,
    int? shields,
  }) => DiyaGame(
    phase: phase ?? this.phase,
    lit: lit ?? this.lit,
    elapsed: elapsed ?? this.elapsed,
    relaxed: relaxed ?? this.relaxed,
    difficulty: difficulty ?? this.difficulty,
    seed: seed,
    nextGust: nextGust ?? this.nextGust,
    gustCount: gustCount ?? this.gustCount,
    warning: warning == null ? this.warning : warning(),
    shielded: shielded ?? this.shielded,
    lightings: lightings ?? this.lightings,
    blownOut: blownOut ?? this.blownOut,
    shields: shields ?? this.shields,
  );

  DiyaGame _fresh({required int seed}) {
    final probe = DiyaGame(relaxed: relaxed, difficulty: difficulty);
    return DiyaGame(
      phase: DiyaGamePhase.playing,
      relaxed: relaxed,
      difficulty: difficulty,
      seed: seed,
      nextGust: probe.wind?.firstGust ?? Duration.zero,
    );
  }

  /// ready -> playing. [seed] decides which diyas the wind targets.
  DiyaGame start({int seed = 0}) =>
      phase == DiyaGamePhase.ready ? _fresh(seed: seed) : this;

  /// Starts a fresh game from any phase, keeping the settings.
  DiyaGame restart({int seed = 0}) => _fresh(seed: seed);

  /// Back to the start screen, optionally changing settings. Only when not
  /// mid-game.
  DiyaGame toReady({bool? relaxed, DiyaDifficulty? difficulty}) =>
      isRunning || phase == DiyaGamePhase.paused
      ? this
      : DiyaGame(
          relaxed: relaxed ?? this.relaxed,
          difficulty: difficulty ?? this.difficulty,
        );

  /// Taps diya [index]. An unlit diya lights (lighting the last one wins). A
  /// lit diya that a gust is about to hit gets shielded. Everything else is
  /// ignored, so double taps never count twice.
  DiyaGame tap(int index) {
    if (!isRunning || index < 0 || index >= diyaCount) return this;
    if (lit.contains(index)) {
      if (isThreatened(index)) {
        return _copy(shielded: true, shields: shields + 1);
      }
      return this;
    }
    final next = Set<int>.unmodifiable(<int>{...lit, index});
    final won = next.length == diyaCount;
    return _copy(
      lit: next,
      lightings: lightings + 1,
      phase: won ? DiyaGamePhase.complete : null,
      warning: won ? () => null : null,
      shielded: won ? false : null,
    );
  }

  /// Records [played] total play time and lets the wind act up to then. Only
  /// while playing, never goes backwards, and ends the game when the limit is
  /// reached.
  DiyaGame tick(Duration played) {
    if (!isRunning || played <= elapsed) return this;
    final l = limit;
    final reached = l != null && played >= l;
    final upTo = reached ? l : played;
    final moved = _blow(upTo);
    return reached ? moved._copy(phase: DiyaGamePhase.timeUp) : moved;
  }

  /// Applies every warning and gust due by [t].
  DiyaGame _blow(Duration t) {
    final w = wind;
    if (w == null) return _copy(elapsed: t);
    final alive = <int>{...lit};
    var warn = warning;
    var shield = shielded;
    var next = nextGust;
    var gusts = gustCount;
    var out = blownOut;
    while (true) {
      if (warn == null) {
        if (next - w.warning > t) break;
        if (alive.isEmpty) {
          // Nothing to blow out: this gust passes.
          next += w.gapAfter(gusts);
          gusts++;
          continue;
        }
        final candidates = alive.toList()..sort();
        warn = candidates[_pick(gusts, candidates.length)];
        shield = false;
      } else {
        if (next > t) break;
        if (!shield && alive.remove(warn)) out++;
        warn = null;
        shield = false;
        next += w.gapAfter(gusts);
        gusts++;
      }
    }
    return _copy(
      elapsed: t,
      lit: Set<int>.unmodifiable(alive),
      nextGust: next,
      gustCount: gusts,
      warning: () => warn,
      shielded: shield,
      blownOut: out,
    );
  }

  int _pick(int gust, int count) =>
      Random((seed * 31 + gust * 7919 + 17) & 0x7fffffff).nextInt(count);

  /// playing -> paused.
  DiyaGame pause() => isRunning ? _copy(phase: DiyaGamePhase.paused) : this;

  /// paused -> playing.
  DiyaGame resume() => phase == DiyaGamePhase.paused
      ? _copy(phase: DiyaGamePhase.playing)
      : this;
}
