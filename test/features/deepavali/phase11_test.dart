import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/content/destinations.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/deepavali_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/diya_game.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/diya_game_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/sound.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/wish.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/wish_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/deepavali_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/countdown_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/destinations_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/diya_game_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/explorer_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/greeting_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/hero_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/more_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/quiz_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/rangoli_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/game_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/greeting_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/rangoli_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_palette.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_theme.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/deepavali_music.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/diwali_motion.dart';

import '../../helpers.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Every file under [dir], relative names only.
List<String> _filesIn(String dir) => [
  for (final e in Directory(dir).listSync())
    if (e is File) e.uri.pathSegments.last,
];

class _Intro implements DeepavaliStore {
  @override
  Future<bool> introSeen() async => true;
  @override
  Future<void> markIntroSeen() async {}
}

class _NoWishes implements WishStore {
  @override
  Future<List<Wish>> load() async => const [];
  @override
  Future<void> save(List<Wish> wishes) async {}
}

class _NoBest implements DiyaGameStore {
  @override
  Future<Duration?> bestTime(DiyaDifficulty difficulty) async => null;
  @override
  Future<void> saveBestTime(DiyaDifficulty d, Duration t) async {}
}

class _Audio implements DeepavaliAudio {
  final List<String> calls = [];
  @override
  Future<AudioCatalog> catalog() async => const AudioCatalog(
    effects: {Sfx.tap: 'assets/deepavali/audio/tap.mp3'},
    music: 'assets/deepavali/audio/music.mp3',
  );
  @override
  Future<void> playEffect(Sfx sfx) async => calls.add('effect:${sfx.name}');
  @override
  Future<void> playMusic() async => calls.add('music:play');
  @override
  Future<void> pauseMusic() async => calls.add('music:pause');
  @override
  Future<void> dispose() async {}
}

class _Clock {
  Duration now = Duration.zero;
  Duration call() => now;
}

void main() {
  reduceMotionForAllTests();

  group('licence audit', () {
    test('every audio file is listed in the folder\'s CREDITS.md', () {
      final files = _filesIn('assets/deepavali/audio')
        ..removeWhere((f) => f.endsWith('.md'));
      expect(files, isNotEmpty);
      final md = File('assets/deepavali/audio/CREDITS.md').readAsStringSync();
      for (final f in files) {
        expect(md, contains(f), reason: '$f has no credit in CREDITS.md');
      }
    });

    test('every photo in the folder belongs to a destination, and back', () {
      final files = _filesIn('assets/deepavali/images/destinations');
      final used = [
        for (final d in destinations) d.photo.asset.split('/').last,
      ];
      expect(files.toSet(), used.toSet(), reason: 'no orphan or missing photo');
    });

    test('the typeface ships with its licence', () {
      final fonts = _filesIn('assets/google_fonts');
      expect(fonts, contains('OFL.txt'));
      expect(
        File('assets/google_fonts/OFL.txt').readAsStringSync(),
        contains('SIL Open Font License'),
      );
    });

    test('every bundled folder is declared in pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final dir in [
        'assets/deepavali/images/destinations/',
        'assets/deepavali/audio/',
        'assets/google_fonts/',
      ]) {
        expect(pubspec, contains(dir), reason: dir);
      }
    });
  });

  group('offline and no tracking', () {
    test('the tab\'s code makes no network requests', () {
      final banned = RegExp(
        r"package:http/|HttpClient|Image\.network|NetworkImage|"
        r"WebSocket|package:dio|launchUrl|url_launcher",
      );
      final hits = <String>[];
      for (final f
          in Directory('lib/features/deepavali')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        // The leaderboard card shows player avatars (ADR-012); the scores
        // themselves go through the Supabase client, which this does not ban.
        if (f.path.endsWith('widgets/scoreboard_card.dart')) continue;
        if (banned.hasMatch(f.readAsStringSync())) hits.add(f.path);
      }
      expect(hits, isEmpty);
    });

    test('the typeface is bundled and never fetched at runtime', () {
      DiwaliTheme.data;
      expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        expect(File('assets/google_fonts/Poppins-$w.ttf').existsSync(), isTrue);
      }
    });

    test('no analytics or crash-reporting package is used by the tab', () {
      final src = [
        for (final f in Directory(
          'lib/features/deepavali',
        ).listSync(recursive: true).whereType<File>())
          f.readAsStringSync(),
      ].join();
      expect(src, isNot(contains('firebase')));
      expect(src, isNot(contains('analytics')));
    });
  });

  group('colour contrast (4.5:1 for text)', () {
    const surfaces = [
      DiwaliPalette.night,
      DiwaliPalette.plum,
      DiwaliPalette.surface,
      DiwaliPalette.surfaceHigh,
    ];

    test('body and muted text on every dark surface', () {
      for (final bg in surfaces) {
        expect(_contrast(DiwaliPalette.cream, bg), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(DiwaliPalette.creamMuted, bg),
          greaterThanOrEqualTo(4.5),
          reason: 'muted text on $bg',
        );
      }
    });

    test('headings and links in gold and saffron', () {
      for (final bg in surfaces) {
        expect(_contrast(DiwaliPalette.gold, bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(DiwaliPalette.saffron, bg), greaterThanOrEqualTo(4.5));
      }
    });

    test('feedback colours on the card surface', () {
      for (final c in [DiwaliPalette.success, DiwaliPalette.error]) {
        expect(_contrast(c, DiwaliPalette.surface), greaterThanOrEqualTo(4.5));
      }
    });

    test('dark text on the gold-to-saffron button', () {
      for (final c in [DiwaliPalette.gold, DiwaliPalette.saffron]) {
        expect(_contrast(DiwaliPalette.night, c), greaterThanOrEqualTo(4.5));
      }
    });
  });

  group('switching tabs', () {
    late _Audio audio;
    late _Clock clock;

    Widget app({required int tab, Widget? deepavali}) => ProviderScope(
      overrides: [
        deepavaliAudioProvider.overrideWithValue(audio),
        diyaGameClockProvider.overrideWithValue(clock.call),
        diyaGameStoreProvider.overrideWithValue(_NoBest()),
        diyaGameSeedProvider.overrideWithValue(() => 5),
        deepavaliStoreProvider.overrideWithValue(_Intro()),
        wishStoreProvider.overrideWithValue(_NoWishes()),
      ],
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          disableAnimations: true,
        ),
        child: MaterialApp(
          theme: DiwaliTheme.data,
          // Mirrors HomePage: tabs stay mounted in an IndexedStack and the
          // hidden ones have their tickers switched off.
          home: Scaffold(
            body: IndexedStack(
              index: tab,
              children: [
                const SizedBox(),
                TickerMode(
                  enabled: tab == 1,
                  child: DiwaliMotionScope(
                    child: DeepavaliMusic(
                      child:
                          deepavali ??
                          const SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: DiyaGameSection(),
                          ),
                    ),
                  ),
                ),
                const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );

    setUp(() {
      audio = _Audio();
      clock = _Clock();
    });

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(Scaffold)));

    testWidgets('a running game pauses when you leave and waits for Resume', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(tab: 1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pump();
      clock.now = const Duration(seconds: 3);
      await tester.pump(const Duration(seconds: 3));
      final c = containerOf(tester);
      expect(c.read(diyaGameProvider).phase, DiyaGamePhase.playing);
      final elapsed = c.read(diyaGameProvider).elapsed;
      expect(elapsed, greaterThan(Duration.zero));

      // Leave for another tab. Time passes while away.
      await tester.pumpWidget(app(tab: 0));
      await tester.pump();
      await tester.pump();
      clock.now = const Duration(seconds: 60);
      await tester.pump(const Duration(seconds: 60));
      expect(c.read(diyaGameProvider).phase, DiyaGamePhase.paused);
      expect(
        c.read(diyaGameProvider).elapsed,
        elapsed,
        reason: 'no time is lost to the clock while away',
      );

      // Back again: still paused, nothing was lost, and it ends at the limit
      // only after Resume.
      await tester.pumpWidget(app(tab: 1));
      await tester.pumpAndSettle();
      expect(c.read(diyaGameProvider).phase, DiyaGamePhase.paused);
      expect(find.text('Paused'), findsOneWidget);
      await tester.tap(find.text('Resume'));
      await tester.pump();
      expect(c.read(diyaGameProvider).phase, DiyaGamePhase.playing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the song follows the tab: plays, pauses away, plays back', (
      tester,
    ) async {
      await tester.pumpWidget(app(tab: 1, deepavali: const SizedBox()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(tab: 2, deepavali: const SizedBox()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(tab: 0, deepavali: const SizedBox()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(tab: 1, deepavali: const SizedBox()));
      await tester.pumpAndSettle();
      expect(audio.calls, ['music:play', 'music:pause', 'music:play']);
    });

    testWidgets('your work is kept while you are on another tab', (
      tester,
    ) async {
      await tester.pumpWidget(app(tab: 1, deepavali: const SizedBox()));
      final c = containerOf(tester);
      c.read(rangoliProvider.notifier).tapCell(5);
      c.read(greetingProvider.notifier)
        ..setMessage('See you soon')
        ..setFrom('Meera');
      final painted = c.read(rangoliProvider).paintedCount;
      expect(painted, greaterThan(0));

      await tester.pumpWidget(app(tab: 0, deepavali: const SizedBox()));
      await tester.pumpWidget(app(tab: 2, deepavali: const SizedBox()));
      await tester.pumpWidget(app(tab: 1, deepavali: const SizedBox()));
      expect(c.read(rangoliProvider).paintedCount, painted);
      expect(c.read(greetingProvider).message, 'See you soon');
      expect(c.read(greetingProvider).from, 'Meera');
    });

    testWidgets('the whole page scrolls top to bottom without a single error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deepavaliAudioProvider.overrideWithValue(audio),
            deepavaliStoreProvider.overrideWithValue(_Intro()),
            wishStoreProvider.overrideWithValue(_NoWishes()),
          ],
          child: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 568),
              disableAnimations: true,
              textScaler: TextScaler.linear(2),
            ),
            child: MaterialApp(home: DeepavaliPage()),
          ),
        ),
      );
      await tester.pump();
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      var guard = 0;
      while (scroll.position.pixels < scroll.position.maxScrollExtent &&
          guard++ < 400) {
        scroll.position.jumpTo(
          (scroll.position.pixels + 300).clamp(
            0,
            scroll.position.maxScrollExtent,
          ),
        );
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Open photo booth'), findsOneWidget);
    });
  });

  group('performance guards', () {
    test('litMask changes exactly when the set of lit diyas changes', () {
      var g = const DiyaGame(difficulty: DiyaDifficulty.gentle).start();
      expect(g.litMask, 0);
      g = g.tap(0);
      expect(g.litMask, 1);
      g = g.tap(3).tap(11);
      expect(g.litMask, 1 | (1 << 3) | (1 << 11));
      final before = g.litMask;
      expect(
        g.tap(3).litMask,
        before,
        reason: 'a repeated tap changes nothing',
      );
      expect(
        g.tick(const Duration(seconds: 1)).litMask,
        before,
        reason: 'time passing alone does not change the board',
      );
    });

    testWidgets('every section sits in its own repaint boundary', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deepavaliAudioProvider.overrideWithValue(_Audio()),
            deepavaliStoreProvider.overrideWithValue(_Intro()),
            wishStoreProvider.overrideWithValue(_NoWishes()),
          ],
          child: const MediaQuery(
            data: MediaQueryData(size: Size(360, 800), disableAnimations: true),
            child: MaterialApp(home: DeepavaliPage()),
          ),
        ),
      );
      await tester.pump();
      // The page is one long column: a repaint inside one section (a ticking
      // clock, a game) must not re-record all the others.
      for (final type in [
        HeroSection,
        CountdownSection,
        ExplorerSection,
        DestinationsSection,
        DiyaGameSection,
        QuizSection,
        RangoliSection,
        GreetingSection,
        MoreSection,
      ]) {
        final boundaries = find.ancestor(
          of: find.byType(type, skipOffstage: false),
          matching: find.byType(RepaintBoundary),
        );
        expect(
          boundaries,
          findsWidgets,
          reason: '$type has no repaint boundary',
        );
      }
    });
  });
}
