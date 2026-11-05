import 'dart:math' as math;
import 'dart:typed_data';

/// One single-coloured piece of a 3D model. Both native renderers draw these
/// as they are, so the models look the same on Android and iOS.
class ArMeshPart {
  const ArMeshPart({
    required this.positions,
    required this.normals,
    required this.indices,
    required this.argb,
    this.unlit = false,
    this.flicker = false,
    this.pivot = const [0, 0, 0],
  });

  final Float32List positions;
  final Float32List normals;
  final Int32List indices;
  final int argb;

  /// Glows at a constant brightness, ignoring the room's light.
  final bool unlit;

  /// Wobbles around [pivot] like a flame.
  final bool flicker;
  final List<double> pivot;

  Map<String, Object> toWire() => {
    'positions': positions,
    'normals': normals,
    'indices': indices,
    'argb': argb,
    'unlit': unlit,
    'flicker': flicker,
    'pivot': pivot,
  };
}

class ArModel {
  const ArModel({required this.height, required this.parts});

  /// Metres from the base to the top of the solid parts; the native view aims
  /// taps at the middle of this.
  final double height;
  final List<ArMeshPart> parts;

  Map<String, Object> toWire() => {
    'height': height,
    'parts': [for (final part in parts) part.toWire()],
  };
}

/// Spins a profile of (radius, height) points around the Y axis. List the
/// points along the surface with the outside on the right as you walk: from
/// the base up the outer wall, then back down any inner wall.
ArMeshPart lathe(
  List<(double, double)> profile, {
  required int argb,
  List<double> center = const [0, 0, 0],
  double Function(double angle)? radiusScale,
  int segments = 32,
  bool unlit = false,
  bool flicker = false,
  List<double> pivot = const [0, 0, 0],
}) {
  final positions = <double>[];
  for (var i = 0; i < segments; i++) {
    final angle = 2 * math.pi * i / segments;
    final scale = radiusScale?.call(angle) ?? 1.0;
    for (final (radius, height) in profile) {
      positions
        ..add(center[0] + radius * scale * math.cos(angle))
        ..add(center[1] + height)
        ..add(center[2] + radius * scale * math.sin(angle));
    }
  }
  final indices = <int>[];
  final rows = profile.length;
  for (var i = 0; i < segments; i++) {
    final next = (i + 1) % segments;
    for (var j = 0; j < rows - 1; j++) {
      final a = i * rows + j;
      final b = next * rows + j;
      final c = next * rows + j + 1;
      final d = i * rows + j + 1;
      indices.addAll([a, c, b, a, d, c]);
    }
  }
  return _part(positions, indices, argb, unlit, flicker, pivot);
}

/// A ball, for haloes and finials.
ArMeshPart sphere(
  double radius, {
  required int argb,
  List<double> center = const [0, 0, 0],
  int rings = 10,
  int segments = 20,
  bool unlit = false,
  bool flicker = false,
  List<double> pivot = const [0, 0, 0],
}) => lathe(
  [
    for (var i = 0; i <= rings; i++)
      (
        radius * math.sin(math.pi * i / rings),
        -radius * math.cos(math.pi * i / rings),
      ),
  ],
  argb: argb,
  center: center,
  segments: segments,
  unlit: unlit,
  flicker: flicker,
  pivot: pivot,
);

/// A flat sheet in the XY plane with a ripple along Z, visible from both sides.
ArMeshPart cloth({
  required double left,
  required double right,
  required double bottom,
  required double top,
  required double Function(double x) ripple,
  required int argb,
  int columns = 20,
}) {
  final positions = <double>[];
  final indices = <int>[];
  // Back faces are culled on iOS, so each side gets its own triangles.
  for (var side = 0; side < 2; side++) {
    final start = positions.length ~/ 3;
    for (var i = 0; i <= columns; i++) {
      final x = left + (right - left) * i / columns;
      positions.addAll([x, bottom, ripple(x), x, top, ripple(x)]);
    }
    for (var i = 0; i < columns; i++) {
      final a = start + i * 2;
      final b = a + 1;
      final c = a + 2;
      final d = a + 3;
      if (side == 0) {
        indices.addAll([a, c, d, a, d, b]);
      } else {
        indices.addAll([a, d, c, a, b, d]);
      }
    }
  }
  return _part(positions, indices, argb, false, false, const [0, 0, 0]);
}

ArMeshPart _part(
  List<double> positions,
  List<int> indices,
  int argb,
  bool unlit,
  bool flicker,
  List<double> pivot,
) => ArMeshPart(
  positions: Float32List.fromList(positions),
  normals: Float32List.fromList(_smoothNormals(positions, indices)),
  indices: Int32List.fromList(indices),
  argb: argb,
  unlit: unlit,
  flicker: flicker,
  pivot: pivot,
);

List<double> _smoothNormals(List<double> positions, List<int> indices) {
  final normals = List<double>.filled(positions.length, 0);
  for (var t = 0; t < indices.length; t += 3) {
    final a = indices[t] * 3;
    final b = indices[t + 1] * 3;
    final c = indices[t + 2] * 3;
    final ux = positions[b] - positions[a];
    final uy = positions[b + 1] - positions[a + 1];
    final uz = positions[b + 2] - positions[a + 2];
    final vx = positions[c] - positions[a];
    final vy = positions[c + 1] - positions[a + 1];
    final vz = positions[c + 2] - positions[a + 2];
    final nx = uy * vz - uz * vy;
    final ny = uz * vx - ux * vz;
    final nz = ux * vy - uy * vx;
    for (final vertex in [a, b, c]) {
      normals[vertex] += nx;
      normals[vertex + 1] += ny;
      normals[vertex + 2] += nz;
    }
  }
  for (var i = 0; i < normals.length; i += 3) {
    final length = math.sqrt(
      normals[i] * normals[i] +
          normals[i + 1] * normals[i + 1] +
          normals[i + 2] * normals[i + 2],
    );
    // Degenerate vertices, such as the tip of a lathe, point straight up.
    if (length == 0) {
      normals[i + 1] = 1;
    } else {
      normals[i] /= length;
      normals[i + 1] /= length;
      normals[i + 2] /= length;
    }
  }
  return normals;
}
