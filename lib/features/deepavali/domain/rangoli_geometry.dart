import 'dart:math' as math;

/// One shape of the rangoli: a ring and a sector within it. The centre disc
/// is ring 0 and has a single cell (sector 0).
class RangoliCell {
  const RangoliCell(this.ring, this.sector);

  final int ring;
  final int sector;

  int get index => RangoliGeometry.indexOf(ring, sector);

  @override
  bool operator ==(Object other) =>
      other is RangoliCell && other.ring == ring && other.sector == sector;

  @override
  int get hashCode => Object.hash(ring, sector);

  @override
  String toString() => 'RangoliCell($ring, $sector)';
}

/// Polar layout of the rangoli, in coordinates normalised to the canvas, so
/// hit-testing is a little arithmetic and needs no per-shape paths.
///
/// A centre disc, then four rings of [sectors] sectors. Sector 0 is centred
/// on the top and numbering runs clockwise.
abstract final class RangoliGeometry {
  static const int sectors = 8;
  static const int rings = 5;

  /// Centre disc plus four rings of eight.
  static const int cellCount = 1 + (rings - 1) * sectors;

  /// Outer edge of each ring as a fraction of the canvas radius.
  static const List<double> outerRadius = [0.2, 0.42, 0.62, 0.82, 1.0];

  /// Inner edge of [ring] (0 for the centre disc).
  static double innerRadiusOf(int ring) =>
      ring == 0 ? 0 : outerRadius[ring - 1];

  static int indexOf(int ring, int sector) =>
      ring == 0 ? 0 : 1 + (ring - 1) * sectors + sector;

  static RangoliCell cellOf(int index) {
    assert(index >= 0 && index < cellCount, 'cell index out of range');
    if (index == 0) return const RangoliCell(0, 0);
    final i = index - 1;
    return RangoliCell(1 + i ~/ sectors, i % sectors);
  }

  /// The cell under ([x], [y]) on a square canvas of side [side], or null
  /// outside the circle.
  static RangoliCell? hit(double x, double y, double side) {
    if (side <= 0) return null;
    final half = side / 2;
    final dx = x - half;
    final dy = y - half;
    final d = math.sqrt(dx * dx + dy * dy) / half;
    if (d > 1) return null;
    var ring = rings - 1;
    for (var r = 0; r < rings; r++) {
      if (d < outerRadius[r]) {
        ring = r;
        break;
      }
    }
    if (ring == 0) return const RangoliCell(0, 0);
    // Clockwise from the top, shifted so sector 0 is centred on the top.
    const step = 2 * math.pi / sectors;
    var angle = math.atan2(dx, -dy) + step / 2;
    angle = (angle % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    return RangoliCell(ring, (angle / step).floor() % sectors);
  }

  /// The cells painted together when symmetry is on: the tapped cell and its
  /// copies turned by quarter turns (four copies; the centre has none).
  static List<int> symmetric(int index) {
    final c = cellOf(index);
    if (c.ring == 0) return const [0];
    return [
      for (var k = 0; k < 4; k++)
        indexOf(c.ring, (c.sector + k * (sectors ~/ 4)) % sectors),
    ];
  }
}
