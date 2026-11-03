import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_tokens.dart';

import '../../../core/theme/pacman_tokens.dart';

/// Animated Diwali night: twinkling stars, fireworks and a marigold toran.
/// Owns its own clock and ticker, so any screen can drop it in a Stack.
///
/// Decorative motion is finite (docs/DESIGN_SYSTEM.md): unless [loop] is set,
/// it plays for [AppDurations.ambient] and then rests as a quiet night sky.
/// With reduced motion it never plays.
class DiwaliSky extends StatefulWidget {
  const DiwaliSky({super.key, required this.toranTop, this.loop = false});

  /// Where the toran hangs, given the available size.
  final double Function(Size size) toranTop;

  /// Keep the fireworks going for as long as the screen is open (the game).
  final bool loop;

  @override
  State<DiwaliSky> createState() => _DiwaliSkyState();
}

class _DiwaliSkyState extends State<DiwaliSky>
    with SingleTickerProviderStateMixin {
  final Stopwatch _clock = Stopwatch()..start();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final Ticker _ticker = createTicker(_onTick);
  bool _started = false;
  bool _rest = false;

  void _onTick(Duration elapsed) {
    _frame.value++;
    if (!widget.loop && elapsed >= AppDurations.ambient) {
      _ticker.stop();
      setState(() => _rest = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _rest = true;
    } else {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: _SkyPainter(_clock, _frame, widget.toranTop, _rest),
    ),
  );
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.clock, Listenable repaint, this.toranTopFor, this.rest)
    : super(repaint: repaint);

  final Stopwatch clock;

  /// Resting sky: still stars and toran, no fireworks.
  final bool rest;
  final double Function(Size size) toranTopFor;

  static const _colors = [
    PacmanColors.cFFFFD54F,
    PacmanColors.cFFFF4081,
    PacmanColors.cFF40C4FF,
    PacmanColors.cFF69F0AE,
    PacmanColors.cFFFF7043,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = rest ? 0.0 : clock.elapsedMilliseconds / 1000;
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PacmanColors.cFF0B0020,
            PacmanColors.cFF2A0845,
            PacmanColors.cFF4A1050,
          ],
        ).createShader(bounds),
    );

    final stars = math.Random(3);
    for (var i = 0; i < 70; i++) {
      final p = Offset(
        stars.nextDouble() * size.width,
        stars.nextDouble() * size.height,
      );
      final a = 0.25 + 0.75 * math.sin(t * 1.5 + i).abs();
      canvas.drawCircle(
        p,
        0.8 + stars.nextDouble() * 1.2,
        Paint()..color = PacmanColors.white.withValues(alpha: a),
      );
    }

    // Fireworks: four launchers on staggered loops, new spot each loop.
    for (var k = 0; k < 4 && !rest; k++) {
      const period = 3.4;
      final local = t - k * 0.85;
      if (local < 0) continue;
      final cycle = (local / period).floor();
      final phase = (local % period) / period;
      if (phase > 0.65) continue;
      final rnd = math.Random(cycle * 11 + k);
      final center = Offset(
        size.width * (0.12 + rnd.nextDouble() * 0.76),
        size.height * (0.1 + rnd.nextDouble() * 0.6),
      );
      final color = _colors[rnd.nextInt(_colors.length)];
      final e = phase / 0.65;
      for (var i = 0; i < 18; i++) {
        final a = i / 18 * 2 * math.pi;
        final dist = Curves.easeOut.transform(e) * 70;
        final p = center + Offset(math.cos(a), math.sin(a)) * dist;
        canvas.drawCircle(
          p.translate(0, e * e * 14),
          3.2 * (1 - e) + 0.6,
          Paint()..color = color.withValues(alpha: 1 - e),
        );
      }
    }

    // Marigold toran.
    final top = toranTopFor(size);
    final string = Paint()
      ..color = PacmanColors.cFF66BB6A
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, top - 10), Offset(size.width, top - 10), string);
    const n = 14;
    for (var i = 0; i < n; i++) {
      final x = (i + 0.5) * size.width / n;
      final sway = math.sin(t * 2 + i) * 2;
      final y = top + 2;
      canvas.drawLine(Offset(x, top - 10), Offset(x + sway, y), string);
      canvas.drawCircle(
        Offset(x + sway, y + 6),
        7,
        Paint()..color = PacmanColors.cFFFF8F00,
      );
      canvas.drawCircle(
        Offset(x + sway, y + 6),
        4,
        Paint()..color = PacmanColors.cFFFFD54F,
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.rest != rest;
}
