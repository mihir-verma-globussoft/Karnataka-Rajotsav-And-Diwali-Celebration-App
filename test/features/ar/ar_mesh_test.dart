import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_mesh.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/hunt_models.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/presentation/ar_models.dart';

void main() {
  double dot(List<double> a, List<double> b) =>
      a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

  /// True when every triangle's winding points the same way as its normals.
  /// iOS hides back faces, so a mistake here turns a model inside out.
  void expectOutwardWinding(ArMeshPart part) {
    final p = part.positions;
    final n = part.normals;
    for (var t = 0; t < part.indices.length; t += 3) {
      final a = part.indices[t] * 3;
      final b = part.indices[t + 1] * 3;
      final c = part.indices[t + 2] * 3;
      final u = [p[b] - p[a], p[b + 1] - p[a + 1], p[b + 2] - p[a + 2]];
      final v = [p[c] - p[a], p[c + 1] - p[a + 1], p[c + 2] - p[a + 2]];
      final face = [
        u[1] * v[2] - u[2] * v[1],
        u[2] * v[0] - u[0] * v[2],
        u[0] * v[1] - u[1] * v[0],
      ];
      if (dot(face, face) < 1e-14) continue;
      expect(
        dot(face, [n[a], n[a + 1], n[a + 2]]),
        greaterThanOrEqualTo(-1e-6),
      );
    }
  }

  test('a sphere faces outwards', () {
    const center = [1.0, 2.0, 3.0];
    final ball = sphere(0.5, argb: 0xFFFFFFFF, center: center);
    expectOutwardWinding(ball);
    final p = ball.positions;
    final n = ball.normals;
    for (var i = 0; i < p.length; i += 3) {
      final out = [
        p[i] - center[0],
        p[i + 1] - center[1],
        p[i + 2] - center[2],
      ];
      expect(dot(out, [n[i], n[i + 1], n[i + 2]]), greaterThan(0));
    }
  });

  test('a lathe follows the profile and its angle scaling', () {
    final bowl = lathe(
      const [(0.1, 0.0), (0.2, 0.1)],
      argb: 0xFFFFFFFF,
      segments: 4,
      radiusScale: (angle) => angle == 0 ? 2 : 1,
    );
    expect(bowl.positions.length, 4 * 2 * 3);
    // The first spoke points along +X and is doubled.
    expect(bowl.positions[0], closeTo(0.2, 1e-6));
    expect(bowl.positions[3], closeTo(0.4, 1e-6));
    expectOutwardWinding(bowl);
  });

  test('cloth can be seen from both sides', () {
    final flag = cloth(
      left: 0,
      right: 1,
      bottom: 0,
      top: 1,
      ripple: (_) => 0,
      argb: 0xFFFFFFFF,
      columns: 2,
    );
    expectOutwardWinding(flag);
    final zs = {
      for (var i = 2; i < flag.normals.length; i += 3) flag.normals[i],
    };
    expect(zs, containsAll(<double>[1, -1]));
  });

  group('the real models', () {
    for (final kind in HuntItemKind.values) {
      test('${kind.name} is valid for both renderers', () {
        final model = huntModel(kind);
        expect(model.parts, isNotEmpty);
        expect(model.height, greaterThan(0));
        for (final part in model.parts) {
          final vertices = part.positions.length ~/ 3;
          expect(part.positions.length % 3, 0);
          expect(part.normals.length, part.positions.length);
          expect(part.indices.length % 3, 0);
          // Android draws with 16-bit indices.
          expect(vertices, lessThan(65536));
          expect(part.indices.every((i) => i >= 0 && i < vertices), isTrue);
          expect(part.pivot, hasLength(3));
          expectOutwardWinding(part);
          for (var i = 0; i < part.normals.length; i += 3) {
            final length = math.sqrt(
              part.normals[i] * part.normals[i] +
                  part.normals[i + 1] * part.normals[i + 1] +
                  part.normals[i + 2] * part.normals[i + 2],
            );
            expect(length, closeTo(1, 1e-3));
          }
        }
      });
    }

    test('models stand on the ground and are a sensible size', () {
      for (final kind in HuntItemKind.values) {
        final solid = huntModel(kind).parts.where((part) => !part.unlit);
        final ys = [
          for (final part in solid)
            for (var i = 1; i < part.positions.length; i += 3)
              part.positions[i],
        ];
        expect(ys.reduce(math.min), closeTo(0, 1e-3));
        expect(ys.reduce(math.max), lessThan(1));
      }
    });

    test('the flag is yellow over red', () {
      final flag = huntModel(HuntItemKind.flag);
      double averageY(int argb) {
        final part = flag.parts.firstWhere((part) => part.argb == argb);
        var sum = 0.0;
        for (var i = 1; i < part.positions.length; i += 3) {
          sum += part.positions[i];
        }
        return sum / (part.positions.length / 3);
      }

      final yellow = const Color(0xFFFFD21F).toARGB32();
      expect(yellow, AppColors.kannadaYellow.toARGB32());
      expect(
        averageY(AppColors.kannadaYellow.toARGB32()),
        greaterThan(averageY(AppColors.kannadaRed.toARGB32())),
      );
    });
  });
}
