import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../domain/rangoli_geometry.dart';
import '../theme/diwali_palette.dart';
import '../theme/rangoli_palette.dart';

/// The rangoli drawing. Only [cells] decide how it looks, so it repaints only
/// when the design changes. Painted on a solid background so exported
/// pictures are never transparent.
class RangoliCanvas extends StatelessWidget {
  const RangoliCanvas({
    required this.cells,
    required this.onCell,
    required this.boundaryKey,
    this.maxSide = 360,
    super.key,
  });

  final List<int?> cells;
  final ValueChanged<int> onCell;

  /// Key of the [RepaintBoundary] around the drawing, used to capture it.
  final GlobalKey boundaryKey;

  /// Largest side of the square canvas.
  final double maxSide;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = math.min(constraints.maxWidth, maxSide);
      final size = Size.square(side);
      final painter = RangoliPainter(cells: cells, onCell: onCell);
      return Center(
        child: SizedBox.square(
          dimension: side,
          child: RepaintBoundary(
            key: boundaryKey,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final cell = RangoliGeometry.hit(
                  d.localPosition.dx,
                  d.localPosition.dy,
                  side,
                );
                if (cell != null) onCell(cell.index);
              },
              child: CustomPaint(size: size, painter: painter),
            ),
          ),
        ),
      );
    },
  );
}

/// Draws the cells as annular wedges, plus a ring of decorative dots.
class RangoliPainter extends CustomPainter {
  RangoliPainter({required this.cells, required this.onCell});

  final List<int?> cells;
  final ValueChanged<int> onCell;

  // Painter-local geometry.
  static const double _drawScale = 0.88; // drawing radius / canvas radius
  static const double _cornerRadius = 0.08; // of the side
  static const double _outline = 1.5;
  static const double _dotRing = 0.95; // of the canvas radius
  static const double _dotSize = 0.012; // of the side
  static const int _dots = 16;

  /// Wedge (or disc) outline for the cell at [index].
  static Path cellPath(int index, Size size) {
    final cell = RangoliGeometry.cellOf(index);
    final centre = size.center(Offset.zero);
    final scale = size.width / 2 * _drawScale;
    final outer = RangoliGeometry.outerRadius[cell.ring] * scale;
    if (cell.ring == 0) {
      return Path()..addOval(Rect.fromCircle(center: centre, radius: outer));
    }
    final inner = RangoliGeometry.innerRadiusOf(cell.ring) * scale;
    const step = 2 * math.pi / RangoliGeometry.sectors;
    // Sector 0 is centred on the top; angles run clockwise from there.
    final start = -math.pi / 2 + (cell.sector - 0.5) * step;
    return Path()
      ..arcTo(Rect.fromCircle(center: centre, radius: outer), start, step, true)
      ..arcTo(
        Rect.fromCircle(center: centre, radius: inner),
        start + step,
        -step,
        false,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(side * _cornerRadius),
      ),
      Paint()..color = DiwaliPalette.plum,
    );

    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outline
      ..color = DiwaliPalette.night;
    for (var i = 0; i < RangoliGeometry.cellCount; i++) {
      final path = cellPath(i, size);
      final colour = cells[i];
      fill.color = colour == null
          ? DiwaliPalette.surface
          : RangoliPalette.colours[colour].color;
      canvas
        ..drawPath(path, fill)
        ..drawPath(path, line);
    }

    final centre = size.center(Offset.zero);
    final dots = Paint()..color = DiwaliPalette.gold;
    for (var i = 0; i < _dots; i++) {
      final a = i * 2 * math.pi / _dots;
      canvas.drawCircle(
        centre + Offset(math.cos(a), math.sin(a)) * (side / 2 * _dotRing),
        side * _dotSize,
        dots,
      );
    }
  }

  /// One semantic node per shape, so the canvas works with a screen reader.
  @override
  SemanticsBuilderCallback get semanticsBuilder => _buildSemantics;

  List<CustomPainterSemantics> _buildSemantics(Size size) => [
    for (var i = 0; i < RangoliGeometry.cellCount; i++)
      CustomPainterSemantics(
        rect: cellPath(i, size).getBounds(),
        properties: SemanticsProperties(
          label: _label(i),
          textDirection: TextDirection.ltr,
          button: true,
          onTap: () => onCell(i),
        ),
      ),
  ];

  String _label(int index) {
    final cell = RangoliGeometry.cellOf(index);
    final colour = cells[index];
    final where = cell.ring == 0
        ? 'Centre'
        : 'Ring ${cell.ring}, section ${cell.sector + 1}';
    final state = colour == null
        ? 'not coloured'
        : RangoliPalette.colours[colour].name;
    return '$where, $state. Double tap to colour.';
  }

  @override
  bool shouldRepaint(RangoliPainter oldDelegate) =>
      !identical(oldDelegate.cells, cells);

  @override
  bool shouldRebuildSemantics(RangoliPainter oldDelegate) =>
      !identical(oldDelegate.cells, cells);
}
