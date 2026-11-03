import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_palette.dart';

/// A clay diya with a flickering flame, drawn entirely with a painter (no
/// image assets). [ignite] (0..1) grows the flame and glow. When [clock] is
/// null the flame is drawn still (reduced motion / hidden / off-screen).
class DiyaArt extends StatelessWidget {
  const DiyaArt({
    required this.width,
    required this.ignite,
    this.clock,
    super.key,
  });

  /// Aspect: the art is [width] wide and `width * heightFactor` tall.
  static const double heightFactor = 1.1;

  final double width;
  final double ignite;
  final ValueListenable<double>? clock;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size(width, width * heightFactor),
      painter: _DiyaPainter(ignite: ignite, clock: clock),
    ),
  );
}

class _DiyaPainter extends CustomPainter {
  _DiyaPainter({required this.ignite, this.clock}) : super(repaint: clock);

  final double ignite;
  final ValueListenable<double>? clock;

  // Painter-local geometry, as fractions of the art width.
  static const double _bowlTop = 0.62;
  static const double _bowlDepth = 0.30;
  static const double _bowlWidth = 0.82;
  static const double _flameHeight = 0.52;
  static const double _flameWidth = 0.22;
  static const double _glowRadius = 0.75;

  /// Gentle two-sine flicker in [-1, 1]; zero when still.
  double _flicker() {
    final t = clock?.value;
    if (t == null) return 0;
    return (math.sin(t * 7.1) * 0.6 + math.sin(t * 13.3 + 1.3) * 0.4);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w / 2;
    final flick = _flicker();
    final p = ignite.clamp(0.0, 1.0);

    // Glow behind the flame.
    final flameBase = Offset(cx, w * _bowlTop);
    if (p > 0) {
      final r = w * _glowRadius * (0.9 + 0.1 * p + 0.04 * flick);
      final glow = Paint()
        ..shader = RadialGradient(
          colors: [
            DiwaliPalette.flameCore.withValues(alpha: AppOpacity.glow * p),
            DiwaliPalette.flameCore.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: flameBase, radius: r));
      canvas.drawCircle(flameBase, r, glow);
    }

    // Bowl: a half-ellipse with a clay gradient.
    final bowlW = w * _bowlWidth;
    final bowlRect = Rect.fromLTWH(
      cx - bowlW / 2,
      w * _bowlTop - w * 0.05,
      bowlW,
      w * (_bowlDepth + 0.1),
    );
    final bowl = Path()
      ..moveTo(bowlRect.left, w * _bowlTop)
      ..quadraticBezierTo(
        bowlRect.left + bowlW * 0.08,
        bowlRect.bottom,
        cx,
        bowlRect.bottom,
      )
      ..quadraticBezierTo(
        bowlRect.right - bowlW * 0.08,
        bowlRect.bottom,
        bowlRect.right,
        w * _bowlTop,
      )
      ..close();
    canvas.drawPath(
      bowl,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DiwaliPalette.orange,
            DiwaliPalette.goldDeep,
            DiwaliPalette.maroon,
          ],
        ).createShader(bowlRect),
    );
    // Rim.
    final rim = Rect.fromCenter(
      center: Offset(cx, w * _bowlTop),
      width: bowlW,
      height: w * 0.12,
    );
    canvas.drawOval(rim, Paint()..color = DiwaliPalette.saffron);
    canvas.drawOval(
      rim.deflate(w * 0.025),
      Paint()..color = DiwaliPalette.maroon,
    );
    // Wick.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, w * _bowlTop - w * 0.03),
          width: w * 0.035,
          height: w * 0.08,
        ),
        Radius.circular(w * 0.01),
      ),
      Paint()..color = DiwaliPalette.night,
    );

    if (p <= 0) return;
    // Flame: three nested teardrops.
    final fh = w * _flameHeight * p * (1 + 0.05 * flick);
    final fw = w * _flameWidth * p;
    final sway = fw * 0.18 * flick;
    final base = Offset(cx, w * _bowlTop - w * 0.06);
    _flame(canvas, base, fw, fh, sway, DiwaliPalette.orange);
    _flame(
      canvas,
      base,
      fw * 0.72,
      fh * 0.78,
      sway * 0.8,
      DiwaliPalette.saffron,
    );
    _flame(
      canvas,
      base,
      fw * 0.42,
      fh * 0.5,
      sway * 0.5,
      DiwaliPalette.flameCore,
    );
  }

  void _flame(
    Canvas canvas,
    Offset base,
    double width,
    double height,
    double sway,
    Color color,
  ) {
    final tip = Offset(base.dx + sway, base.dy - height);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx - width,
        base.dy - height * 0.25,
        base.dx - width * 0.5,
        base.dy - height * 0.7,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        base.dx + width * 0.5,
        base.dy - height * 0.7,
        base.dx + width,
        base.dy - height * 0.25,
        base.dx,
        base.dy,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DiyaPainter old) =>
      old.ignite != ignite || old.clock != clock;
}
