import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/pacman_tokens.dart';

enum CartoonKind { fireBreather, monster, hulk, thunderMan, theKing, destroyer }

/// A cartoon body drawn in code with the person's photo as the head.
/// While [active] is false it stands in an idle pose; while true it performs
/// (fire breath, sword swing, hulk pounding), driven by [animation] (0..1,
/// looping). Drawn in a 140x140 box and scaled to fit.
class CartoonCharacter extends StatelessWidget {
  const CartoonCharacter({
    super.key,
    required this.kind,
    required this.photoAsset,
    required this.animation,
    this.active = true,
  });

  final CartoonKind kind;
  final String photoAsset;
  final Animation<double> animation;
  final bool active;

  static const double _box = 140;
  static const double _head = 62;

  @override
  Widget build(BuildContext context) {
    // The photos are cut out along the person's outline (transparent edges).
    Widget head = Image.asset(
      photoAsset,
      width: _head,
      height: _head,
      fit: BoxFit.contain,
      cacheWidth: 256,
    );
    if (kind == CartoonKind.hulk) {
      head = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          PacmanColors.c994CAF50,
          BlendMode.srcATop,
        ),
        child: head,
      );
    }
    return FittedBox(
      child: SizedBox(
        width: _box,
        height: _box,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = active ? animation.value : 0.0;
            final off = _headOffset(kind, t, active);
            final pulse = kind == CartoonKind.hulk && active
                ? 1 + 0.06 * math.sin(t * 2 * math.pi * 2)
                : 1.0;
            return Stack(
              children: [
                CustomPaint(
                  size: const Size(_box, _box),
                  painter: _BodyPainter(kind, t, active),
                ),
                Positioned(
                  left: 39 + off.dx,
                  top: 8 + off.dy,
                  child: Transform.scale(scale: pulse, child: head),
                ),
                CustomPaint(
                  size: const Size(_box, _box),
                  painter: _FrontPainter(kind, t, off, active),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Where the head sits relative to its rest spot while performing.
Offset _headOffset(CartoonKind kind, double t, bool active) {
  if (!active) return Offset.zero;
  switch (kind) {
    case CartoonKind.thunderMan:
      return Offset(24 * math.sin(t * 2 * math.pi), 0);
    case CartoonKind.destroyer:
      if (t < 0.5) return Offset(0, -6 * math.sin(t / 0.5 * math.pi / 2));
      if (t < 0.6) return Offset(0, -6 + 14 * ((t - 0.5) / 0.1));
      final k = 1 - (t - 0.6) / 0.4;
      return Offset(3 * k * math.sin(t * 90), 8 * k);
    default:
      return Offset(0, math.sin(t * 2 * math.pi * 2) * 1.5);
  }
}

Path _heart(Offset c, double s) => Path()
  ..moveTo(c.dx, c.dy + s * 0.9)
  ..cubicTo(
    c.dx - s * 1.6,
    c.dy - s * 0.2,
    c.dx - s * 0.7,
    c.dy - s * 1.3,
    c.dx,
    c.dy - s * 0.4,
  )
  ..cubicTo(
    c.dx + s * 0.7,
    c.dy - s * 1.3,
    c.dx + s * 1.6,
    c.dy - s * 0.2,
    c.dx,
    c.dy + s * 0.9,
  )
  ..close();

// Painter geometry in the 140x140 character box (not screen sizes).
const double _bodyRadius = 10;
const double _shortsRadius = 8;
const double _hiltRadius = 2;
const double _rockWidth = 6;
const double _rockHeight = 5;
const double _footWidth = 22;
const double _footHeight = 11;
const double _ringMinWidth = 30;
const double _ringGrowWidth = 100;
const double _ringMinHeight = 6;
const double _ringGrowHeight = 12;
const double _mouthWidth = 13;
const double _mouthHeight = 10;
const double _flameWidth = 7;
const double _flameHeight = 5;

Paint _fill(Color c) => Paint()..color = c;

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

const Color _skin = PacmanColors.cFFFFCC80;

class _BodyPainter extends CustomPainter {
  _BodyPainter(this.kind, this.t, this.active);

  final CartoonKind kind;
  final double t;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    // Ground shadow.
    canvas.drawOval(
      const Rect.fromLTWH(30, 126, 80, 10),
      _fill(PacmanColors.c40000000),
    );
    switch (kind) {
      case CartoonKind.fireBreather:
        _fireGuy(canvas);
      case CartoonKind.monster:
        _monster(canvas);
      case CartoonKind.hulk:
        _hulk(canvas);
      case CartoonKind.thunderMan:
        _thunderMan(canvas);
      case CartoonKind.theKing:
        _theKing(canvas);
      case CartoonKind.destroyer:
        _destroyer(canvas);
    }
  }

  void _fireGuy(Canvas canvas) =>
      _basicPerson(canvas, PacmanColors.cFFD84315, PacmanColors.cFFFFD54F);

  void _basicPerson(
    Canvas canvas,
    Color shirt,
    Color trim, {
    bool rightArm = true,
  }) {
    final leg = _stroke(PacmanColors.cFF37474F, 9);
    canvas.drawLine(const Offset(62, 104), const Offset(58, 126), leg);
    canvas.drawLine(const Offset(78, 104), const Offset(82, 126), leg);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(50, 66, 40, 42),
        const Radius.circular(_bodyRadius),
      ),
      _fill(shirt),
    );
    // Gold kurta trim.
    canvas.drawLine(
      const Offset(70, 68),
      const Offset(70, 106),
      _stroke(trim, 3),
    );
    for (final side in [-1.0, 1.0]) {
      if (side > 0 && !rightArm) continue;
      canvas.drawLine(
        Offset(70 + side * 18, 74),
        Offset(70 + side * 29, 98),
        _stroke(shirt, 8),
      );
      canvas.drawCircle(Offset(70 + side * 30, 100), 5, _fill(_skin));
    }
  }

  void _thunderMan(Canvas canvas) {
    final off = _headOffset(kind, t, active);
    final dir = math.cos(t * 2 * math.pi) >= 0 ? 1.0 : -1.0;
    if (active) {
      // Speed lines trail behind the dash.
      for (var i = 0; i < 6; i++) {
        final y = 70.0 + i * 10;
        final x0 = 70 + off.dx - dir * 34;
        canvas.drawLine(
          Offset(x0, y),
          Offset(x0 - dir * (14 + (i % 3) * 8), y),
          _stroke(PacmanColors.cAAFFF176, 2.5),
        );
      }
      // Afterimages.
      for (var k = 2; k >= 1; k--) {
        canvas.saveLayer(
          null,
          Paint()
            ..color = PacmanColors.white.withValues(
              alpha: PacmanOpacity.afterimage,
            ),
        );
        canvas.translate(off.dx - dir * k * 11, 0);
        _basicPerson(canvas, PacmanColors.cFFFFC107, PacmanColors.cFF212121);
        canvas.restore();
      }
    }
    canvas.save();
    canvas.translate(off.dx, 0);
    _basicPerson(canvas, PacmanColors.cFFFFC107, PacmanColors.cFF212121);
    // Lightning-bolt emblem on the chest.
    canvas.drawPath(
      Path()
        ..moveTo(74, 72)
        ..lineTo(64, 90)
        ..lineTo(70, 90)
        ..lineTo(66, 104)
        ..lineTo(78, 84)
        ..lineTo(71, 84)
        ..close(),
      _fill(PacmanColors.cFF212121),
    );
    canvas.restore();
  }

  void _theKing(Canvas canvas) {
    const robe = PacmanColors.cFF1565C0;
    // Cape behind.
    canvas.drawPath(
      Path()
        ..moveTo(48, 66)
        ..lineTo(92, 66)
        ..lineTo(112, 122)
        ..lineTo(28, 122)
        ..close(),
      _fill(PacmanColors.cFF0D47A1),
    );
    final leg = _stroke(PacmanColors.cFF37474F, 9);
    canvas.drawLine(const Offset(62, 104), const Offset(58, 126), leg);
    canvas.drawLine(const Offset(78, 104), const Offset(82, 126), leg);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(48, 66, 44, 42),
        const Radius.circular(_bodyRadius),
      ),
      _fill(robe),
    );
    canvas.drawLine(
      const Offset(70, 68),
      const Offset(70, 106),
      _stroke(PacmanColors.cFFFFD54F, 4),
    );
    canvas.drawCircle(const Offset(70, 86), 4, _fill(PacmanColors.cFFE53935));
    // King pose: arms sweep up and out.
    final spread = active ? 0.5 + 0.5 * math.sin(t * 2 * math.pi) : 0.0;
    final a = 1.2 - 1.8 * spread;
    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(70 + side * 20, 74);
      final hand = shoulder + Offset(side * math.cos(a), math.sin(a)) * 28;
      canvas.drawLine(shoulder, hand, _stroke(robe, 8));
      canvas.drawCircle(hand, 5, _fill(_skin));
    }
  }

  void _destroyer(Canvas canvas) {
    const armor = PacmanColors.cFFEF6C00;
    final off = _headOffset(kind, t, active);
    final p = active ? t : 0.0;
    // Ground cracks and flying rocks after the slam.
    if (active && p > 0.6) {
      final k = (p - 0.6) / 0.4;
      final reach = 66 * math.min(1.0, k * 3);
      final crack = _stroke(
        PacmanColors.cFF4E342E.withValues(alpha: 1 - k * 0.6),
        3,
      );
      for (final side in [-1.0, 1.0]) {
        final path = Path()..moveTo(70, 128);
        for (var i = 1; i <= 5; i++) {
          path.lineTo(70 + side * reach * i / 5, 128 + (i.isOdd ? -5 : 4));
        }
        canvas.drawPath(path, crack..style = PaintingStyle.stroke);
      }
      final u = math.min(1.0, k / 0.85);
      for (var i = 0; i < 8; i++) {
        final x = 70 + (i - 3.5) * 13;
        final h = math.sin(u * math.pi) * (22 + (i % 3) * 14);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, 124 - h),
            width: _rockWidth,
            height: _rockHeight,
          ),
          _fill(PacmanColors.cFF8D6E63.withValues(alpha: 1 - u * 0.5)),
        );
      }
    }
    canvas.save();
    canvas.translate(off.dx, 0);
    final leg = _stroke(PacmanColors.cFF3E2723, 12);
    canvas.drawLine(const Offset(60, 104), const Offset(56, 126), leg);
    canvas.drawLine(const Offset(80, 104), const Offset(84, 126), leg);
    final torso = Path()
      ..moveTo(40, 66)
      ..lineTo(100, 66)
      ..lineTo(92, 108)
      ..lineTo(48, 108)
      ..close();
    canvas.drawPath(torso, _fill(armor));
    canvas.drawPath(torso, _stroke(PacmanColors.cFFBF360C, 2));
    canvas.drawLine(
      const Offset(48, 98),
      const Offset(92, 98),
      _stroke(PacmanColors.cFF3E2723, 5),
    );
    // Spiked shoulder pads.
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(70 + side * 26, 68)
          ..lineTo(70 + side * 40, 56)
          ..lineTo(70 + side * 40, 74)
          ..close(),
        _fill(PacmanColors.cFF8D6E63),
      );
    }
    // Arms: fists rise, slam down, rest on the ground.
    final fistY = p < 0.5
        ? 112 - 76 * Curves.easeOut.transform(p / 0.5)
        : p < 0.6
        ? 36 + 76 * ((p - 0.5) / 0.1)
        : 112.0;
    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(70 + side * 28, 74);
      final fist = Offset(70 + side * 42, fistY.toDouble());
      canvas.drawLine(shoulder, fist, _stroke(armor, 12));
      canvas.drawCircle(fist, 10, _fill(PacmanColors.cFF6D4C41));
    }
    canvas.restore();
  }

  void _monster(Canvas canvas) {
    const purple = PacmanColors.cFF7E57C2;
    const horn = PacmanColors.cFFFFF59D;
    // Horns peek out above the head.
    for (final side in [-1.0, 1.0]) {
      final horns = Path()
        ..moveTo(70 + side * 22, 26)
        ..lineTo(70 + side * 28, 2)
        ..lineTo(70 + side * 8, 16)
        ..close();
      canvas.drawPath(horns, _fill(horn));
      canvas.drawPath(horns, _stroke(PacmanColors.cFFF9A825, 1.5));
    }
    // Feet.
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(70 + side * 13, 120),
          width: _footWidth,
          height: _footHeight,
        ),
        _fill(PacmanColors.cFFFF7043),
      );
    }
    // Round furry body with spots.
    canvas.drawOval(const Rect.fromLTWH(42, 64, 56, 56), _fill(purple));
    canvas.drawOval(
      const Rect.fromLTWH(42, 64, 56, 56),
      _stroke(PacmanColors.cFF4527A0, 2),
    );
    final spot = _fill(PacmanColors.cFFB39DDB);
    canvas.drawCircle(const Offset(58, 98), 5, spot);
    canvas.drawCircle(const Offset(80, 106), 4, spot);
    canvas.drawCircle(const Offset(72, 90), 3, spot);
    // Left arm waves a little.
    final wave = active ? math.sin(t * 2 * math.pi * 2) * 0.3 : 0.0;
    final hand = Offset(40 - 8 * math.cos(wave), 92 + 8 * math.sin(wave) - 6);
    canvas.drawLine(const Offset(46, 84), hand, _stroke(purple, 8));
    canvas.drawCircle(hand, 5, _fill(PacmanColors.cFFD1C4E9));
    _sword(canvas);
  }

  void _sword(Canvas canvas) {
    const shoulder = Offset(88, 84);
    final phase = math.sin(t * 2 * math.pi);
    // Swings from up-and-back down to forward; idle holds it upright.
    final theta = active ? -0.2 + 1.1 * phase : -1.0;
    final hand = shoulder + Offset(math.cos(theta), math.sin(theta)) * 12;
    canvas.drawLine(shoulder, hand, _stroke(PacmanColors.cFF7E57C2, 8));
    if (active) {
      // Swoosh trail behind the blade.
      final dir = math.cos(t * 2 * math.pi) >= 0 ? 1.0 : -1.0;
      canvas.drawArc(
        Rect.fromCircle(center: shoulder, radius: 40),
        theta - 0.7 * dir,
        0.7 * dir,
        false,
        _stroke(PacmanColors.c88FFFFFF, 5),
      );
    }
    canvas.save();
    canvas.translate(hand.dx, hand.dy);
    canvas.rotate(theta);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, -2.5, 10, 5),
        const Radius.circular(_hiltRadius),
      ),
      _fill(PacmanColors.cFF5D4037),
    );
    canvas.drawRect(
      const Rect.fromLTWH(4, -6, 3, 12),
      _fill(PacmanColors.cFFFFC107),
    );
    final blade = Path()
      ..moveTo(7, -3)
      ..lineTo(32, -3)
      ..lineTo(38, 0)
      ..lineTo(32, 3)
      ..lineTo(7, 3)
      ..close();
    canvas.drawPath(blade, _fill(PacmanColors.cFFECEFF1));
    canvas.drawLine(
      const Offset(8, 0),
      const Offset(34, 0),
      _stroke(PacmanColors.cFF90A4AE, 1),
    );
    canvas.restore();
    canvas.drawCircle(hand, 5, _fill(PacmanColors.cFFD1C4E9));
  }

  void _hulk(Canvas canvas) {
    const green = PacmanColors.cFF4CAF50;
    final dark = _stroke(PacmanColors.cFF2E7D32, 2);
    final flex = 1 + 0.12 * math.sin(t * 2 * math.pi * 2);
    if (active) {
      // Ground shockwave from the pounding fists.
      final ph = (t * 2) % 1;
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(70, 128),
          width: _ringMinWidth + _ringGrowWidth * ph,
          height: _ringMinHeight + _ringGrowHeight * ph,
        ),
        _stroke(PacmanColors.cFFFFC107.withValues(alpha: 1 - ph), 3),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(46, 100, 48, 24),
        const Radius.circular(_shortsRadius),
      ),
      _fill(PacmanColors.cFF6A1B9A),
    );
    final torso = Path()
      ..moveTo(32, 64)
      ..lineTo(108, 64)
      ..lineTo(94, 106)
      ..lineTo(46, 106)
      ..close();
    canvas.drawPath(torso, _fill(green));
    canvas.drawPath(torso, dark);
    canvas.drawLine(const Offset(70, 74), const Offset(70, 100), dark);
    canvas.drawArc(const Rect.fromLTWH(46, 70, 24, 16), 0.2, 2.7, false, dark);
    canvas.drawArc(const Rect.fromLTWH(70, 70, 24, 16), 0.2, 2.7, false, dark);
    for (final side in [-1.0, 1.0]) {
      final bicep = Offset(70 + side * 46, 82);
      canvas.drawCircle(bicep, 16 * flex, _fill(green));
      canvas.drawCircle(bicep, 16 * flex, dark);
      // Fists alternate pounding down.
      final pound = active
          ? math.sin(t * 2 * math.pi * 2 + (side > 0 ? math.pi : 0)) * 8
          : 0.0;
      final fist = Offset(70 + side * 50, 104 + pound);
      canvas.drawCircle(fist, 13, _fill(green));
      canvas.drawCircle(fist, 13, dark);
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) => old.t != t || old.active != active;
}

/// Drawn over the head: mouth fire, hulk brows, lightning, crown and hearts.
class _FrontPainter extends CustomPainter {
  _FrontPainter(this.kind, this.t, this.off, this.active);

  final CartoonKind kind;
  final double t;
  final Offset off;
  final bool active;

  double get bob => off.dy;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case CartoonKind.fireBreather:
        if (active) _fire(canvas);
      case CartoonKind.hulk:
        final brow = _stroke(PacmanColors.cFF1B5E20, 4);
        canvas.drawLine(Offset(52, 29 + bob), Offset(66, 35 + bob), brow);
        canvas.drawLine(Offset(88, 29 + bob), Offset(74, 35 + bob), brow);
      case CartoonKind.thunderMan:
        if (active) _bolts(canvas);
      case CartoonKind.theKing:
        _crown(canvas);
        if (active) _heartWave(canvas);
      case CartoonKind.monster:
      case CartoonKind.destroyer:
        break;
    }
  }

  void _bolts(Canvas canvas) {
    canvas.save();
    canvas.translate(off.dx, 0);
    // New random zigzags a dozen times a second.
    final rnd = math.Random((t * 12).floor() + 7);
    for (var b = 0; b < 3; b++) {
      final side = b == 1 ? 1.0 : -1.0;
      var p = Offset(70 + side * (14 + b * 10), 0);
      final path = Path()..moveTo(p.dx, p.dy);
      for (var i = 1; i <= 6; i++) {
        p = Offset(
          70 + side * (30 + b * 6) + (rnd.nextDouble() - 0.5) * 22,
          i * 20.0,
        );
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, _stroke(PacmanColors.cFFFFEB3B, 4));
      canvas.drawPath(path, _stroke(PacmanColors.white, 1.5));
    }
    canvas.restore();
  }

  void _crown(Canvas canvas) {
    final crown = Path()
      ..moveTo(52, 22 + bob)
      ..lineTo(52, 6 + bob)
      ..lineTo(61, 14 + bob)
      ..lineTo(70, 2 + bob)
      ..lineTo(79, 14 + bob)
      ..lineTo(88, 6 + bob)
      ..lineTo(88, 22 + bob)
      ..close();
    canvas.drawPath(crown, _fill(PacmanColors.cFFFFD54F));
    canvas.drawPath(crown, _stroke(PacmanColors.cFFF9A825, 1.5));
    canvas.drawCircle(Offset(70, 15 + bob), 3, _fill(PacmanColors.cFFE53935));
  }

  void _heartWave(Canvas canvas) {
    const center = Offset(70, 90);
    for (var i = 0; i < 8; i++) {
      final ph = (t * 1.5 + i / 8) % 1;
      final a = i / 8 * 2 * math.pi;
      final pos = center + Offset(math.cos(a), math.sin(a)) * (14 + ph * 52);
      canvas.drawPath(
        _heart(pos, 3 + ph * 5),
        _fill(PacmanColors.cFFFF4081.withValues(alpha: 1 - ph)),
      );
    }
    // Icy ring: the "freeze".
    final ph = (t * 1.5) % 1;
    canvas.drawCircle(
      center,
      12 + ph * 56,
      _stroke(PacmanColors.cFFB3E5FC.withValues(alpha: 1 - ph), 3),
    );
  }

  void _fire(Canvas canvas) {
    final mouth = Offset(74, 54 + bob);
    canvas.drawOval(
      Rect.fromCenter(center: mouth, width: _mouthWidth, height: _mouthHeight),
      _fill(PacmanColors.cFF3E0A0A),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: mouth.translate(2, 1),
        width: _flameWidth,
        height: _flameHeight,
      ),
      _fill(PacmanColors.cFFFF7043),
    );
    for (var i = 0; i < 14; i++) {
      final phase = (t * 2 + i / 14) % 1;
      final x = mouth.dx + 4 + phase * 60;
      final y = mouth.dy + math.sin((phase + i) * 7) * 4 - phase * 7;
      final radius = 4 + phase * 12;
      final color = Color.lerp(
        PacmanColors.cFFFFEB3B,
        PacmanColors.cFFE53935,
        phase,
      )!.withValues(alpha: 1 - phase * 0.7);
      canvas.drawCircle(Offset(x, y), radius, _fill(color));
    }
  }

  @override
  bool shouldRepaint(_FrontPainter old) =>
      old.t != t || old.off != off || old.active != active;
}
