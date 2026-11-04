import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/diwali_palette.dart';

/// A simple house at night, ready to be decorated. Decorative, so it is hidden
/// from screen readers (the screen describes what is on it).
class HouseArt extends StatelessWidget {
  const HouseArt({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: CustomPaint(painter: _HousePainter(), child: SizedBox.expand()),
  );
}

class _HousePainter extends CustomPainter {
  const _HousePainter();

  // Painter-local geometry, as fractions of the picture side.
  static const double _groundTop = 0.84;
  static const double _wallLeft = 0.2;
  static const double _wallRight = 0.8;
  static const double _wallTop = 0.42;
  static const double _roofTop = 0.22;
  static const double _starAlpha = 0.7;
  static const double _windowAlpha = 0.85;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DiwaliPalette.night,
            DiwaliPalette.plum,
            DiwaliPalette.maroon,
          ],
        ).createShader(rect),
    );

    // Stars: a fixed sky, the same every time.
    final star = Paint()
      ..color = DiwaliPalette.cream.withValues(alpha: _starAlpha);
    final rng = math.Random(11);
    for (var i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.4),
        w * (0.002 + rng.nextDouble() * 0.004),
        star,
      );
    }

    // Ground.
    canvas.drawRect(
      Rect.fromLTRB(0, h * _groundTop, w, h),
      Paint()..color = DiwaliPalette.night,
    );

    // Walls and roof.
    final wall = Rect.fromLTRB(
      w * _wallLeft,
      h * _wallTop,
      w * _wallRight,
      h * _groundTop,
    );
    canvas.drawRect(wall, Paint()..color = DiwaliPalette.surfaceHigh);
    canvas.drawPath(
      Path()
        ..moveTo(w * (_wallLeft - 0.04), h * _wallTop)
        ..lineTo(w * 0.5, h * _roofTop)
        ..lineTo(w * (_wallRight + 0.04), h * _wallTop)
        ..close(),
      Paint()..color = DiwaliPalette.maroon,
    );

    // Warm windows and a door.
    final glow = Paint()
      ..color = DiwaliPalette.flameCore.withValues(alpha: _windowAlpha);
    for (final x in const [0.27, 0.62]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * x, h * 0.52, w * 0.11, h * 0.12),
          Radius.circular(w * 0.01),
        ),
        glow,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.44, h * 0.62, w * 0.56, h * _groundTop),
        Radius.circular(w * 0.015),
      ),
      Paint()..color = DiwaliPalette.goldDeep,
    );
  }

  @override
  bool shouldRepaint(_HousePainter oldDelegate) => false;
}
