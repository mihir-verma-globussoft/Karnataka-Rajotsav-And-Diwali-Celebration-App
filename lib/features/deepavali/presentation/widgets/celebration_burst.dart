import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/diwali_palette.dart';

/// A one-shot burst of sparks (at most [particleCount]) that plays once for
/// [duration] and then stops its ticker. Decorative: excluded from semantics.
/// Callers show a static alternative instead when motion is reduced.
class CelebrationBurst extends StatefulWidget {
  const CelebrationBurst({super.key});

  static const int particleCount = 48;
  static const Duration duration = Duration(seconds: 2);

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CelebrationBurst.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BurstPainter(_controller),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _Spark {
  const _Spark(this.angle, this.speed, this.size, this.color);
  final double angle;
  final double speed;
  final double size;
  final Color color;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  // Painter-local constants.
  static const List<Color> _colors = [
    DiwaliPalette.gold,
    DiwaliPalette.saffron,
    DiwaliPalette.flameCore,
    DiwaliPalette.orange,
  ];
  static const double _maxRadius = 0.55; // of the shorter side
  static const double _gravity = 0.18;
  static const double _minSize = 2;
  static const double _sizeSpan = 3;

  // Fixed seed: the same pleasing burst every time, no per-frame randomness.
  static final List<_Spark> _sparks = () {
    final rng = math.Random(8);
    return List<_Spark>.generate(
      CelebrationBurst.particleCount,
      (i) => _Spark(
        rng.nextDouble() * math.pi * 2,
        0.4 + rng.nextDouble() * 0.6,
        _minSize + rng.nextDouble() * _sizeSpan,
        _colors[i % _colors.length],
      ),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(animation.value);
    final fade = 1 - animation.value;
    final origin = size.center(Offset.zero);
    final reach = size.shortestSide * _maxRadius;
    final paint = Paint();
    for (final s in _sparks) {
      final d = reach * s.speed * t;
      final pos = Offset(
        origin.dx + math.cos(s.angle) * d,
        origin.dy + math.sin(s.angle) * d + reach * _gravity * t * t,
      );
      paint.color = s.color.withValues(alpha: fade);
      canvas.drawCircle(pos, s.size * (1 - 0.4 * t), paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.animation != animation;
}
