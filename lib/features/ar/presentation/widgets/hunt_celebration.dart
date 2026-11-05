import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/hunt_models.dart';
import 'hunt_widgets.dart';

/// Crackers going off behind the winners' board: rockets rise and burst into
/// sparks, one after another. It only decorates, so screen readers skip it, and
/// with reduced motion it holds one still frame of the same bursts.
class HuntCrackers extends StatefulWidget {
  const HuntCrackers({super.key});

  @override
  State<HuntCrackers> createState() => _HuntCrackersState();
}

class _HuntCrackersState extends State<HuntCrackers>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: AppDurations.celebration,
  );

  /// The row along the bottom of the page.
  static const int _diyas = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock
        ..stop()
        ..value = _CrackersPainter.stillFrame;
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Its own layer: it repaints every frame, the board on top does not.
          RepaintBoundary(
            child: CustomPaint(painter: _CrackersPainter(_clock)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < _diyas; i++)
                      const HuntItemArt(HuntItemKind.diya),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Cracker {
  const _Cracker(this.x, this.y, this.delay, this.color);

  /// Where it bursts, as fractions of the page.
  final double x;
  final double y;

  /// How far through the show it goes off.
  final double delay;
  final Color color;
}

class _CrackersPainter extends CustomPainter {
  _CrackersPainter(this.clock) : super(repaint: clock);

  /// A moment when several crackers are at their fullest.
  static const double stillFrame = 0.42;

  static const List<_Cracker> _crackers = [
    _Cracker(0.18, 0.16, 0, AppColors.diwaliGold),
    _Cracker(0.8, 0.12, 0.12, AppColors.kannadaRed),
    _Cracker(0.5, 0.3, 0.25, AppColors.kannadaYellow),
    _Cracker(0.14, 0.5, 0.37, AppColors.diwaliSaffron),
    _Cracker(0.86, 0.44, 0.5, AppColors.diwaliCream),
    _Cracker(0.38, 0.66, 0.62, AppColors.diwaliOrange),
    _Cracker(0.72, 0.72, 0.75, AppColors.diwaliGold),
    _Cracker(0.3, 0.08, 0.87, AppColors.kannadaRed),
  ];

  // Painter-local tuning: all fractions of the page or of one cracker's life.
  static const int _sparks = 28;
  static const double _riseEnds = 0.25;
  static const double _reach = 0.3;
  static const double _shortestReach = 0.55;
  static const double _fall = 0.07;
  static const double _sparkSize = 0.009;
  static const double _trail = 0.14;
  static const double _flashEnds = 0.16;
  static const double _flashSize = 0.09;

  final Animation<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (final cracker in _crackers) {
      final life = (clock.value - cracker.delay) % 1;
      final burstAt = Offset(cracker.x * size.width, cracker.y * size.height);
      if (life < _riseEnds) {
        _rocket(canvas, size, burstAt, life / _riseEnds, cracker.color, paint);
      } else {
        final burst = (life - _riseEnds) / (1 - _riseEnds);
        _burst(canvas, size, burstAt, burst, cracker.color, paint);
      }
    }
  }

  double _heightAt(Size size, Offset to, double rise) =>
      size.height + (to.dy - size.height) * rise;

  void _rocket(
    Canvas canvas,
    Size size,
    Offset to,
    double rise,
    Color color,
    Paint paint,
  ) {
    paint
      ..color = color
      ..strokeWidth = size.shortestSide * _sparkSize;
    canvas.drawLine(
      Offset(to.dx, _heightAt(size, to, math.max(0, rise - _trail))),
      Offset(to.dx, _heightAt(size, to, rise)),
      paint,
    );
  }

  void _burst(
    Canvas canvas,
    Size size,
    Offset centre,
    double burst,
    Color color,
    Paint paint,
  ) {
    final fade = 1 - burst;
    if (burst < _flashEnds) {
      paint.color = AppColors.diwaliCream.withValues(
        alpha: 1 - burst / _flashEnds,
      );
      canvas.drawCircle(centre, size.shortestSide * _flashSize * fade, paint);
    }
    final tip = Curves.easeOutCubic.transform(burst);
    final tail = Curves.easeOutCubic.transform(math.max(0, burst - _trail));
    final drop = size.height * _fall * burst * burst;
    paint.strokeWidth = size.shortestSide * _sparkSize * fade;
    for (var i = 0; i < _sparks; i++) {
      final angle = i * 2 * math.pi / _sparks;
      final direction = Offset(math.cos(angle), math.sin(angle));
      // Uneven lengths, so a burst looks like sparks and not a neat ring.
      final length = _shortestReach + (1 - _shortestReach) * ((i * 7) % 5) / 4;
      final reach = size.shortestSide * _reach * length;
      paint.color = (i.isEven ? color : AppColors.diwaliCream).withValues(
        alpha: fade,
      );
      canvas.drawLine(
        centre + direction * (reach * tail) + Offset(0, drop),
        centre + direction * (reach * tip) + Offset(0, drop),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CrackersPainter oldDelegate) =>
      oldDelegate.clock != clock;
}

/// The top of the winners' board: who won, between lit diyas and flags.
class HuntWinnerBanner extends StatelessWidget {
  const HuntWinnerBanner({
    required this.winner,
    required this.isYou,
    super.key,
  });

  final HuntLeader winner;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ArPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExcludeSemantics(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                HuntItemArt(HuntItemKind.diya),
                HuntItemArt(HuntItemKind.flag),
                Icon(
                  Icons.emoji_events,
                  size: AppIconSizes.hero,
                  color: AppColors.diwaliGold,
                ),
                HuntItemArt(HuntItemKind.flag),
                HuntItemArt(HuntItemKind.diya),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            header: true,
            child: Text(
              isYou ? 'You are the winner!' : 'Winner: ${winner.username}',
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(color: AppColors.onArPanel),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${winner.points} points. '
            'Happy Rajyotsava and happy Deepavali!',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: AppColors.onArPanel),
          ),
        ],
      ),
    );
  }
}
