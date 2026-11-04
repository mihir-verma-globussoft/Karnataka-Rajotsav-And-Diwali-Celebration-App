import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_tokens.dart';

/// Diwali fireworks over [child]. [show] rockets rise and burst when the
/// widget appears and whenever [showKey] changes; a tap anywhere sets off a
/// burst at that point. Everything is finite: the ticker stops when the last
/// spark fades. Nothing runs when the system asks for reduced motion.
class FireworkShow extends StatefulWidget {
  const FireworkShow({
    super.key,
    required this.child,
    required this.accent,
    required this.showKey,
    this.onBurst,
  });

  final Widget child;
  final Color accent;
  final Object showKey;

  /// Called when a tap sets off a burst (for haptics).
  final VoidCallback? onBurst;

  @override
  State<FireworkShow> createState() => _FireworkShowState();
}

class _Burst {
  _Burst(this.at, this.start, this.rocket, this.seed, this.accent);

  /// Centre as fractions of the layer's width and height.
  final Offset at;
  final Duration start;
  final bool rocket;
  final int seed;
  final Color accent;
}

class _FireworkShowState extends State<FireworkShow>
    with SingleTickerProviderStateMixin {
  static const int _maxBursts = 8;

  /// Rockets of the opening show: (x, y, delay in ms) as screen fractions.
  static const List<(double, double, int)> _opening = [
    (0.2, 0.28, 250),
    (0.8, 0.22, 600),
    (0.5, 0.12, 950),
  ];

  final _bursts = <_Burst>[];
  final _clock = ValueNotifier<Duration>(Duration.zero);
  late final Ticker _ticker = createTicker(_tick);
  int _count = 0;

  bool get _still => MediaQuery.disableAnimationsOf(context);

  void _tick(Duration elapsed) {
    _clock.value = elapsed;
    _bursts.removeWhere((b) => elapsed - b.start > _FireworkPainter.lifeOf(b));
    if (_bursts.isEmpty) _ticker.stop();
  }

  void _launch(Offset at, {int delayMs = 0, bool rocket = false}) {
    if (!_ticker.isActive) {
      _clock.value = Duration.zero;
      _ticker.start();
    }
    if (_bursts.length >= _maxBursts) _bursts.removeAt(0);
    _bursts.add(
      _Burst(
        at,
        _clock.value + Duration(milliseconds: delayMs),
        rocket,
        _count++,
        widget.accent,
      ),
    );
  }

  void _opening_() {
    if (_still) return;
    for (final (x, y, ms) in _opening) {
      _launch(Offset(x, y), delayMs: ms, rocket: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_count == 0 && _bursts.isEmpty) _opening_();
  }

  @override
  void didUpdateWidget(FireworkShow old) {
    super.didUpdateWidget(old);
    if (old.showKey != widget.showKey) _opening_();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (d) {
        if (_still || box.biggest.isEmpty) return;
        widget.onBurst?.call();
        _launch(
          Offset(
            d.localPosition.dx / box.maxWidth,
            d.localPosition.dy / box.maxHeight,
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          // Decorative: ignores touches and is hidden from screen readers.
          Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _FireworkPainter(_bursts, _clock),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FireworkPainter extends CustomPainter {
  _FireworkPainter(this.bursts, this.clock) : super(repaint: clock);

  final List<_Burst> bursts;
  final ValueNotifier<Duration> clock;

  // Painter-local tuning.
  static const double _rise = 0.55;
  static const double _burstLife = 1.7;
  static const int _sparks = 30;
  static const double _reach = 0.38;
  static const double _gravity = 0.35;
  static const double _streak = 3;
  static const double _head = 3.6;
  static const double _tail = 0.12;
  static const double _flashShare = 0.2;

  static const List<Color> _palette = [
    AppColors.diwaliGold,
    AppColors.diwaliSaffron,
    AppColors.rangoliMagenta,
    AppColors.diwaliFlameCore,
    AppColors.rangoliTeal,
    AppColors.diwaliCream,
  ];

  static Duration lifeOf(_Burst b) => Duration(
    milliseconds: ((b.rocket ? _rise : 0) * 1000 + _burstLife * 1000).round(),
  );

  static double _ease(double t) => 1 - math.pow(1 - t, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (final b in bursts) {
      final age = (clock.value - b.start).inMicroseconds / 1e6;
      if (age < 0) continue;
      final centre = Offset(b.at.dx * size.width, b.at.dy * size.height);
      final rise = b.rocket ? _rise : 0.0;
      if (age < rise) {
        final r = _ease(age / rise);
        final head = Offset(
          centre.dx,
          size.height + (centre.dy - size.height) * r,
        );
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = _streak
          ..color = AppColors.diwaliFlameCore;
        canvas.drawLine(head, head + Offset(0, size.height * _tail), paint);
        paint
          ..style = PaintingStyle.fill
          ..color = AppColors.diwaliCream;
        canvas.drawCircle(head, _head, paint);
        continue;
      }
      _burst(canvas, size, paint, b, centre, (age - rise) / _burstLife);
    }
  }

  void _burst(
    Canvas canvas,
    Size size,
    Paint paint,
    _Burst b,
    Offset centre,
    double s,
  ) {
    if (s > 1) return;
    final reach = size.width * _reach;
    final fade = math.pow(1 - s, 1.4).toDouble();
    if (s < _flashShare) {
      final f = s / _flashShare;
      paint
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            b.accent.withValues(alpha: AppOpacity.glow * (1 - f)),
            b.accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: reach));
      canvas.drawCircle(centre, reach, paint);
      paint.shader = null;
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = _streak;
    for (var k = 0; k < _sparks; k++) {
      final angle =
          k * 2 * math.pi / _sparks + 0.35 * math.sin(b.seed * 3.1 + k * 1.7);
      final length = reach * (0.7 + 0.3 * ((k * 0.618 + b.seed * 0.37) % 1));
      // The accent colour is on every third spark; the rest are festival gold.
      final color = k % 3 == 0 ? b.accent : _palette[(k + b.seed) % 6];
      Offset at(double along) {
        final a = along.clamp(0.0, 1.0);
        final d = length * _ease(a);
        return centre +
            Offset(
              math.cos(angle) * d,
              math.sin(angle) * d + _gravity * reach * a * a,
            );
      }

      paint.color = color.withValues(
        alpha: fade * (0.75 + 0.25 * math.sin(s * 18 + k)),
      );
      canvas.drawLine(at(s - 0.1), at(s), paint);
    }
  }

  @override
  bool shouldRepaint(_FireworkPainter old) => true;
}
