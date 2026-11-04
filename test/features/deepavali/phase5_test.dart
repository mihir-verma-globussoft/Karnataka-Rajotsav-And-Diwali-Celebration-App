import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/diya_game.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/diya_game_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/diya_game_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/game_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_theme.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/diwali_motion.dart';

import '../../helpers.dart';

class _Store implements DiyaGameStore {
  final Map<DiyaDifficulty, Duration> best = {};
  @override
  Future<Duration?> bestTime(DiyaDifficulty difficulty) async =>
      best[difficulty];
  @override
  Future<void> saveBestTime(DiyaDifficulty difficulty, Duration time) async =>
      best[difficulty] = time;
}

/// A clock the test moves by hand.
class _Clock {
  Duration now = Duration.zero;
  Duration call() => now;
}

const Duration _s = Duration(seconds: 1);
Duration _secs(double s) => Duration(milliseconds: (s * 1000).round());

// Breezy timings, read from the game so tuning the wind never breaks tests.
final WindSpec _wind = DiyaDifficulty.breezy.wind!;
final Duration _gustAt = _wind.firstGust;
final Duration _warnAt = _gustAt - _wind.warning;
final Duration _nextGustAt = _gustAt + _wind.gapAfter(0);

/// The original no-wind game: nothing but the clock can end it.
DiyaGame _gentle() => const DiyaGame(difficulty: DiyaDifficulty.gentle).start();

DiyaGame _windy({
  DiyaDifficulty difficulty = DiyaDifficulty.breezy,
  int seed = 5,
}) => DiyaGame(difficulty: difficulty).start(seed: seed);

DiyaGame _light(DiyaGame g, Iterable<int> indexes) {
  var game = g;
  for (final i in indexes) {
    game = game.tap(i);
  }
  return game;
}

DiyaGame _lightAll(DiyaGame g) =>
    _light(g, List<int>.generate(DiyaGame.diyaCount, (i) => i));

void main() {
  reduceMotionForAllTests();

  group('DiyaGame basics (no wind)', () {
    test('starts ready with nothing lit', () {
      const g = DiyaGame();
      expect(g.phase, DiyaGamePhase.ready);
      expect(g.litCount, 0);
      expect(g.remaining, DiyaDifficulty.breezy.limit);
    });

    test('start only works from ready', () {
      final p = _gentle();
      expect(p.phase, DiyaGamePhase.playing);
      expect(identical(p.start(), p), isTrue);
      final paused = p.pause();
      expect(identical(paused.start(), paused), isTrue);
    });

    test('taps are ignored unless playing', () {
      const ready = DiyaGame();
      expect(identical(ready.tap(0), ready), isTrue);
      expect(_gentle().pause().tap(0).litCount, 0);
    });

    test('tapping lights a diya once; double taps never double count', () {
      final g = _gentle().tap(3).tap(3).tap(3);
      expect(g.litCount, 1);
      expect(g.lightings, 1);
      expect(g.isLit(3), isTrue);
      expect(g.isLit(4), isFalse);
    });

    test('out of range taps are ignored', () {
      final g = _gentle();
      expect(identical(g.tap(-1), g), isTrue);
      expect(identical(g.tap(DiyaGame.diyaCount), g), isTrue);
    });

    test('lighting all twelve wins; nothing more changes afterwards', () {
      final won = _lightAll(_gentle());
      expect(won.isWin, isTrue);
      expect(won.litCount, DiyaGame.diyaCount);
      expect(identical(won.tap(0), won), isTrue);
      expect(identical(won.tick(_s * 5), won), isTrue);
      expect(identical(won.pause(), won), isTrue);
    });

    test('the eleventh diya does not win', () {
      final g = _light(_gentle(), List.generate(11, (i) => i));
      expect(g.phase, DiyaGamePhase.playing);
    });

    test('tick records time, never goes backwards', () {
      var g = _gentle().tick(_s * 10);
      expect(g.elapsed, _s * 10);
      expect(g.remaining, _s * 35);
      g = g.tick(_gustAt);
      expect(g.elapsed, _s * 10);
    });

    test('reaching the limit ends the game as time up, clamped', () {
      final g = _gentle().tap(0).tick(_s * 50);
      expect(g.phase, DiyaGamePhase.timeUp);
      expect(g.elapsed, DiyaDifficulty.gentle.limit);
      expect(g.remaining, Duration.zero);
      expect(g.litCount, 1);
      expect(identical(g.tap(1), g), isTrue);
    });

    test('one tick short of the limit is still playing', () {
      final g = _gentle().tick(
        DiyaDifficulty.gentle.limit - const Duration(milliseconds: 1),
      );
      expect(g.phase, DiyaGamePhase.playing);
    });

    test('pause and resume; tick is ignored while paused', () {
      final paused = _gentle().tick(_s * 5).pause();
      expect(paused.phase, DiyaGamePhase.paused);
      expect(identical(paused.tick(_s * 30), paused), isTrue);
      expect(identical(paused.pause(), paused), isTrue);
      final back = paused.resume();
      expect(back.phase, DiyaGamePhase.playing);
      expect(back.elapsed, _s * 5);
      expect(identical(back.resume(), back), isTrue);
      const ready = DiyaGame();
      expect(identical(ready.resume(), ready), isTrue);
    });

    test('restart resets everything and keeps the settings', () {
      final g = const DiyaGame(
        relaxed: true,
        difficulty: DiyaDifficulty.stormy,
      ).start().tap(1).tick(_s * 9);
      final r = g.restart();
      expect(r.phase, DiyaGamePhase.playing);
      expect(r.litCount, 0);
      expect(r.elapsed, Duration.zero);
      expect(r.relaxed, isTrue);
      expect(r.difficulty, DiyaDifficulty.stormy);
      expect(_lightAll(_gentle()).restart().litCount, 0);
    });

    test('toReady is refused mid-game but allowed after the end', () {
      final p = _gentle();
      expect(identical(p.toReady(), p), isTrue);
      final paused = p.pause();
      expect(identical(paused.toReady(), paused), isTrue);
      expect(_lightAll(p).toReady().phase, DiyaGamePhase.ready);
      expect(_lightAll(p).toReady().litCount, 0);
      expect(const DiyaGame().toReady(relaxed: true).relaxed, isTrue);
      expect(
        const DiyaGame().toReady(difficulty: DiyaDifficulty.stormy).difficulty,
        DiyaDifficulty.stormy,
      );
    });

    test('relaxed mode has no limit and never times out', () {
      final g = const DiyaGame(relaxed: true)
          .start()
          .tick(const Duration(hours: 2));
      expect(g.limit, isNull);
      expect(g.remaining, isNull);
      expect(g.phase, DiyaGamePhase.playing);
      expect(g.elapsed, const Duration(hours: 2));
    });
  });

  group('wind', () {
    // Breezy: the first gust lands at `_gustAt`, its warning `_wind.warning`
    // earlier, then gaps that shrink.
    test('gentle and relaxed games have no wind at all', () {
      final gentle = _gentle().tap(0).tap(1).tick(_s * 44);
      expect(gentle.hasWind, isFalse);
      expect(gentle.litCount, 2);
      expect(gentle.blownOut, 0);

      final relaxed = const DiyaGame(relaxed: true).start(seed: 2);
      final later = _light(relaxed, [0, 1, 2]).tick(const Duration(hours: 1));
      expect(later.hasWind, isFalse);
      expect(later.litCount, 3);
    });

    test('a threatened diya is named shortly before the gust', () {
      var g = _light(_windy(), [0, 1, 2]);
      g = g.tick(_warnAt - const Duration(milliseconds: 100));
      expect(g.warning, isNull);
      g = g.tick(_warnAt);
      expect(g.warning, isNotNull);
      expect({0, 1, 2}, contains(g.warning));
      expect(g.isThreatened(g.warning!), isTrue);
      expect(g.litCount, 3, reason: 'warned, not yet blown out');
      g = g.tick(_gustAt - const Duration(milliseconds: 10));
      expect(g.litCount, 3);
    });

    test('the gust puts the warned diya out and schedules the next', () {
      var g = _light(_windy(), [0, 1, 2]).tick(_warnAt);
      final target = g.warning!;
      g = g.tick(_gustAt);
      expect(g.litCount, 2);
      expect(g.isLit(target), isFalse);
      expect(g.blownOut, 1);
      expect(g.gustCount, 1);
      expect(g.warning, isNull);
      expect(g.nextGust, _nextGustAt);
    });

    test('a put-out diya can be relit', () {
      var g = _light(_windy(), [0, 1, 2]).tick(_warnAt);
      final target = g.warning!;
      g = g.tick(_gustAt).tap(target);
      expect(g.isLit(target), isTrue);
      expect(g.litCount, 3);
      expect(g.lightings, 4);
    });

    test('tapping the warned diya shields it from that gust', () {
      var g = _light(_windy(), [0, 1, 2]).tick(_warnAt);
      final target = g.warning!;
      g = g.tap(target);
      expect(g.shielded, isTrue);
      expect(g.isShielded(target), isTrue);
      expect(g.isThreatened(target), isFalse);
      expect(g.shields, 1);
      // A second tap cannot shield twice.
      final again = g.tap(target);
      expect(identical(again, g), isTrue);
      g = g.tick(_gustAt);
      expect(g.litCount, 3);
      expect(g.blownOut, 0);
      expect(g.gustCount, 1);
      expect(g.warning, isNull);
      expect(g.shielded, isFalse);
    });

    test('tapping a different lit diya during the warning does nothing', () {
      final g = _light(_windy(), [0, 1, 2]).tick(_warnAt);
      final other = [0, 1, 2].firstWhere((i) => i != g.warning);
      expect(identical(g.tap(other), g), isTrue);
    });

    test('shielding is only possible during the warning', () {
      final g = _light(_windy(), [0, 1, 2]).tick(_s * 1);
      expect(identical(g.tap(0), g), isTrue);
    });

    test('a gust with nothing lit passes harmlessly', () {
      final g = _windy().tick(_warnAt);
      expect(g.warning, isNull);
      expect(g.gustCount, 1);
      expect(g.nextGust, _nextGustAt);
      expect(g.blownOut, 0);
    });

    test('gaps shrink with each gust and stop at the minimum', () {
      const w = WindSpec(
        firstGust: Duration(seconds: 4),
        interval: Duration(milliseconds: 2800),
        shrink: 0.96,
        minInterval: Duration(milliseconds: 1600),
        warning: Duration(milliseconds: 800),
      );
      expect(w.gapAfter(0), _secs(2.8));
      expect(w.gapAfter(5), lessThan(w.gapAfter(1)));
      expect(w.gapAfter(100), _secs(1.6));
    });

    test('stormy is harder than breezy', () {
      final b = DiyaDifficulty.breezy.wind!;
      final s = DiyaDifficulty.stormy.wind!;
      expect(s.firstGust, lessThan(b.firstGust));
      expect(s.interval, lessThan(b.interval));
      expect(s.warning, lessThan(b.warning));
      expect(
        DiyaDifficulty.stormy.limit,
        lessThan(DiyaDifficulty.breezy.limit),
      );
    });

    test('the same seed gives the same gust; seeds vary the target', () {
      DiyaGame warned(int seed) =>
          _light(_windy(seed: seed), List.generate(11, (i) => i)).tick(_warnAt);
      expect(warned(9).warning, warned(9).warning);
      final targets = {for (var s = 0; s < 30; s++) warned(s).warning};
      expect(targets.length, greaterThan(3));
    });

    test('a long gap between ticks still plays every gust, then stops', () {
      final g = _light(_windy(), [0, 1, 2, 3, 4]).tick(_s * 14);
      expect(g.litCount, 0);
      expect(g.blownOut, 5);
      expect(g.phase, DiyaGamePhase.playing);
    });

    test('time up still applies the wind up to the limit', () {
      final g = _light(_windy(), [0, 1, 2]).tick(_s * 60);
      expect(g.phase, DiyaGamePhase.timeUp);
      expect(g.elapsed, DiyaDifficulty.breezy.limit);
      expect(g.litCount, lessThanOrEqualTo(3));
    });

    test('lighting the last diya wins and clears any warning', () {
      var g = _light(_windy(), List.generate(11, (i) => i)).tick(_warnAt);
      expect(g.warning, isNotNull);
      g = g.tap(11);
      expect(g.isWin, isTrue);
      expect(g.warning, isNull);
      expect(g.shielded, isFalse);
    });

    test('wind never moves while paused', () {
      var g = _light(_windy(), [0, 1, 2]).tick(_warnAt).pause();
      final warning = g.warning;
      g = g.tick(_s * 30);
      expect(g.warning, warning);
      expect(g.blownOut, 0);
      g = g.resume().tick(_gustAt);
      expect(g.blownOut, 1);
    });

    test('restart clears the wind and reschedules the first gust', () {
      final g = _light(_windy(), [0, 1]).tick(_s * 10).restart(seed: 3);
      expect(g.gustCount, 0);
      expect(g.blownOut, 0);
      expect(g.warning, isNull);
      expect(g.nextGust, DiyaDifficulty.breezy.wind!.firstGust);
    });
  });

  group('DiyaGameNotifier', () {
    late _Clock clock;
    late _Store store;
    late ProviderContainer container;

    DiyaGameNotifier notifier() => container.read(diyaGameProvider.notifier);
    DiyaGame game() => container.read(diyaGameProvider);

    setUp(() {
      clock = _Clock();
      store = _Store();
      container = ProviderContainer(
        overrides: [
          diyaGameClockProvider.overrideWithValue(clock.call),
          diyaGameStoreProvider.overrideWithValue(store),
          diyaGameSeedProvider.overrideWithValue(() => 5),
        ],
      );
    });

    // Disposed inside each test body: a pending timer must be gone before the
    // test ends.
    void notifierTest(
      String name,
      Future<void> Function(WidgetTester tester) body,
    ) => testWidgets(name, (tester) async {
      await body(tester);
      container.dispose();
      await tester.pump();
    });

    Future<void> advance(WidgetTester tester, Duration d) async {
      clock.now += d;
      await tester.pump(d);
    }

    void startGentle() {
      notifier().setDifficulty(DiyaDifficulty.gentle);
      notifier().start();
    }

    notifierTest('time counts only while playing', (tester) async {
      startGentle();
      await advance(tester, _s * 10);
      expect(game().elapsed, _s * 10);

      notifier().pause();
      await advance(tester, _s * 20);
      expect(game().phase, DiyaGamePhase.paused);
      expect(game().elapsed, _s * 10);

      notifier().resume();
      await advance(tester, _s * 5);
      expect(game().elapsed, _s * 15);
    });

    notifierTest('time runs out at the limit and stops the timer', (
      tester,
    ) async {
      startGentle();
      notifier().tap(0);
      await advance(tester, _s * 44);
      expect(game().phase, DiyaGamePhase.playing);
      await advance(tester, _s * 2);
      expect(game().phase, DiyaGamePhase.timeUp);
      expect(game().litCount, 1);
      await advance(tester, _s * 30);
      expect(game().elapsed, DiyaDifficulty.gentle.limit);
    });

    notifierTest('best times are kept per difficulty and only improve', (
      tester,
    ) async {
      void winAfter(Duration t) {
        notifier().restart();
        clock.now += t;
      }

      startGentle();
      clock.now += _s * 20;
      for (var i = 0; i < DiyaGame.diyaCount; i++) {
        expect(notifier().tap(i), DiyaTap.lit);
      }
      await tester.pump();
      expect(game().isWin, isTrue);
      expect(game().elapsed, _s * 20);
      expect(store.best[DiyaDifficulty.gentle], _s * 20);

      winAfter(_s * 30);
      for (var i = 0; i < DiyaGame.diyaCount; i++) {
        notifier().tap(i);
      }
      await tester.pump();
      expect(store.best[DiyaDifficulty.gentle], _s * 20, reason: 'slower');

      winAfter(_s * 12);
      for (var i = 0; i < DiyaGame.diyaCount; i++) {
        notifier().tap(i);
      }
      await tester.pump();
      expect(store.best[DiyaDifficulty.gentle], _s * 12);
      expect(store.best.containsKey(DiyaDifficulty.breezy), isFalse);
    });

    notifierTest('a breezy win is recorded under breezy', (tester) async {
      notifier().setDifficulty(DiyaDifficulty.breezy);
      notifier().start();
      clock.now += _s * 1;
      for (var i = 0; i < DiyaGame.diyaCount; i++) {
        notifier().tap(i);
      }
      await tester.pump();
      expect(game().isWin, isTrue);
      expect(store.best[DiyaDifficulty.breezy], _s * 1);
      expect(store.best.containsKey(DiyaDifficulty.gentle), isFalse);
    });

    notifierTest('relaxed wins are not recorded as best times', (tester) async {
      notifier().setRelaxed(value: true);
      notifier().start();
      await advance(tester, _s * 90);
      for (var i = 0; i < DiyaGame.diyaCount; i++) {
        notifier().tap(i);
      }
      await tester.pump();
      expect(game().isWin, isTrue);
      expect(store.best, isEmpty);
    });

    notifierTest('wind: warning, shield and blow-out through the timer', (
      tester,
    ) async {
      notifier().setDifficulty(DiyaDifficulty.breezy);
      notifier().start();
      for (var i = 0; i < 4; i++) {
        expect(notifier().tap(i), DiyaTap.lit);
      }
      await advance(tester, _warnAt);
      expect(game().warning, isNotNull);
      final first = game().warning!;
      expect(notifier().tap(first), DiyaTap.shielded);
      expect(notifier().tap(first), DiyaTap.none);
      await advance(tester, _wind.warning);
      expect(game().blownOut, 0);
      expect(game().litCount, 4);

      // The next gust is not shielded and takes a diya.
      await advance(tester, _wind.gapAfter(0));
      expect(game().blownOut, 1);
      expect(game().litCount, 3);
    });

    notifierTest('a repeated tap reports none and changes nothing', (
      tester,
    ) async {
      startGentle();
      expect(notifier().tap(2), DiyaTap.lit);
      expect(notifier().tap(2), DiyaTap.none);
      expect(game().litCount, 1);
      await tester.pump();
    });

    notifierTest('restart gives a fresh clock', (tester) async {
      startGentle();
      await advance(tester, _s * 30);
      notifier().restart();
      expect(game().elapsed, Duration.zero);
      await advance(tester, _s * 3);
      expect(game().elapsed, _s * 3);
    });

    notifierTest('settings cannot change mid-game', (tester) async {
      startGentle();
      notifier().setRelaxed(value: true);
      notifier().setDifficulty(DiyaDifficulty.stormy);
      expect(game().relaxed, isFalse);
      expect(game().difficulty, DiyaDifficulty.gentle);
      await tester.pump();
    });
  });

  group('DiyaGameSection', () {
    late _Clock clock;
    late _Store store;

    Widget app({double scale = 1, Size size = const Size(360, 800)}) {
      return ProviderScope(
        overrides: [
          diyaGameClockProvider.overrideWithValue(clock.call),
          diyaGameStoreProvider.overrideWithValue(store),
          diyaGameSeedProvider.overrideWithValue(() => 5),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: MaterialApp(
            theme: DiwaliTheme.data,
            home: const Scaffold(
              body: DiwaliMotionScope(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: DiyaGameSection(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    setUp(() {
      clock = _Clock();
      store = _Store();
    });

    /// Runs [body] on a phone-sized view, then removes the tree so the game's
    /// timer is cancelled before the test ends.
    void sectionTest(
      String name,
      Future<void> Function(WidgetTester tester) body, {
      Size size = const Size(360, 800),
    }) => testWidgets(name, (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await body(tester);
      await tester.pumpWidget(const SizedBox());
    });

    Finder diya(int n) =>
        find.bySemanticsLabel(RegExp('^Diya $n of 12, unlit'));

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pump();
    }

    Future<void> startGentle(WidgetTester tester) async {
      await tapText(tester, 'Gentle');
      await tapText(tester, 'Start');
    }

    sectionTest(
      'ready screen shows levels, rules, best time and relaxed mode',
      (tester) async {
        store.best[DiyaDifficulty.breezy] = _s * 31;
        store.best[DiyaDifficulty.stormy] = _s * 22;
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(find.text('Light the Diyas'), findsOneWidget);
        for (final d in DiyaDifficulty.values) {
          expect(find.text(d.label), findsOneWidget);
        }
        expect(find.text('Start'), findsOneWidget);
        expect(find.text('Relaxed mode (no timer, no wind)'), findsOneWidget);
        // Breezy is the default and is a windy game.
        expect(find.textContaining('Gusts blow out one diya'), findsOneWidget);
        expect(find.text('Best: 31 s'), findsOneWidget);

        await tapText(tester, 'Stormy');
        expect(find.textContaining('Faster, fiercer gusts'), findsOneWidget);
        expect(find.text('Best: 22 s'), findsOneWidget);

        await tapText(tester, 'Gentle');
        expect(find.textContaining('No wind.'), findsOneWidget);
        expect(find.text('Best: —'), findsOneWidget);
      },
    );

    sectionTest('play through on Gentle: light diyas, counter, win', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await startGentle(tester);
      expect(find.text('0 / 12 lit'), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);
      // No wind banner without wind.
      expect(find.bySemanticsLabel(RegExp('Wind')), findsNothing);

      await tester.tap(diya(1));
      await tester.pump();
      expect(find.text('1 / 12 lit'), findsOneWidget);
      expect(diya(1), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('^Diya 1 of 12, lit')),
        findsOneWidget,
      );

      for (var n = 2; n <= 12; n++) {
        await tester.ensureVisible(diya(n));
        await tester.tap(diya(n));
        await tester.pump();
      }
      expect(find.text('All 12 diyas are glowing!'), findsOneWidget);
      expect(find.text('Play again'), findsOneWidget);
      expect(find.text('Change level'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      handle.dispose();
    });

    sectionTest('breezy: a warned diya can be shielded; stats are shown', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Start');
      expect(find.bySemanticsLabel(RegExp('Wind is calm')), findsOneWidget);
      for (var n = 1; n <= 4; n++) {
        await tester.tap(diya(n));
        await tester.pump();
      }
      clock.now = _warnAt + _secs(0.1);
      await tester.pump(clock.now);
      expect(find.bySemanticsLabel(RegExp('Wind gust coming')), findsOneWidget);
      final danger = find.bySemanticsLabel(RegExp('in danger from the wind'));
      expect(danger, findsOneWidget);
      await tester.tap(danger);
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp('Diya shielded from the wind')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('lit and shielded')), findsOneWidget);

      // Past the gust: the shield held, all four still burn.
      clock.now = _gustAt + _secs(0.2);
      await tester.pump(_secs(0.9));
      expect(find.text('4 / 12 lit'), findsOneWidget);

      // Light the rest to win and see the wind stats.
      for (var n = 1; n <= 12; n++) {
        final unlit = diya(n);
        if (unlit.evaluate().isEmpty) continue;
        await tester.ensureVisible(unlit);
        await tester.tap(unlit);
        await tester.pump();
      }
      expect(find.text('All 12 diyas are glowing!'), findsOneWidget);
      expect(find.text('Blown out 0× · Shielded 1×'), findsOneWidget);
      handle.dispose();
    });

    sectionTest('an unshielded gust puts a diya out on screen', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Start');
      for (var n = 1; n <= 4; n++) {
        await tester.tap(diya(n));
        await tester.pump();
      }
      clock.now = _gustAt + _secs(0.1);
      await tester.pump(clock.now);
      expect(find.text('3 / 12 lit'), findsOneWidget);
      handle.dispose();
    });

    sectionTest('time up shows the result and Try again restarts', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await startGentle(tester);
      await tester.tap(diya(1));
      await tester.tap(diya(2));
      await tester.pump();
      clock.now = _s * 46;
      await tester.pump(_s * 46);
      expect(find.text('Time’s up! 2 / 12 lit'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tapText(tester, 'Try again');
      expect(find.text('0 / 12 lit'), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);
      handle.dispose();
    });

    sectionTest('losing to the wind says so; Change level returns', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Stormy');
      await tapText(tester, 'Start');
      clock.now = _s * 50;
      await tester.pump(_s * 50);
      expect(find.textContaining('Time’s up!'), findsOneWidget);
      expect(find.text('The wind won this time. Try again.'), findsOneWidget);
      await tapText(tester, 'Change level');
      expect(find.text('Start'), findsOneWidget);
      handle.dispose();
    });

    sectionTest('pause dims the board; Resume continues', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await startGentle(tester);
      clock.now = _s * 10;
      await tester.pump(_s * 10);
      expect(find.text('00:35'), findsOneWidget);

      await tapText(tester, 'Pause');
      expect(find.text('Paused'), findsOneWidget);
      clock.now = _s * 40;
      await tester.pump(_s * 30);
      expect(find.text('00:35'), findsOneWidget);

      await tapText(tester, 'Resume');
      expect(find.text('Paused'), findsNothing);
      clock.now = _s * 45;
      await tester.pump(_s * 5);
      expect(find.text('00:30'), findsOneWidget);
      handle.dispose();
    });

    sectionTest('Restart mid-game clears progress', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await startGentle(tester);
      await tester.tap(diya(4));
      await tester.pump();
      expect(find.text('1 / 12 lit'), findsOneWidget);
      await tapText(tester, 'Restart');
      expect(find.text('0 / 12 lit'), findsOneWidget);
      handle.dispose();
    });

    sectionTest('relaxed mode counts up, has no wind and never times out', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(
        find.textContaining('Light all 12 diyas at once, at your own pace'),
        findsOneWidget,
      );
      await tapText(tester, 'Start');
      clock.now = const Duration(minutes: 5);
      await tester.pump(const Duration(minutes: 5));
      expect(find.text('05:00'), findsOneWidget);
      expect(find.textContaining('Time’s up'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Wind')), findsNothing);
    });

    for (final (name, size, scale) in [
      ('320x568 at 2x text', const Size(320, 568), 2.0),
      ('360x800', const Size(360, 800), 1.0),
      ('600x900', const Size(600, 900), 1.0),
    ]) {
      sectionTest('every state fits at $name', size: size, (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(app(scale: scale, size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        for (final level in ['Stormy', 'Gentle', 'Breezy']) {
          await tapText(tester, level);
          expect(tester.takeException(), isNull);
        }

        await tapText(tester, 'Start');
        expect(tester.takeException(), isNull);

        // Warning state: light a few, run to the warning.
        for (var n = 1; n <= 4; n++) {
          await tester.ensureVisible(diya(n));
          await tester.tap(diya(n));
          await tester.pump();
        }
        clock.now = _warnAt + _secs(0.1);
        await tester.pump(clock.now);
        expect(tester.takeException(), isNull);

        await tapText(tester, 'Pause');
        expect(tester.takeException(), isNull);
        await tapText(tester, 'Resume');

        clock.now = _s * 50;
        await tester.pump(_s * 50);
        expect(find.textContaining('Time’s up'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tapText(tester, 'Try again');
        for (var n = 1; n <= 12; n++) {
          await tester.ensureVisible(diya(n));
          await tester.tap(diya(n));
          await tester.pump();
        }
        expect(find.text('All 12 diyas are glowing!'), findsOneWidget);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }
  });

  group('formatting', () {
    test('game time', () {
      expect(formatGameTime(_s * 45), '00:45');
      expect(formatGameTime(const Duration(milliseconds: 44100)), '00:44');
      expect(
        formatGameTime(const Duration(milliseconds: 44100), roundUp: true),
        '00:45',
      );
      expect(formatGameTime(const Duration(minutes: 5)), '05:00');
    });
    test('result time', () {
      expect(formatResultTime(_s * 24), '24 s');
      expect(formatResultTime(const Duration(milliseconds: 24500)), '24.5 s');
    });
  });
}
