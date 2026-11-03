import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

/// The Kannada flag, yellow over red (3:2). It waves in the breeze while
/// [motion] is active (each time the tab appears) and lies flat when still.
class WavingFlag extends StatelessWidget {
  const WavingFlag({required this.motion, required this.width, super.key});

  final AmbientMotion motion;
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
        child: CustomPaint(painter: _FlagPainter(motion)),
      ),
    ),
  );
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.motion) : super(repaint: motion);

  final AmbientMotion motion;

  /// Wave height at full motion, as a fraction of the flag's height.
  static const double _amplitude = 0.1;
  static const double _waves = 1.5;

  /// Waves travelling along the flag per second.
  static const double _speed = 1.1;
  static const double _step = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final t = motion.time;
    final amplitude = size.height * _amplitude * motion.strength;
    double wave(double x) =>
        amplitude *
        sin(x / size.width * 2 * pi * _waves - t * 2 * pi * _speed) *
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
  bool shouldRepaint(_FlagPainter oldDelegate) => oldDelegate.motion != motion;
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

/// Drives the banner's ambient decoration (toran sway, drifting petals) from
/// one ticker. It runs for [AppDurations.ambient] each time the Rajyotsava
/// tab appears (selected tab, no sub-screen on top, app in the foreground),
/// easing in and out, and not at all with reduced motion. [strength] is 0
/// when still and 1 at full motion; [time] is elapsed seconds.
class RajyotsavaAmbience extends StatefulWidget {
  const RajyotsavaAmbience({required this.builder, super.key});

  final Widget Function(BuildContext context, AmbientMotion motion) builder;

  @override
  State<RajyotsavaAmbience> createState() => _RajyotsavaAmbienceState();
}

/// The ambient clock and its envelope.
class AmbientMotion extends ChangeNotifier {
  double time = 0;
  double strength = 0;

  void _set(double t, double s) {
    time = t;
    strength = s;
    notifyListeners();
  }
}

class _RajyotsavaAmbienceState extends State<RajyotsavaAmbience>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final AppLifecycleListener _lifecycle;
  final AmbientMotion _motion = AmbientMotion();
  var _foreground = true;
  var _visible = false;

  /// Seconds for motion to ease in and out of the ambient window.
  static const double _easeIn = 0.8;
  static const double _easeOut = 2;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        _sync();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final visible =
        _foreground &&
        !reduceMotion(context) &&
        Visibility.of(context) &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (visible == _visible) return;
    _visible = visible;
    if (visible) {
      // Start after the frame is drawn, so the motion is seen from its start.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _visible && !_ticker.isActive) _ticker.start();
      });
    } else {
      _ticker.stop();
      _motion._set(_motion.time, 0);
    }
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final total =
        AppDurations.ambient.inMicroseconds / Duration.microsecondsPerSecond;
    if (t >= total) {
      _ticker.stop();
      _motion._set(t, 0);
      return;
    }
    final strength = min(1.0, min(t / _easeIn, (total - t) / _easeOut));
    _motion._set(t, Curves.easeInOut.transform(strength.clamp(0, 1)));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _ticker.dispose();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _motion);
}

/// A toran of mango leaves and marigolds hung across the top of the banner,
/// a traditional Karnataka festival decoration. Sways gently with [motion].
class Toran extends StatelessWidget {
  const Toran({required this.motion, super.key});

  final AmbientMotion motion;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: const Size(double.infinity, AppSizes.toran),
        painter: _ToranPainter(motion),
      ),
    ),
  );
}

class _ToranPainter extends CustomPainter {
  _ToranPainter(this.motion) : super(repaint: motion);

  final AmbientMotion motion;

  // Painter-local geometry.
  static const double _spacing = 26;
  static const double _ropeSag = 6;
  static const double _leafLength = 26;
  static const double _leafWidth = 9;
  static const double _flowerRadius = 7;
  static const double _petals = 10;
  static const double _maxSway = 0.16;
  static const double _ropeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final count = max(3, (size.width / _spacing).floor());
    final gap = size.width / count;
    double ropeY(double x) => _ropeSag * sin(x / size.width * pi) + _ropeWidth;
    canvas.drawPath(
      Path()
        ..moveTo(0, ropeY(0))
        ..quadraticBezierTo(size.width / 2, _ropeSag * 2, size.width, 0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ropeWidth
        ..color = AppColors.rangoliMarigold.withValues(
          alpha: AppOpacity.strong,
        ),
    );
    for (var i = 0; i < count; i++) {
      final x = gap * (i + 0.5);
      final top = Offset(x, ropeY(x));
      final sway =
          _maxSway * motion.strength * sin(motion.time * 2.2 + i * 0.9);
      canvas
        ..save()
        ..translate(top.dx, top.dy)
        ..rotate(sway);
      if (i.isEven) {
        _leaf(canvas);
      } else {
        _marigold(canvas);
      }
      canvas.restore();
    }
  }

  void _leaf(Canvas canvas) {
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(_leafWidth, _leafLength * 0.45, 0, _leafLength)
      ..quadraticBezierTo(-_leafWidth, _leafLength * 0.45, 0, 0);
    canvas
      ..drawPath(path, Paint()..color = AppColors.rangoliLeaf)
      ..drawLine(
        Offset.zero,
        const Offset(0, _leafLength),
        Paint()
          ..strokeWidth = 1
          ..color = AppColors.onBanner.withValues(alpha: AppOpacity.subtle),
      );
  }

  void _marigold(Canvas canvas) {
    const centre = Offset(0, _flowerRadius + 2);
    final petal = Paint()..color = AppColors.rangoliSaffron;
    for (var p = 0; p < _petals; p++) {
      final a = p * 2 * pi / _petals;
      canvas.drawCircle(
        centre + Offset.fromDirection(a, _flowerRadius * 0.6),
        _flowerRadius * 0.5,
        petal,
      );
    }
    canvas.drawCircle(
      centre,
      _flowerRadius * 0.55,
      Paint()..color = AppColors.rangoliMarigold,
    );
  }

  @override
  bool shouldRepaint(_ToranPainter old) => old.motion != motion;
}

/// Marigold and flag-coloured petals drifting down over the banner while
/// [motion] is active. Draws nothing when still.
class PetalField extends StatelessWidget {
  const PetalField({required this.motion, this.count = 18, super.key});

  final AmbientMotion motion;
  final int count;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _PetalPainter(motion, count),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _PetalPainter extends CustomPainter {
  _PetalPainter(this.motion, this.count) : super(repaint: motion);

  final AmbientMotion motion;
  final int count;

  static const double _length = 7;
  static const double _width = 4;

  /// Fraction part, for cheap deterministic "randomness" per petal.
  static double _frac(double v) => v - v.floorToDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final s = motion.strength;
    if (s <= 0) return;
    final t = motion.time;
    const colors = [
      AppColors.kannadaYellow,
      AppColors.rangoliSaffron,
      AppColors.kannadaRed,
      AppColors.rangoliMarigold,
    ];
    for (var i = 0; i < count; i++) {
      final speed = 0.05 + 0.06 * _frac(i * 0.7548776);
      final y = size.height * _frac(_frac(i * 0.5698402) + t * speed);
      final drift = sin(t * 1.3 + i) * _length * 2;
      final x = _frac(i * 0.6180339) * size.width + drift;
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(t * (0.6 + _frac(i * 0.32)) + i);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: _width, height: _length),
        Paint()
          ..color = colors[i % colors.length].withValues(
            alpha: AppOpacity.strong * s,
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalPainter old) =>
      old.motion != motion || old.count != count;
}

/// Thin flag-coloured rule with a centred diamond, above section titles.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: SizedBox(
      height: AppSpacing.md,
      width: double.infinity,
      child: CustomPaint(painter: _OrnamentPainter()),
    ),
  );
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter();

  static const double _gap = 12;
  static const double _gem = 5;
  static const double _stroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final cx = size.width / 2;
    final left = Rect.fromLTWH(0, cy, cx - _gap, _stroke);
    final right = Rect.fromLTWH(cx + _gap, cy, cx - _gap, _stroke);
    canvas
      ..drawRect(
        left,
        Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.kannadaYellow.withValues(alpha: 0),
              AppColors.kannadaYellow,
            ],
          ).createShader(left),
      )
      ..drawRect(
        right,
        Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.kannadaRed,
              AppColors.kannadaRed.withValues(alpha: 0),
            ],
          ).createShader(right),
      )
      ..drawPath(
        Path()
          ..moveTo(cx, cy - _gem)
          ..lineTo(cx + _gem, cy)
          ..lineTo(cx, cy + _gem)
          ..lineTo(cx - _gem, cy)
          ..close(),
        Paint()..color = AppColors.kannadaRed,
      )
      ..drawCircle(
        Offset(cx, cy),
        _gem / 2.5,
        Paint()..color = AppColors.kannadaYellow,
      );
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) => false;
}

/// Red and yellow fireworks over the banner: a few bursts while [motion] is
/// active (when the tab appears), plus one wherever the person taps an empty
/// part of the banner. Decorative; nothing with reduced motion.
class Fireworks extends StatefulWidget {
  const Fireworks({required this.motion, super.key});

  final AmbientMotion motion;

  @override
  State<Fireworks> createState() => _FireworksState();
}

class _FireworksState extends State<Fireworks>
    with SingleTickerProviderStateMixin {
  /// Bursts launched by taps, as (position, start time in seconds).
  final List<(Offset, double)> _taps = [];
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _tapClock = ValueNotifier<double>(0);

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _tapClock.value = t;
    _taps.removeWhere((b) => t - b.$2 > _FireworksPainter.life);
    if (_taps.isEmpty) _ticker.stop();
  }

  void _launch(TapUpDetails details) {
    if (reduceMotion(context)) return;
    if (!_ticker.isActive) {
      _tapClock.value = 0;
      _ticker.start();
    }
    _taps.add((details.localPosition, _tapClock.value));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tapClock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _launch,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _FireworksPainter(widget.motion, _tapClock, _taps),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.motion, this.tapClock, this.taps)
    : super(repaint: Listenable.merge([motion, tapClock]));

  final AmbientMotion motion;
  final ValueListenable<double> tapClock;
  final List<(Offset, double)> taps;

  /// Seconds a burst lasts: rocket rise, then sparks falling and fading.
  static const double life = 1.8;
  static const double _rise = 0.45;
  static const int _sparks = 32;
  static const double _reach = 95;
  static const double _gravity = 60;
  static const double _sparkRadius = 2.8;

  /// Automatic bursts: start time (s) and position as fractions of the size.
  static const List<(double, double, double)> _auto = [
    (0.5, 0.72, 0.22),
    (1.6, 0.30, 0.30),
    (2.7, 0.85, 0.40),
    (3.9, 0.55, 0.18),
    (5.1, 0.18, 0.45),
  ];

  static const List<Color> _colors = [
    AppColors.kannadaRed,
    AppColors.kannadaYellow,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (motion.strength > 0) {
      for (var i = 0; i < _auto.length; i++) {
        final (start, fx, fy) = _auto[i];
        _burst(
          canvas,
          size,
          Offset(fx * size.width, fy * size.height),
          motion.time - start,
          i,
          rocket: true,
        );
      }
    }
    final now = tapClock.value;
    for (var i = 0; i < taps.length; i++) {
      final (at, start) = taps[i];
      _burst(canvas, size, at, now - start, i + _auto.length, rocket: false);
    }
  }

  void _burst(
    Canvas canvas,
    Size size,
    Offset at,
    double age,
    int seed, {
    required bool rocket,
  }) {
    if (age < 0 || age > life) return;
    final main = _colors[seed % _colors.length];
    final other = _colors[(seed + 1) % _colors.length];
    if (rocket && age < _rise) {
      // Rocket climbing from the bottom with a short glowing trail.
      final p = Curves.easeOut.transform(age / _rise);
      final from = Offset(at.dx, size.height);
      final head = Offset.lerp(from, at, p)!;
      final tail = Offset.lerp(from, at, max(0, p - 0.25))!;
      canvas
        ..drawLine(
          tail,
          head,
          Paint()
            ..strokeWidth = _sparkRadius
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(colors: [main.withValues(alpha: 0), main])
                .createShader(Rect.fromPoints(tail, head)),
        )
        ..drawCircle(
          head,
          _sparkRadius * 1.2,
          Paint()..color = AppColors.onBanner,
        );
      return;
    }
    final t = rocket ? age - _rise : age;
    final span = rocket ? life - _rise : life;
    final p = (t / span).clamp(0.0, 1.0);
    final fade = 1 - Curves.easeIn.transform(p);
    // A white flash at the centre just after it bursts.
    if (p < 0.15) {
      canvas.drawCircle(
        at,
        _sparkRadius * 6 * (1 - p / 0.15),
        Paint()
          ..color = AppColors.onBanner.withValues(
            alpha: AppOpacity.strong * fade,
          ),
      );
    }
    final reach = _reach * Curves.easeOutCubic.transform(p);
    final drop = _gravity * p * p;
    for (var s = 0; s < _sparks; s++) {
      final angle = s * 2 * pi / _sparks + seed;
      final spread = 0.75 + 0.25 * sin(seed * 3.7 + s * 1.3);
      final pos =
          at + Offset.fromDirection(angle, reach * spread) + Offset(0, drop);
      final color = (s.isEven ? main : other).withValues(alpha: fade);
      canvas
        ..drawCircle(
          pos,
          _sparkRadius * 2,
          Paint()..color = color.withValues(alpha: AppOpacity.faint * fade),
        )
        ..drawCircle(pos, _sparkRadius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) =>
      old.motion != motion || old.tapClock != tapClock || old.taps != taps;
}
