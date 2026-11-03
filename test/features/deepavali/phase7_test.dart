import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/image_sharer.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/rangoli_geometry.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/rangoli_state.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/rangoli_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/rangoli_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_theme.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/rangoli_palette.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/rangoli_canvas.dart';

import '../../helpers.dart';

/// A point at [radius] (0..1 of the canvas radius) and [degrees] clockwise
/// from straight up, on a canvas of side [side].
Offset _at(double radius, double degrees, {double side = 200}) {
  final half = side / 2;
  final a = degrees * math.pi / 180;
  return Offset(
    half + math.sin(a) * radius * half,
    half - math.cos(a) * radius * half,
  );
}

RangoliCell? _hit(double radius, double degrees) {
  final p = _at(radius, degrees);
  return RangoliGeometry.hit(p.dx, p.dy, 200);
}

class _Sharer implements ImageSharer {
  final List<Uint8List> shared = [];
  bool fail = false;
  @override
  Future<void> sharePng(
    Uint8List png, {
    required String fileName,
    String? text,
  }) async {
    if (fail) throw StateError('no share sheet');
    shared.add(png);
  }
}

void main() {
  reduceMotionForAllTests();

  group('RangoliGeometry', () {
    test('sizes are consistent', () {
      expect(RangoliGeometry.cellCount, 33);
      expect(RangoliGeometry.outerRadius.length, RangoliGeometry.rings);
      expect(RangoliGeometry.outerRadius.last, 1.0);
      expect(
        RangoliGeometry.outerRadius,
        orderedEquals([...RangoliGeometry.outerRadius]..sort()),
      );
    });

    test('index and cell round-trip for every cell', () {
      for (var i = 0; i < RangoliGeometry.cellCount; i++) {
        expect(RangoliGeometry.cellOf(i).index, i);
      }
      expect(RangoliGeometry.indexOf(0, 0), 0);
      expect(RangoliGeometry.indexOf(1, 0), 1);
      expect(RangoliGeometry.indexOf(4, 7), 32);
    });

    test('centre and the middle of the first ring', () {
      expect(RangoliGeometry.hit(100, 100, 200), const RangoliCell(0, 0));
      expect(_hit(0.1, 77), const RangoliCell(0, 0));
    });

    test('each ring is found at its middle', () {
      for (var ring = 1; ring < RangoliGeometry.rings; ring++) {
        final mid =
            (RangoliGeometry.innerRadiusOf(ring) +
                RangoliGeometry.outerRadius[ring]) /
            2;
        expect(_hit(mid, 0)!.ring, ring, reason: 'ring $ring');
      }
    });

    test('ring borders: just inside and just outside', () {
      for (var ring = 0; ring < RangoliGeometry.rings - 1; ring++) {
        final edge = RangoliGeometry.outerRadius[ring];
        expect(_hit(edge - 0.01, 10)!.ring, ring);
        expect(_hit(edge + 0.01, 10)!.ring, ring + 1);
      }
    });

    test('sectors run clockwise from a first sector centred on the top', () {
      expect(_hit(0.5, 0)!.sector, 0);
      expect(_hit(0.5, 45)!.sector, 1);
      expect(_hit(0.5, 90)!.sector, 2);
      expect(_hit(0.5, 135)!.sector, 3);
      expect(_hit(0.5, 180)!.sector, 4);
      expect(_hit(0.5, 225)!.sector, 5);
      expect(_hit(0.5, 270)!.sector, 6);
      expect(_hit(0.5, 315)!.sector, 7);
    });

    test('sector borders sit half a sector either side', () {
      expect(_hit(0.5, 22)!.sector, 0);
      expect(_hit(0.5, 23)!.sector, 1);
      expect(_hit(0.5, -22)!.sector, 0);
      expect(_hit(0.5, -23)!.sector, 7);
      expect(_hit(0.5, 337)!.sector, 7);
    });

    test('outside the circle is ignored, the very edge is not', () {
      expect(_hit(1.01, 0), isNull);
      expect(_hit(1.2, 123), isNull);
      expect(RangoliGeometry.hit(0, 0, 200), isNull, reason: 'canvas corner');
      expect(RangoliGeometry.hit(-5, 100, 200), isNull);
      expect(_hit(0.999, 0)!.ring, 4);
    });

    test('a zero-size canvas has no cells', () {
      expect(RangoliGeometry.hit(0, 0, 0), isNull);
    });

    test('symmetry gives quarter-turn copies; the centre has none', () {
      expect(RangoliGeometry.symmetric(0), [0]);
      final copies = RangoliGeometry.symmetric(RangoliGeometry.indexOf(2, 1));
      expect(copies.toSet(), {
        RangoliGeometry.indexOf(2, 1),
        RangoliGeometry.indexOf(2, 3),
        RangoliGeometry.indexOf(2, 5),
        RangoliGeometry.indexOf(2, 7),
      });
      expect(copies.length, 4);
    });
  });

  group('RangoliState', () {
    int cell(int ring, int sector) => RangoliGeometry.indexOf(ring, sector);

    test('starts empty, symmetric, with the first colour', () {
      final s = RangoliState();
      expect(s.isEmpty, isTrue);
      expect(s.paintedCount, 0);
      expect(s.symmetry, isTrue);
      expect(s.colour, 0);
      expect(s.canUndo, isFalse);
    });

    test('the palette matches the colour count', () {
      expect(RangoliPalette.colours.length, rangoliPaletteSize);
      expect(
        RangoliPalette.colours.map((c) => c.name).toSet().length,
        rangoliPaletteSize,
      );
    });

    test('symmetry paints the cell and its three copies', () {
      final s = RangoliState().select(3).tap(cell(2, 1));
      expect(s.paintedCount, 4);
      for (final k in [1, 3, 5, 7]) {
        expect(s.cells[cell(2, k)], 3);
      }
      expect(s.cells[cell(2, 0)], isNull);
    });

    test('without symmetry only one cell is painted', () {
      final s = RangoliState().setSymmetry(on: false).tap(cell(3, 4));
      expect(s.paintedCount, 1);
      expect(s.cells[cell(3, 4)], 0);
    });

    test('the centre is always a single cell', () {
      final s = RangoliState().select(5).tap(0);
      expect(s.paintedCount, 1);
      expect(s.cells[0], 5);
    });

    test('repainting with the same colour changes nothing', () {
      final s = RangoliState().tap(cell(1, 0));
      expect(identical(s.tap(cell(1, 0)), s), isTrue);
      expect(s.undoDepth, 1, reason: 'no extra undo step for a no-op');
    });

    test('the eraser clears a cell and its copies', () {
      final s = RangoliState().tap(cell(2, 0)).select(null).tap(cell(2, 4));
      expect(s.isEmpty, isTrue);
    });

    test('out of range taps are ignored', () {
      final s = RangoliState();
      expect(identical(s.tap(-1), s), isTrue);
      expect(identical(s.tap(RangoliGeometry.cellCount), s), isTrue);
    });

    test('undo steps back exactly, one tap at a time', () {
      var s = RangoliState().setSymmetry(on: false);
      s = s.tap(cell(1, 0)).select(2).tap(cell(1, 1)).tap(cell(1, 2));
      expect(s.paintedCount, 3);
      s = s.undo();
      expect(s.paintedCount, 2);
      expect(s.cells[cell(1, 2)], isNull);
      s = s.undo().undo();
      expect(s.isEmpty, isTrue);
      expect(s.canUndo, isFalse);
      expect(identical(s.undo(), s), isTrue);
    });

    test('undo keeps the selected colour and symmetry', () {
      final s = RangoliState()
          .select(6)
          .setSymmetry(on: false)
          .tap(cell(1, 0))
          .undo();
      expect(s.colour, 6);
      expect(s.symmetry, isFalse);
    });

    test('reset clears everything and can be undone', () {
      final painted = RangoliState().tap(cell(1, 0)).tap(cell(3, 2));
      final cleared = painted.reset();
      expect(cleared.isEmpty, isTrue);
      expect(cleared.undo().paintedCount, painted.paintedCount);
      final empty = RangoliState();
      expect(identical(empty.reset(), empty), isTrue);
    });

    test('undo history is capped', () {
      var s = RangoliState().setSymmetry(on: false);
      for (var i = 0; i < rangoliUndoDepth + 20; i++) {
        s = s.select(i % 2).tap(cell(1, 0)).tap(cell(2, 0));
      }
      expect(s.undoDepth, rangoliUndoDepth);
    });

    test('random is repeatable, symmetrical, and fills every ring', () {
      final a = RangoliState().randomize(42);
      final b = RangoliState().randomize(42);
      expect(a.cells, b.cells);
      expect(a.cells, isNot(RangoliState().randomize(43).cells));
      expect(a.cells.every((c) => c != null), isTrue);
      for (var ring = 1; ring < RangoliGeometry.rings; ring++) {
        final even = a.cells[cell(ring, 0)];
        final odd = a.cells[cell(ring, 1)];
        expect(even, isNot(odd), reason: 'ring $ring alternates colours');
        for (var s = 0; s < RangoliGeometry.sectors; s++) {
          expect(a.cells[cell(ring, s)], s.isEven ? even : odd);
        }
      }
      expect(a.canUndo, isTrue);
      expect(a.undo().isEmpty, isTrue);
    });

    test('states are not changed behind your back', () {
      final s = RangoliState().tap(cell(1, 0));
      expect(() => s.cells[0] = 1, throwsUnsupportedError);
    });
  });

  group('RangoliSection', () {
    late _Sharer sharer;

    Widget app({
      double scale = 1,
      Size size = const Size(360, 800),
      bool withSharer = false,
    }) => ProviderScope(
      overrides: [
        rangoliSeedProvider.overrideWithValue(() => 11),
        imageSharerProvider.overrideWithValue(withSharer ? sharer : null),
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
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: RangoliSection(),
            ),
          ),
        ),
      ),
    );

    setUp(() => sharer = _Sharer());

    void rangoliTest(
      String name,
      Future<void> Function(WidgetTester tester) body, {
      Size size = const Size(360, 800),
    }) => testWidgets(name, (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await body(tester);
    });

    ProviderContainer container(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(RangoliSection)));

    RangoliState state(WidgetTester tester) =>
        container(tester).read(rangoliProvider);

    /// Taps the canvas at a polar position.
    Future<void> tapCanvas(
      WidgetTester tester,
      double radius,
      double degrees,
    ) async {
      final box = tester.getRect(find.byType(RangoliCanvas));
      final side = box.width;
      final p = _at(radius, degrees, side: side);
      await tester.tapAt(box.topLeft + p);
      await tester.pump();
    }

    rangoliTest('starts with an empty canvas and the hint', (tester) async {
      await tester.pumpWidget(app());
      expect(find.text('Rangoli Studio'), findsOneWidget);
      expect(find.text('Tap a shape to begin.'), findsOneWidget);
      expect(
        find.text('Share image'),
        findsNothing,
        reason: 'no sharer available',
      );
      expect(find.text('Undo'), findsOneWidget);
    });

    rangoliTest('tapping the canvas colours the shape and its copies', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tapCanvas(tester, 0.5, 45); // ring 2, sector 1
      final s = state(tester);
      expect(s.paintedCount, 4);
      expect(s.cells[RangoliGeometry.indexOf(2, 1)], 0);
      expect(find.text('4 of 33 shapes coloured.'), findsOneWidget);
    });

    rangoliTest('taps just outside the circle do nothing', (tester) async {
      await tester.pumpWidget(app());
      final box = tester.getRect(find.byType(RangoliCanvas));
      await tester.tapAt(box.topLeft + const Offset(2, 2));
      await tester.pump();
      expect(state(tester).isEmpty, isTrue);
    });

    rangoliTest('choosing a colour and turning symmetry off', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.bySemanticsLabel('Magenta'));
      await tester.pump();
      expect(state(tester).colour, 3);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.text('Each tap colours one shape'), findsOneWidget);
      await tapCanvas(tester, 0.9, 180);
      final s = state(tester);
      expect(s.paintedCount, 1);
      expect(s.cells[RangoliGeometry.indexOf(4, 4)], 3);
    });

    rangoliTest('the eraser removes colour', (tester) async {
      await tester.pumpWidget(app());
      await tapCanvas(tester, 0.5, 0);
      expect(state(tester).paintedCount, 4);
      await tester.tap(find.bySemanticsLabel('Eraser'));
      await tester.pump();
      await tapCanvas(tester, 0.5, 0);
      expect(state(tester).isEmpty, isTrue);
    });

    rangoliTest(
      'Undo goes back; it is disabled when there is nothing to undo',
      (tester) async {
        await tester.pumpWidget(app());
        await tapCanvas(tester, 0.5, 0);
        expect(state(tester).canUndo, isTrue);
        await tester.tap(find.text('Undo'));
        await tester.pump();
        expect(state(tester).isEmpty, isTrue);
        expect(state(tester).canUndo, isFalse);
      },
    );

    rangoliTest('Random makes a full symmetrical design', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Random'));
      await tester.pump();
      expect(state(tester).paintedCount, RangoliGeometry.cellCount);
      expect(find.text('33 of 33 shapes coloured.'), findsOneWidget);
    });

    rangoliTest('Reset asks first, and can be cancelled', (tester) async {
      await tester.pumpWidget(app());
      await tapCanvas(tester, 0.5, 0);
      await tester.ensureVisible(find.text('Reset'));
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('Clear your rangoli?'), findsOneWidget);
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(state(tester).paintedCount, 4);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(state(tester).isEmpty, isTrue);
      expect(find.text('Tap a shape to begin.'), findsOneWidget);
    });

    rangoliTest('Reset is disabled while empty', (tester) async {
      await tester.pumpWidget(app());
      await tester.ensureVisible(find.text('Reset'));
      await tester.tap(find.text('Reset'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Clear your rangoli?'), findsNothing);
    });

    /// Every semantics node under the canvas, in tree order.
    List<SemanticsNode> shapeNodes(WidgetTester tester) {
      final out = <SemanticsNode>[];
      void walk(SemanticsNode n) {
        if (n.label.contains('Double tap to colour')) out.add(n);
        n.visitChildren((SemanticsNode c) {
          walk(c);
          return true;
        });
      }

      walk(tester.getSemantics(find.byType(RangoliCanvas)));
      return out;
    }

    rangoliTest(
      'the canvas has one labelled shape per cell for screen readers',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(app());
        await tester.pump();
        var nodes = shapeNodes(tester);
        expect(nodes.length, RangoliGeometry.cellCount);
        expect(nodes.every((n) => n.label.contains('not coloured')), isTrue);
        expect(nodes.first.label, startsWith('Centre'));

        await tapCanvas(tester, 0.5, 0);
        nodes = shapeNodes(tester);
        expect(
          nodes.where((n) => n.label.startsWith('Ring 2, section 1, Marigold')),
          hasLength(1),
        );
        handle.dispose();
      },
    );

    rangoliTest('a screen reader can colour a shape without touching it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pump();
      final centre = shapeNodes(tester)
          .firstWhere((n) => n.label.startsWith('Centre'));
      // Tests are the one place that may drive the semantics tree directly.
      // ignore: invalid_use_of_protected_member
      SemanticsBinding.instance.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: centre.id,
        ),
      );
      await tester.pump();
      expect(state(tester).cells[0], 0);
      handle.dispose();
    });

    rangoliTest('Share image appears with a sharer and shares a PNG', (
      tester,
    ) async {
      await tester.pumpWidget(app(withSharer: true));
      await tester.ensureVisible(find.text('Share image'));
      // Nothing to share yet.
      await tester.tap(find.text('Share image'), warnIfMissed: false);
      await tester.pump();
      expect(sharer.shared, isEmpty);

      await tapCanvas(tester, 0.5, 0);
      await tester.runAsync(() async {
        await tester.tap(find.text('Share image'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      expect(sharer.shared.length, 1);
      // PNG signature.
      expect(sharer.shared.single.take(4), [0x89, 0x50, 0x4E, 0x47]);
    });

    rangoliTest('a failed share says so and offers Retry', (tester) async {
      sharer.fail = true;
      await tester.pumpWidget(app(withSharer: true));
      await tapCanvas(tester, 0.5, 0);
      await tester.ensureVisible(find.text('Share image'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Share image'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      expect(find.text('Could not share the picture.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    for (final (name, size, scale) in [
      ('320x568 at 2x text', const Size(320, 568), 2.0),
      ('360x800', const Size(360, 800), 1.0),
      ('600x900', const Size(600, 900), 1.0),
    ]) {
      rangoliTest('fits at $name', size: size, (tester) async {
        await tester.pumpWidget(
          app(scale: scale, size: size, withSharer: true),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Random'));
        await tester.tap(find.text('Random'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final box = tester.getRect(find.byType(RangoliCanvas));
        expect(box.width, lessThanOrEqualTo(size.width));
      });
    }
  });
}
