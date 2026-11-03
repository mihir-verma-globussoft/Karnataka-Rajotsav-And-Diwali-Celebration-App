import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_palette.dart';

/// Fraction part, used for cheap deterministic "randomness" per index.
double _frac(double v) => v - v.floorToDouble();

/// Floating embers/sparkles that drift upward. One painter draws every
/// particle; it repaints from the shared clock and draws nothing when [clock]
/// is null (reduced motion, hidden, or scrolled away).
class ParticleField extends StatelessWidget {
  const ParticleField({
    required this.count,
    required this.fade,
    this.clock,
    super.key,
  });

  final int count;

  /// 0..1 intro fade.
  final double fade;
  final ValueListenable<double>? clock;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: clock == null || fade <= 0
            ? null
            : _ParticlePainter(count: count, fade: fade, clock: clock!),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.count,
    required this.fade,
    required this.clock,
  }) : super(repaint: clock);

  final int count;
  final double fade;
  final ValueListenable<double> clock;

  static const double _minRadius = 1;
  static const double _radiusRange = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final x = _frac(i * 0.6180339) * size.width;
      final speed = 0.015 + 0.03 * _frac(i * 0.7548776);
      final y = size.height * (1 - _frac(_frac(i * 0.5698402) + t * speed));
      final twinkle = 0.5 + 0.5 * math.sin(t * 2 + i * 1.7);
      final r = _minRadius + _radiusRange * _frac(i * 0.3247179);
      paint.color = (i.isEven ? DiwaliPalette.flameCore : DiwaliPalette.gold)
          .withValues(alpha: AppOpacity.strong * twinkle * fade);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.count != count || old.fade != fade;
}

/// A string of festive lights hanging across the top. Static (steady glow)
/// when [clock] is null.
class Garland extends StatelessWidget {
  const Garland({required this.fade, this.clock, super.key});

  static const double height = 56;

  final double fade;
  final ValueListenable<double>? clock;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: const Size(double.infinity, height),
        painter: _GarlandPainter(fade: fade, clock: clock),
      ),
    ),
  );
}

class _GarlandPainter extends CustomPainter {
  _GarlandPainter({required this.fade, required this.clock})
    : super(repaint: clock);

  final double fade;
  final ValueListenable<double>? clock;

  static const int _swags = 3;
  static const int _bulbsPerSwag = 5;
  static const double _sag = 0.55;
  static const double _bulbRadius = 4;
  static const double _wireWidth = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    if (fade <= 0) return;
    final t = clock?.value;
    final colors = [
      DiwaliPalette.gold,
      DiwaliPalette.saffron,
      DiwaliPalette.orange,
      DiwaliPalette.flameCore,
    ];
    final swagW = size.width / _swags;
    final wire = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _wireWidth
      ..color = DiwaliPalette.goldDeep.withValues(
        alpha: AppOpacity.strong * fade,
      );
    var index = 0;
    for (var s = 0; s < _swags; s++) {
      final x0 = s * swagW;
      final sagY = size.height * _sag;
      final path = Path()
        ..moveTo(x0, 0)
        ..quadraticBezierTo(x0 + swagW / 2, sagY * 2, x0 + swagW, 0);
      canvas.drawPath(path, wire);
      final metric = path.computeMetrics().first;
      for (var b = 1; b <= _bulbsPerSwag; b++) {
        final pos = metric
            .getTangentForOffset(metric.length * b / (_bulbsPerSwag + 1))!
            .position;
        final twinkle = t == null
            ? 1.0
            : 0.6 + 0.4 * math.sin(t * 2 + index * 1.7);
        final c = colors[index % colors.length];
        canvas.drawCircle(
          pos,
          _bulbRadius * 2,
          Paint()
            ..color = c.withValues(alpha: AppOpacity.faint * twinkle * fade),
        );
        canvas.drawCircle(
          pos,
          _bulbRadius,
          Paint()..color = c.withValues(alpha: twinkle * fade),
        );
        index++;
      }
    }
  }

  @override
  bool shouldRepaint(_GarlandPainter old) =>
      old.fade != fade || old.clock != clock;
}
