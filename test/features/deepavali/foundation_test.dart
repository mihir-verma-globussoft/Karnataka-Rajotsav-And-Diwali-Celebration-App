import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/deepavali_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/deepavali_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/diwali_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/settings_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_palette.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/diwali_button.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/diwali_motion.dart';

final DateTime _now = DateTime.utc(2026, 11, 3, 6);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

class _FakeStore implements DeepavaliStore {
  _FakeStore({this.seen = false});
  bool seen;
  @override
  Future<bool> introSeen() async => seen;
  @override
  Future<void> markIntroSeen() async => seen = true;
}

Widget _host({
  Size size = const Size(360, 800),
  double textScale = 1,
  bool disableAnimations = false,
  Widget child = const DeepavaliPage(),
  DeepavaliStore? store,
  DateTime? now,
}) => ProviderScope(
  overrides: [
    deepavaliStoreProvider.overrideWithValue(store ?? _FakeStore(seen: true)),
    deepavaliNowProvider.overrideWithValue(() => now ?? _now),
  ],
  child: MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
    ),
    child: MaterialApp(home: child),
  ),
);

void main() {
  group('palette contrast', () {
    test('body text on backgrounds is at least 7:1', () {
      for (final bg in [
        DiwaliPalette.night,
        DiwaliPalette.surface,
        DiwaliPalette.surfaceHigh,
      ]) {
        expect(_contrast(DiwaliPalette.cream, bg), greaterThanOrEqualTo(7));
      }
    });
    test('muted text and gold on surfaces are at least 4.5:1', () {
      expect(
        _contrast(DiwaliPalette.creamMuted, DiwaliPalette.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(DiwaliPalette.gold, DiwaliPalette.night),
        greaterThanOrEqualTo(4.5),
      );
    });
    test('night text on the CTA gradient is at least 7:1', () {
      for (final c in [DiwaliPalette.gold, DiwaliPalette.saffron]) {
        expect(_contrast(DiwaliPalette.night, c), greaterThanOrEqualTo(7));
      }
    });
  });

  group('layout', () {
    for (final (name, size, scale) in [
      ('320dp', const Size(320, 640), 1.0),
      ('360dp 2x text', const Size(360, 800), 2.0),
      ('600dp', const Size(600, 900), 1.0),
      ('840dp', const Size(840, 900), 1.0),
      ('landscape', const Size(800, 360), 1.0),
    ]) {
      testWidgets('scrolls through every section at $name', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_host(size: size, textScale: scale));
        for (final s in DiwaliSection.values) {
          await tester.scrollUntilVisible(
            find.text(s.title),
            300,
            scrollable: find.byType(Scrollable).first,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('last section clears the floating bar area', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host());
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    // Let the last section finish fading in before measuring.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final bottom = tester.getBottomLeft(find.text('Open photo booth')).dy;
    expect(800 - bottom, greaterThanOrEqualTo(96));
  });

  group('motion scope', () {
    Widget probe(void Function(DiwaliMotion) onBuild) => Builder(
      builder: (context) {
        onBuild(DiwaliMotion.of(context));
        return const SizedBox();
      },
    );

    testWidgets('animates by default', (tester) async {
      late DiwaliMotion m;
      await tester.pumpWidget(
        _host(child: DiwaliMotionScope(child: probe((v) => m = v))),
      );
      expect(m.animate, isTrue);
      expect(m.reduceMotion, isFalse);
    });

    testWidgets('OS reduce-motion disables animation', (tester) async {
      late DiwaliMotion m;
      await tester.pumpWidget(
        _host(
          disableAnimations: true,
          child: DiwaliMotionScope(child: probe((v) => m = v)),
        ),
      );
      expect(m.animate, isFalse);
      expect(m.reduceMotion, isTrue);
    });

    testWidgets('turning reduce-motion on and off switches animation live', (
      tester,
    ) async {
      late DiwaliMotion m;
      Widget app({required bool reduce}) => _host(
        disableAnimations: reduce,
        child: DiwaliMotionScope(child: probe((v) => m = v)),
      );
      await tester.pumpWidget(app(reduce: false));
      expect(m.animate, isTrue);
      await tester.pumpWidget(app(reduce: true));
      expect(m.animate, isFalse);
      await tester.pumpWidget(app(reduce: false));
      expect(m.animate, isTrue);
    });

    // Spike result: IndexedStack alone does NOT disable tickers, so the home
    // shell wraps each tab in TickerMode (approved one-line shell change).
    testWidgets('animation pauses when the tab is hidden in an IndexedStack', (
      tester,
    ) async {
      late DiwaliMotion m;
      Widget stack(int index) => _host(
        child: IndexedStack(
          index: index,
          children: [
            // Mirrors HomePage: each tab is wrapped in TickerMode.
            TickerMode(
              enabled: index == 0,
              child: DiwaliMotionScope(child: probe((v) => m = v)),
            ),
            const SizedBox(),
          ],
        ),
      );
      await tester.pumpWidget(stack(0));
      expect(m.animate, isTrue);
      await tester.pumpWidget(stack(1));
      expect(m.animate, isFalse);
      await tester.pumpWidget(stack(0));
      expect(m.animate, isTrue);
    });
  });

  testWidgets('settings default: the song is on', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(diwaliSettingsProvider).music, isTrue);
  });

  testWidgets('buttons meet the 48dp touch target and respect disabled', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        child: Scaffold(
          body: Column(
            children: [
              DiwaliButton(label: 'Go', onPressed: () => taps++),
              const DiwaliButton(label: 'Off', onPressed: null),
              DiwaliButton(
                label: 'Two',
                kind: DiwaliButtonKind.secondary,
                onPressed: () {},
              ),
              DiwaliButton(
                label: 'Three',
                kind: DiwaliButtonKind.tertiary,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.widgetWithText(InkWell, 'Go')).height,
      greaterThanOrEqualTo(48),
    );
    for (final t in [OutlinedButton, TextButton]) {
      expect(tester.getSize(find.byType(t)).height, greaterThanOrEqualTo(48));
    }
    await tester.tap(find.text('Go'));
    await tester.tap(find.text('Off'), warnIfMissed: false);
    expect(taps, 1);
  });
}
