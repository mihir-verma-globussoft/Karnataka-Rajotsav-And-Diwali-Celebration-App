import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/deepavali_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/wish.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/wish_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/deepavali_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/hero_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/fireworks.dart';

import '../../helpers.dart';

/// Counts what a painter draws.
class _CountingCanvas implements ui.Canvas {
  final Map<String, int> calls = {};
  int get draws => calls.entries
      .where((e) => e.key.startsWith('draw'))
      .fold(0, (a, e) => a + e.value);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString().replaceAll(
      RegExp(r'Symbol\("|"\)'),
      '',
    );
    calls[name] = (calls[name] ?? 0) + 1;
    return null;
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

int _draw({
  required double fade,
  ValueListenable<double>? clock,
  Size size = const Size(360, 600),
}) {
  final canvas = _CountingCanvas();
  FireworksPainter(fade: fade, clock: clock).paint(canvas, size);
  return canvas.draws;
}

void main() {
  reduceMotionForAllTests();

  group('FireworksPainter', () {
    test('draws nothing before the intro has faded it in', () {
      expect(_draw(fade: 0), 0);
    });

    test('draws nothing on an empty canvas', () {
      expect(_draw(fade: 1, size: Size.zero), 0);
    });

    test('without a clock it shows a still celebration', () {
      final n = _draw(fade: 1);
      expect(n, greaterThan(60), reason: 'bursts and fountains are visible');
    });

    test('with a clock it draws something at every moment of the cycle', () {
      for (var i = 0; i < 200; i++) {
        final clock = ValueNotifier<double>(i * 0.1);
        expect(
          _draw(fade: 1, clock: clock),
          greaterThan(0),
          reason: 't=${i * 0.1}',
        );
      }
    });

    test('never draws more than the stated upper bound', () {
      for (var i = 0; i < 400; i++) {
        final clock = ValueNotifier<double>(i * 0.05);
        expect(
          _draw(fade: 1, clock: clock),
          lessThanOrEqualTo(FireworksPainter.maxPrimitives),
          reason: 't=${i * 0.05}',
        );
      }
      expect(FireworksPainter.maxPrimitives, lessThanOrEqualTo(260));
    });

    test('is repeatable: the same moment draws the same thing', () {
      final a = _draw(fade: 1, clock: ValueNotifier<double>(7.3));
      final b = _draw(fade: 1, clock: ValueNotifier<double>(7.3));
      expect(a, b);
    });

    test('fading in draws the same shapes, only fainter', () {
      expect(_draw(fade: 0.4), _draw(fade: 1));
    });

    test('repaints when the fade or the clock changes, not otherwise', () {
      final clock = ValueNotifier<double>(0);
      final base = FireworksPainter(fade: 1, clock: clock);
      expect(
        base.shouldRepaint(FireworksPainter(fade: 1, clock: clock)),
        isFalse,
      );
      expect(
        base.shouldRepaint(FireworksPainter(fade: 0.5, clock: clock)),
        isTrue,
      );
      expect(base.shouldRepaint(FireworksPainter(fade: 1)), isTrue);
    });
  });

  group('FireworksLayer', () {
    testWidgets(
      'is decorative: hidden from screen readers, own repaint layer',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          const MaterialApp(
            home: SizedBox(
              width: 360,
              height: 600,
              child: FireworksLayer(fade: 1),
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(FireworksLayer),
            matching: find.byType(RepaintBoundary),
          ),
          findsWidgets,
        );
        expect(
          find.bySemanticsLabel(RegExp('firework', caseSensitive: false)),
          findsNothing,
        );
        handle.dispose();
      },
    );

    testWidgets('repaints on every tick of the clock', (tester) async {
      final clock = ValueNotifier<double>(0);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 600,
            child: FireworksLayer(fade: 1, clock: clock),
          ),
        ),
      );
      clock.value = 1.5;
      await tester.pump();
      clock.value = 3;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('in the hero', () {
    Widget page({required bool reduce}) => ProviderScope(
      overrides: [
        deepavaliStoreProvider.overrideWithValue(_Intro()),
        wishStoreProvider.overrideWithValue(_NoWishes()),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 800),
          disableAnimations: reduce,
        ),
        child: const MaterialApp(home: DeepavaliPage()),
      ),
    );

    testWidgets('the hero shows fireworks', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(page(reduce: false));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.descendant(
          of: find.byType(HeroSection),
          matching: find.byType(FireworksLayer),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with reduced motion they are still and nothing animates', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(page(reduce: true));
      await tester.pump(const Duration(milliseconds: 500));
      final layer = tester.widget<FireworksLayer>(find.byType(FireworksLayer));
      expect(layer.clock, isNull, reason: 'a still frame, no ticking');
      expect(layer.fade, 1);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets(
      'and fireworks do not spoil the layout at 320x568 with 2x text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
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
        expect(tester.takeException(), isNull);
      },
    );
  });
}
