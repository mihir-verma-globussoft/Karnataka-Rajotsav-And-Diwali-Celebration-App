import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/deepavali_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/settings_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/sound.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/wish.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/wish_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/deepavali_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/feedback.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/settings_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_theme.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/deepavali_music.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/diwali_motion.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/section_reveal.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/utility_bar.dart';

import '../../helpers.dart';

class _Audio implements DeepavaliAudio {
  _Audio(this._catalog);
  final AudioCatalog _catalog;
  final List<String> calls = [];
  int catalogReads = 0;

  @override
  Future<AudioCatalog> catalog() async {
    catalogReads++;
    return _catalog;
  }

  @override
  Future<void> playEffect(Sfx sfx) async => calls.add('effect:${sfx.name}');
  @override
  Future<void> playMusic() async => calls.add('music:play');
  @override
  Future<void> pauseMusic() async => calls.add('music:pause');
  @override
  Future<void> dispose() async {}
}

class _SettingsStore implements DeepavaliSettingsStore {
  _SettingsStore([this.music]);
  bool? music;
  int saves = 0;
  @override
  Future<bool?> loadMusic() async => music;
  @override
  Future<void> saveMusic(bool on) async {
    saves++;
    music = on;
  }
}

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

AudioCatalog _full() => const AudioCatalog(
  effects: {
    Sfx.diyaLight: 'assets/deepavali/audio/diya_light.mp3',
    Sfx.tap: 'assets/deepavali/audio/tap.mp3',
  },
  music: 'assets/deepavali/audio/music.mp3',
);

/// Records vibration calls made through the platform channel.
List<String> _recordHaptics() {
  final calls = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add('${call.arguments}');
        }
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}

void main() {
  reduceMotionForAllTests();

  group('AudioCatalog', () {
    const base = 'assets/deepavali/audio';

    test('nothing bundled means nothing to play', () {
      final c = AudioCatalog.fromAssets([
        '$base/README.md',
        'assets/team/photo.jpg',
      ]);
      expect(c.isEmpty, isTrue);
      expect(c.hasMusic, isFalse);
      expect(c.effects, isEmpty);
    });

    test('finds each file by name, whatever its extension', () {
      final c = AudioCatalog.fromAssets([
        '$base/music.ogg',
        '$base/tap.wav',
        '$base/win.m4a',
        '$base/gust.aac',
        '$base/diya_light.mp3',
      ]);
      expect(c.music, '$base/music.ogg');
      expect(c.effects[Sfx.tap], '$base/tap.wav');
      expect(c.effects[Sfx.win], '$base/win.m4a');
      expect(c.effects[Sfx.gust], '$base/gust.aac');
      expect(c.effects[Sfx.diyaLight], '$base/diya_light.mp3');
      expect(c.has(Sfx.correct), isFalse);
      expect(c.isEmpty, isFalse);
    });

    test('mp3 is preferred when several formats exist', () {
      final c = AudioCatalog.fromAssets(['$base/tap.wav', '$base/tap.mp3']);
      expect(c.effects[Sfx.tap], '$base/tap.mp3');
    });

    test('files outside the audio folder or with other names are ignored', () {
      final c = AudioCatalog.fromAssets([
        'assets/audio/tap.mp3',
        '$base/other.mp3',
        '$base/tap.txt',
        '$base/sub/tap.mp3',
      ]);
      expect(c.isEmpty, isTrue);
    });

    test('a lone song still counts', () {
      final c = AudioCatalog.fromAssets(['$base/music.mp3']);
      expect(c.hasMusic, isTrue);
      expect(c.effects, isEmpty);
      expect(c.isEmpty, isFalse);
    });

    test('every effect has a distinct file name', () {
      expect(
        Sfx.values.map((s) => s.fileStem).toSet().length,
        Sfx.values.length,
      );
      expect(Sfx.values.map((s) => s.fileStem), isNot(contains(musicFileStem)));
    });
  });

  group('settings', () {
    ProviderContainer make(_SettingsStore store) {
      final c = ProviderContainer(
        overrides: [deepavaliSettingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('the song is on for a new install', () {
      final c = make(_SettingsStore());
      expect(c.read(diwaliSettingsProvider).music, isTrue);
    });

    test('a remembered mute is restored', () async {
      final c = make(_SettingsStore(false));
      c.read(diwaliSettingsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(diwaliSettingsProvider).music, isFalse);
    });

    test('a remembered "on" is restored', () async {
      final c = make(_SettingsStore(true));
      c.read(diwaliSettingsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(diwaliSettingsProvider).music, isTrue);
    });

    test(
      'muting and unmuting the song take effect at once and are saved',
      () async {
        final store = _SettingsStore();
        final c = make(store);
        final n = c.read(diwaliSettingsProvider.notifier);
        await Future<void>.delayed(Duration.zero);
        n.setMusic(enabled: false);
        expect(c.read(diwaliSettingsProvider).music, isFalse);
        expect(store.music, isFalse);
        n.setMusic(enabled: true);
        expect(c.read(diwaliSettingsProvider).music, isTrue);
        expect(store.music, isTrue);
        expect(store.saves, 2);
      },
    );
  });

  group('feedback', () {
    ProviderContainer make({required _Audio audio}) {
      final c = ProviderContainer(
        overrides: [
          deepavaliAudioProvider.overrideWithValue(audio),
          deepavaliSettingsStoreProvider.overrideWithValue(_SettingsStore()),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    testWidgets('haptics are felt when on, each with its own strength', (
      tester,
    ) async {
      final calls = _recordHaptics();
      final c = make(audio: _Audio(_full()));
      final f = c.read(diwaliFeedbackProvider);
      f.haptic(Haptic.selection);
      f.haptic(Haptic.light);
      f.haptic(Haptic.medium);
      f.haptic(Haptic.heavy);
      await tester.pump();
      expect(calls, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ]);
    });

    testWidgets('vibration is always on, even when the song is muted', (
      tester,
    ) async {
      final calls = _recordHaptics();
      final c = make(audio: _Audio(_full()));
      c.read(diwaliSettingsProvider.notifier).setMusic(enabled: false);
      c.read(diwaliFeedbackProvider).haptic(Haptic.light);
      await tester.pump();
      expect(calls, ['HapticFeedbackType.lightImpact']);
    });

    testWidgets('sound effects play', (tester) async {
      _recordHaptics();
      final audio = _Audio(_full());
      final c = make(audio: audio);
      c.read(diwaliFeedbackProvider).sfx(Sfx.diyaLight);
      c.read(diwaliFeedbackProvider).both(Haptic.light, Sfx.tap);
      await tester.pump();
      expect(audio.calls, ['effect:diyaLight', 'effect:tap']);
    });

    testWidgets('muting the song does not silence the sound effects', (
      tester,
    ) async {
      final calls = _recordHaptics();
      final audio = _Audio(_full());
      final c = make(audio: audio);
      c.read(diwaliSettingsProvider.notifier).setMusic(enabled: false);
      final f = c.read(diwaliFeedbackProvider);
      f.sfx(Sfx.win);
      f.both(Haptic.medium, Sfx.correct);
      await tester.pump();
      expect(audio.calls, ['effect:win', 'effect:correct']);
      expect(calls, ['HapticFeedbackType.mediumImpact']);
    });

    testWidgets('an effect with no file stays silent without error', (
      tester,
    ) async {
      _recordHaptics();
      final audio = _Audio(const AudioCatalog());
      final c = make(audio: audio);
      c.read(diwaliFeedbackProvider).sfx(Sfx.gust);
      await tester.pump();
      // The audio layer is asked; it is the layer that skips missing files.
      expect(audio.calls, ['effect:gust']);
    });
  });

  group('widgets', () {
    late _Audio audio;
    late _SettingsStore settings;

    Widget host(Widget child, {double width = 360}) => ProviderScope(
      overrides: [
        deepavaliAudioProvider.overrideWithValue(audio),
        deepavaliSettingsStoreProvider.overrideWithValue(settings),
        deepavaliStoreProvider.overrideWithValue(_Intro()),
        wishStoreProvider.overrideWithValue(_NoWishes()),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: Size(width, 800), disableAnimations: true),
        child: MaterialApp(
          theme: DiwaliTheme.data,
          home: Scaffold(body: child),
        ),
      ),
    );

    setUp(() {
      audio = _Audio(_full());
      settings = _SettingsStore();
    });

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(Scaffold)));

    group('music', () {
      testWidgets('plays while the tab is on screen and sound is on', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            const DiwaliMotionScope(child: DeepavaliMusic(child: SizedBox())),
          ),
        );
        await tester.pumpAndSettle();
        expect(audio.calls, ['music:play']);
      });

      testWidgets('stops when the tab is hidden and resumes on return', (
        tester,
      ) async {
        Widget app({required bool visible}) => host(
          TickerMode(
            enabled: visible,
            child: const DiwaliMotionScope(
              child: DeepavaliMusic(child: SizedBox()),
            ),
          ),
        );
        await tester.pumpWidget(app(visible: true));
        await tester.pumpAndSettle();
        await tester.pumpWidget(app(visible: false));
        await tester.pumpAndSettle();
        await tester.pumpWidget(app(visible: true));
        await tester.pumpAndSettle();
        expect(audio.calls, ['music:play', 'music:pause', 'music:play']);
      });

      testWidgets('muting pauses it and unmuting plays it again', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            const DiwaliMotionScope(child: DeepavaliMusic(child: SizedBox())),
          ),
        );
        await tester.pumpAndSettle();
        final n = containerOf(tester).read(diwaliSettingsProvider.notifier);
        n.setMusic(enabled: false);
        await tester.pumpAndSettle();
        n.setMusic(enabled: true);
        await tester.pumpAndSettle();
        expect(audio.calls, ['music:play', 'music:pause', 'music:play']);
      });

      testWidgets('without a song file the audio is never started', (
        tester,
      ) async {
        audio = _Audio(const AudioCatalog());
        await tester.pumpWidget(
          host(
            const DiwaliMotionScope(child: DeepavaliMusic(child: SizedBox())),
          ),
        );
        await tester.pumpAndSettle();
        expect(audio.calls, isEmpty);
      });

      testWidgets('a person who muted earlier never hears it start', (
        tester,
      ) async {
        settings = _SettingsStore(false);
        await tester.pumpWidget(
          host(
            const DiwaliMotionScope(child: DeepavaliMusic(child: SizedBox())),
          ),
        );
        await tester.pumpAndSettle();
        expect(audio.calls, isNot(contains('music:play')));
      });

      testWidgets('leaving the page pauses the song', (tester) async {
        await tester.pumpWidget(
          host(
            const DiwaliMotionScope(child: DeepavaliMusic(child: SizedBox())),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pumpWidget(host(const SizedBox()));
        await tester.pumpAndSettle();
        expect(audio.calls, ['music:play', 'music:pause']);
      });
    });

    group('mute button', () {
      testWidgets('shows a mute button when a song is bundled', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(const MuteButton()));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Mute music'), findsOneWidget);
        expect(find.bySemanticsLabel('Settings'), findsNothing);
        handle.dispose();
      });

      testWidgets('with no song file there is no button at all', (
        tester,
      ) async {
        audio = _Audio(const AudioCatalog());
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(const MuteButton()));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Mute music'), findsNothing);
        expect(find.bySemanticsLabel('Turn music on'), findsNothing);
        handle.dispose();
      });

      testWidgets('sound effects without a song give no button', (
        tester,
      ) async {
        audio = _Audio(
          const AudioCatalog(
            effects: {Sfx.tap: 'assets/deepavali/audio/tap.mp3'},
          ),
        );
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(const MuteButton()));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Mute music'), findsNothing);
        handle.dispose();
      });

      testWidgets('tapping toggles mute and remembers it', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(const MuteButton()));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Mute music'));
        await tester.pump();
        expect(find.bySemanticsLabel('Turn music on'), findsOneWidget);
        expect(settings.music, isFalse);
        await tester.tap(find.bySemanticsLabel('Turn music on'));
        await tester.pump();
        expect(find.bySemanticsLabel('Mute music'), findsOneWidget);
        expect(settings.music, isTrue);
        handle.dispose();
      });

      testWidgets('the button is at least 48dp', (tester) async {
        await tester.pumpWidget(host(const Align(child: MuteButton())));
        await tester.pumpAndSettle();
        final size = tester.getSize(
          find
              .ancestor(
                of: find.byIcon(Icons.volume_up),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      });

      testWidgets('muting from the button stops the song, unmuting restarts', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          host(
            const DiwaliMotionScope(
              child: DeepavaliMusic(child: Center(child: MuteButton())),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(audio.calls, ['music:play']);
        await tester.tap(find.bySemanticsLabel('Mute music'));
        await tester.pumpAndSettle();
        expect(audio.calls, ['music:play', 'music:pause']);
        await tester.tap(find.bySemanticsLabel('Turn music on'));
        await tester.pumpAndSettle();
        expect(audio.calls, ['music:play', 'music:pause', 'music:play']);
        handle.dispose();
      });
    });

    group('section reveal', () {
      Widget scroller({required bool reduce}) => ProviderScope(
        overrides: [
          deepavaliAudioProvider.overrideWithValue(audio),
          deepavaliSettingsStoreProvider.overrideWithValue(settings),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 800),
            disableAnimations: reduce,
          ),
          child: MaterialApp(
            theme: DiwaliTheme.data,
            home: const Scaffold(
              body: DiwaliMotionScope(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 1600),
                      SectionReveal(child: Text('Far below')),
                      SizedBox(height: 800),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      double opacity(WidgetTester tester) =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

      testWidgets('stays hidden until it scrolls into view, then appears', (
        tester,
      ) async {
        await tester.pumpWidget(scroller(reduce: false));
        await tester.pump();
        expect(opacity(tester), 0);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -1200),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(opacity(tester), 1);
      });

      testWidgets('once shown it stays shown when scrolled away', (
        tester,
      ) async {
        await tester.pumpWidget(scroller(reduce: false));
        await tester.pump();
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -1200),
        );
        await tester.pump();
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 1200),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(opacity(tester), 1);
      });

      testWidgets('with animations off nothing is ever hidden', (tester) async {
        await tester.pumpWidget(scroller(reduce: true));
        await tester.pump();
        expect(find.byType(AnimatedOpacity), findsNothing);
        expect(find.text('Far below'), findsOneWidget);
      });

      testWidgets('the content is in the tree even while hidden', (
        tester,
      ) async {
        await tester.pumpWidget(scroller(reduce: false));
        await tester.pump();
        expect(find.text('Far below', skipOffstage: false), findsOneWidget);
      });
    });

    group('whole page', () {
      Widget page({required bool visible, required bool reduce}) =>
          ProviderScope(
            overrides: [
              deepavaliAudioProvider.overrideWithValue(audio),
              deepavaliSettingsStoreProvider.overrideWithValue(settings),
              deepavaliStoreProvider.overrideWithValue(_Intro()),
              wishStoreProvider.overrideWithValue(_NoWishes()),
            ],
            child: MediaQuery(
              data: MediaQueryData(
                size: const Size(360, 800),
                disableAnimations: reduce,
              ),
              child: MaterialApp(
                home: TickerMode(
                  enabled: visible,
                  child: const DeepavaliPage(),
                ),
              ),
            ),
          );

      testWidgets('a hidden tab runs no animation tickers', (tester) async {
        await tester.pumpWidget(page(visible: false, reduce: false));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.binding.transientCallbackCount, 0);
      });

      testWidgets('a visible tab animates', (tester) async {
        await tester.pumpWidget(page(visible: true, reduce: false));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.binding.transientCallbackCount, greaterThan(0));
        // Leave cleanly.
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('with animations off no ticker runs even when visible', (
        tester,
      ) async {
        await tester.pumpWidget(page(visible: true, reduce: true));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.binding.transientCallbackCount, 0);
      });

      testWidgets('the page has a mute-music button and no settings button', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(page(visible: true, reduce: true));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Mute music'), findsOneWidget);
        expect(find.bySemanticsLabel('Settings'), findsNothing);
        handle.dispose();
      });
    });
  });
}
