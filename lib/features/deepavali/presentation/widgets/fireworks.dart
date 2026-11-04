import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_palette.dart';

/// Firecrackers: rockets that rise and burst into coloured sparks across the
/// sky, and two fountains of sparks at the bottom corners.
///
/// One painter draws everything and repaints from the shared animation clock.
/// When [clock] is null (reduced motion, tab hidden, scrolled away) it shows a
/// single still frame of the same bursts, so the page still looks like a
/// celebration without moving. It is decorative and hidden from screen readers.
class FireworksLayer extends StatelessWidget {
  const FireworksLayer({required this.fade, this.clock, super.key});

  /// 0..1 intro fade; nothing is drawn at 0.
  final double fade;
  final ValueListenable<double>? clock;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    // Its own layer: it repaints every frame, and without a boundary the
    // whole long page would repaint with it.
    child: RepaintBoundary(
      child: CustomPaint(
        painter: FireworksPainter(fade: fade, clock: clock),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _Burst {
  const _Burst({
    required this.x,
    required this.y,
    required this.period,
    required this.offset,
    required this.radius,
    required this.colors,
  });

  /// Centre of the burst, as fractions of the layer's width and height.
  final double x;
  final double y;

  /// Seconds for one rocket-and-burst cycle.
  final double period;

  /// Seconds into the cycle at time zero, so the bursts are staggered.
  final double offset;

  /// Burst radius as a fraction of the layer's width.
  final double radius;

  /// Sparks take these colours in turn.
  final List<Color> colors;
}

class FireworksPainter extends CustomPainter {
  FireworksPainter({required this.fade, this.clock}) : super(repaint: clock);

  final double fade;
  final ValueListenable<double>? clock;

  // Painter-local tuning.
  static const List<_Burst> _bursts = [
    _Burst(
      x: 0.15,
      y: 0.22,
      period: 3.0,
      offset: 0,
      radius: 0.3,
      colors: [
        DiwaliPalette.gold,
        DiwaliPalette.flameCore,
        DiwaliPalette.cream,
      ],
    ),
    _Burst(
      x: 0.85,
      y: 0.18,
      period: 3.4,
      offset: 1.1,
      radius: 0.32,
      colors: [
        DiwaliPalette.saffron,
        AppColors.rangoliMagenta,
        DiwaliPalette.flameCore,
      ],
    ),
    _Burst(
      x: 0.5,
      y: 0.07,
      period: 3.8,
      offset: 2.0,
      radius: 0.3,
      colors: [AppColors.rangoliTeal, DiwaliPalette.cream, DiwaliPalette.gold],
    ),
    _Burst(
      x: 0.27,
      y: 0.32,
      period: 3.2,
      offset: 0.6,
      radius: 0.2,
      colors: [
        AppColors.rangoliViolet,
        AppColors.rangoliMagenta,
        DiwaliPalette.flameCore,
      ],
    ),
    _Burst(
      x: 0.75,
      y: 0.3,
      period: 3.6,
      offset: 2.6,
      radius: 0.2,
      colors: [DiwaliPalette.gold, DiwaliPalette.orange, DiwaliPalette.cream],
    ),
  ];

  static const int _sparksPerBurst = 24;
  static const int _fountainSparks = 18;
  static const List<double> _fountainX = [0.07, 0.93];

  /// Share of the cycle the rocket spends rising before it bursts.
  static const double _riseShare = 0.2;

  /// Where the rocket starts, as a fraction of the layer's height.
  static const double _launchY = 0.8;
  static const double _trailLength = 0.1;
  static const double _gravity = 0.4;
  static const double _streakWidth = 3.2;
  static const double _tailShare = 0.1;
  static const double _headRadius = 3.6;
  static const double _flashRadius = 0.09;
  static const double _flashShare = 0.2;
  static const double _glowAlpha = 0.45;
  static const double _sparkAlpha = 1;

  /// Where in its cycle each burst is when nothing moves.
  static const double _stillCycle = 0.52;

  static const double _fountainPeak = 0.34;
  static const double _fountainSpread = 0.1;
  static const double _fountainRate = 0.7;
  static const double _fountainOriginY = 0.95;
  static const double _fountainSparkRadius = 3.2;
  static const double _fountainAlpha = 1;

  /// Most things drawn in one frame, an upper bound the tests hold us to.
  static int get maxPrimitives =>
      _bursts.length * (_sparksPerBurst + 3) +
      _fountainX.length * _fountainSparks;

  static double _frac(double v) => v - v.floorToDouble();

  /// Fast start, slow finish: how far a spark has travelled.
  static double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    if (fade <= 0 || size.isEmpty) return;
    final t = clock?.value;
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var b = 0; b < _bursts.length; b++) {
      _paintBurst(canvas, size, paint, _bursts[b], b, t);
    }
    for (var f = 0; f < _fountainX.length; f++) {
      _paintFountain(canvas, size, paint, _fountainX[f], f, t);
    }
  }

  void _paintBurst(
    Canvas canvas,
    Size size,
    Paint paint,
    _Burst burst,
    int index,
    double? t,
  ) {
    final w = size.width;
    final h = size.height;
    final u = t == null
        ? _stillCycle
        : _frac((t + burst.offset) / burst.period);
    final centre = Offset(burst.x * w, burst.y * h);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = _streakWidth;

    if (u < _riseShare) {
      // The rocket climbs with a short glowing tail.
      final r = _easeOut(u / _riseShare);
      final head = Offset(
        centre.dx,
        _launchY * h + (centre.dy - _launchY * h) * r,
      );
      final tail = head + Offset(0, _trailLength * h * (1 - r));
      paint.color = DiwaliPalette.flameCore.withValues(
        alpha: _sparkAlpha * fade * 0.7,
      );
      canvas.drawLine(head, tail, paint);
      paint
        ..style = PaintingStyle.fill
        ..color = DiwaliPalette.cream.withValues(alpha: _sparkAlpha * fade);
      canvas.drawCircle(head, _headRadius, paint);
      return;
    }

    final s = (u - _riseShare) / (1 - _riseShare);
    final reach = burst.radius * w;
    final fadeOut = math.pow(1 - s, 1.4).toDouble();

    // A bright flash and glow as it bursts.
    if (s < _flashShare) {
      final f = s / _flashShare;
      final glowColor = burst.colors.first;
      paint
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            glowColor.withValues(alpha: _glowAlpha * fade * (1 - f)),
            glowColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: reach * 0.9));
      canvas.drawCircle(centre, reach * 0.9, paint);
      // A soft white-hot core, not a flat disc.
      final core = _flashRadius * w * (0.6 + f);
      paint.shader = RadialGradient(
        colors: [
          DiwaliPalette.cream.withValues(alpha: _sparkAlpha * fade * (1 - f)),
          DiwaliPalette.cream.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: centre, radius: core));
      canvas.drawCircle(centre, core, paint);
      paint.shader = null;
      paint.style = PaintingStyle.stroke;
    }

    for (var k = 0; k < _sparksPerBurst; k++) {
      // Spread evenly round the circle with a little deterministic wobble.
      final angle =
          k * 2 * math.pi / _sparksPerBurst +
          0.35 * math.sin(index * 3.1 + k * 1.7);
      final length = reach * (0.8 + 0.2 * _frac(k * 0.618 + index * 0.37));
      final color = burst.colors[(k + index) % burst.colors.length];
      Offset at(double along) {
        final d = length * _easeOut(along.clamp(0.0, 1.0));
        // Sparks droop as they slow down.
        return centre +
            Offset(
              math.cos(angle) * d,
              math.sin(angle) * d + _gravity * reach * along * along,
            );
      }

      final twinkle = 0.75 + 0.25 * math.sin(s * 18 + k);
      paint.color = color.withValues(
        alpha: _sparkAlpha * fade * fadeOut * twinkle,
      );
      canvas.drawLine(at(s - _tailShare), at(s), paint);
    }
  }

  void _paintFountain(
    Canvas canvas,
    Size size,
    Paint paint,
    double x,
    int index,
    double? t,
  ) {
    final w = size.width;
    final h = size.height;
    final origin = Offset(x * w, _fountainOriginY * h);
    paint.style = PaintingStyle.fill;
    const colors = [
      DiwaliPalette.gold,
      DiwaliPalette.orange,
      DiwaliPalette.flameCore,
    ];
    for (var k = 0; k < _fountainSparks; k++) {
      final life = _frac(
        k / _fountainSparks + (t == null ? 0.0 : t * _fountainRate),
      );
      // Up and back down in a parabola, drifting sideways.
      final lift = 4 * life * (1 - life);
      final side =
          (k.isEven ? 1 : -1) *
          _fountainSpread *
          w *
          life *
          (0.4 + 0.6 * _frac(k * 0.618 + index * 0.5));
      final peak = _fountainPeak * h * (0.6 + 0.4 * _frac(k * 0.382));
      final at = origin + Offset(side, -peak * lift);
      paint.color = colors[k % colors.length].withValues(
        alpha: _fountainAlpha * fade * math.sin(math.pi * life),
      );
      canvas.drawCircle(at, _fountainSparkRadius, paint);
    }
  }

  @override
  bool shouldRepaint(FireworksPainter oldDelegate) =>
      oldDelegate.fade != fade || oldDelegate.clock != clock;
}
