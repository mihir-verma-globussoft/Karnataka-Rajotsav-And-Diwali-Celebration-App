import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Whether the person asked the system to reduce motion (iOS Reduce Motion,
/// Android "Remove animations"). Decorative motion is then skipped or
/// replaced by a fade.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Starts [controller] once the frame that first shows it has been drawn,
/// so the animation is seen from its beginning even if that first frame is
/// slow (app start-up, first visit to a screen).
void startAfterFirstFrame(AnimationController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (controller.isDismissed) controller.forward();
  });
}

/// Fades and slides [child] up into place once, when first shown. Items with
/// a higher [index] start a little later, so a list enters one by one. With
/// reduced motion it only fades.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  /// Later items do not wait longer than this many steps.
  static const int maxStagger = 8;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay =
        AppDurations.stagger * min(widget.index, FadeSlideIn.maxStagger);
    final total = AppDurations.entrance + delay;
    _controller = AnimationController(vsync: this, duration: total);
    startAfterFirstFrame(_controller);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faded = FadeTransition(opacity: _progress, child: widget.child);
    if (reduceMotion(context)) return faded;
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, _slideFraction),
        end: Offset.zero,
      ).animate(_progress),
      child: faded,
    );
  }

  /// How far below its place an item starts, as a fraction of its height.
  static const double _slideFraction = 0.12;
}

/// The Kannada flag, waving for a moment when [progress] runs from 0 to 1
/// and then lying flat. Yellow over red, 3:2.
class WavingFlag extends StatelessWidget {
  const WavingFlag({required this.progress, required this.width, super.key});

  final Animation<double> progress;
  final double width;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Kannada flag',
    image: true,
    child: ClipRRect(
      borderRadius: AppRadius.xsAll,
      child: SizedBox(
        width: width,
        height: width * 2 / 3,
        child: CustomPaint(painter: _FlagPainter(progress)),
      ),
    ),
  );
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  /// Wave height at the start, as a fraction of the flag's height.
  static const double _amplitude = 0.08;
  static const double _waves = 1.5;
  static const double _cycles = 3;
  static const double _step = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final amplitude = size.height * _amplitude * (1 - t);
    double wave(double x) =>
        amplitude *
        sin(x / size.width * 2 * pi * _waves + t * 2 * pi * _cycles) *
        // Fixed at the hoist (left), free at the fly (right).
        (x / size.width);

    Path band(double top, double bottom) {
      final path = Path()..moveTo(0, top);
      for (var x = 0.0; x <= size.width; x += _step) {
        path.lineTo(x, top + wave(x));
      }
      for (var x = size.width; x >= 0; x -= _step) {
        path.lineTo(x, bottom + wave(x));
      }
      return path..close();
    }

    final middle = size.height / 2;
    // Bands overlap the edges so the wave never shows a gap.
    canvas
      ..drawPath(
        band(-amplitude, middle),
        Paint()..color = AppColors.kannadaYellow,
      )
      ..drawPath(
        band(middle, size.height + amplitude),
        Paint()..color = AppColors.kannadaRed,
      );
  }

  @override
  bool shouldRepaint(_FlagPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Shows [value] counting up from zero as [progress] runs from 0 to 1.
class CountUp extends StatelessWidget {
  const CountUp({
    required this.value,
    required this.progress,
    required this.builder,
    super.key,
  });

  final int value;
  final Animation<double> progress;
  final Widget Function(BuildContext context, int value) builder;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (context, _) => builder(context, (value * progress.value).round()),
  );
}

/// Three small bars that bounce while [active], like a music equalizer.
/// Still when inactive or with reduced motion.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    required this.active,
    required this.color,
    this.size = AppIconSizes.xs,
    super.key,
  });

  final bool active;
  final Color color;
  final double size;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.loop,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate = widget.active && !reduceMotion(context);
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(painter: _BarsPainter(_controller, widget.color)),
    ),
  );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.progress, this.color) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  static const int _bars = 3;
  static const double _minHeight = 0.3;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width / (_bars * 2 + 1);
    final paint = Paint()..color = color;
    for (var i = 0; i < _bars; i++) {
      final phase = (progress.value + i / _bars) * 2 * pi;
      final h =
          size.height * (_minHeight + (1 - _minHeight) * (sin(phase) + 1) / 2);
      final x = gap * (1 + i * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, gap, h),
          Radius.circular(gap / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) => oldDelegate.color != color;
}
