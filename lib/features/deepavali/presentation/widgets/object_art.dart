import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/diwali_palette.dart';

/// A Diwali object drawn as a flat vector. Unrevealed it is a single-colour
/// silhouette; revealed it shows its real colours. Decorative: callers label
/// the answer only after the guess.
class ObjectArt extends StatelessWidget {
  const ObjectArt({required this.id, required this.revealed, super.key});

  final String id;
  final bool revealed;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(painter: _ObjectPainter(id, revealed: revealed)),
      ),
    ),
  );
}

class _ObjectPainter extends CustomPainter {
  const _ObjectPainter(this.id, {required this.revealed});

  final String id;
  final bool revealed;

  // Painter-local drawing constants.
  static const Color _silhouette = DiwaliPalette.creamMuted;

  Color _c(Color real) => revealed ? real : _silhouette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    switch (id) {
      case 'diya':
        _diya(canvas, s);
      case 'rangoli':
        _rangoli(canvas, s);
      case 'lantern':
        _lantern(canvas, s);
      case 'laddu':
        _laddu(canvas, s);
      case 'sparkler':
        _sparkler(canvas, s);
      case 'garland':
        _garland(canvas, s);
      case 'thali':
        _thali(canvas, s);
      case 'rocket':
        _rocket(canvas, s);
    }
  }

  Paint _p(Color color) => Paint()..color = _c(color);

  void _diya(Canvas canvas, double s) {
    final bowl = Path()
      ..moveTo(s * 0.12, s * 0.58)
      ..quadraticBezierTo(s * 0.2, s * 0.9, s * 0.5, s * 0.9)
      ..quadraticBezierTo(s * 0.8, s * 0.9, s * 0.88, s * 0.58)
      ..close();
    canvas
      ..drawPath(bowl, _p(DiwaliPalette.orange))
      ..drawOval(
        Rect.fromLTRB(s * 0.12, s * 0.52, s * 0.88, s * 0.64),
        _p(DiwaliPalette.saffron),
      );
    final flame = Path()
      ..moveTo(s * 0.5, s * 0.54)
      ..cubicTo(s * 0.3, s * 0.4, s * 0.45, s * 0.25, s * 0.5, s * 0.08)
      ..cubicTo(s * 0.55, s * 0.25, s * 0.7, s * 0.4, s * 0.5, s * 0.54)
      ..close();
    canvas
      ..drawPath(flame, _p(DiwaliPalette.gold))
      ..drawPath(
        Path()
          ..moveTo(s * 0.5, s * 0.52)
          ..cubicTo(s * 0.42, s * 0.44, s * 0.48, s * 0.36, s * 0.5, s * 0.28)
          ..cubicTo(s * 0.52, s * 0.36, s * 0.58, s * 0.44, s * 0.5, s * 0.52)
          ..close(),
        _p(DiwaliPalette.flameCore),
      );
  }

  void _rangoli(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    const petals = 8;
    final colours = [
      DiwaliPalette.saffron,
      DiwaliPalette.gold,
      DiwaliPalette.error,
      DiwaliPalette.success,
    ];
    for (var i = 0; i < petals; i++) {
      final a = i * 2 * math.pi / petals;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * s * 0.3,
        s * 0.15,
        _p(colours[i % colours.length]),
      );
    }
    canvas
      ..drawCircle(c, s * 0.2, _p(DiwaliPalette.orange))
      ..drawCircle(c, s * 0.1, _p(DiwaliPalette.cream));
  }

  void _lantern(Canvas canvas, double s) {
    canvas
      ..drawLine(
        Offset(s * 0.5, s * 0.02),
        Offset(s * 0.5, s * 0.16),
        Paint()
          ..color = _c(DiwaliPalette.goldDeep)
          ..strokeWidth = s * 0.025,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(s * 0.28, s * 0.16, s * 0.72, s * 0.22),
          Radius.circular(s * 0.02),
        ),
        _p(DiwaliPalette.goldDeep),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(s * 0.22, s * 0.22, s * 0.78, s * 0.72),
          Radius.circular(s * 0.1),
        ),
        _p(DiwaliPalette.orange),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(s * 0.34, s * 0.3, s * 0.66, s * 0.64),
          Radius.circular(s * 0.07),
        ),
        _p(DiwaliPalette.flameCore),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(s * 0.28, s * 0.72, s * 0.72, s * 0.78),
          Radius.circular(s * 0.02),
        ),
        _p(DiwaliPalette.goldDeep),
      );
    for (final x in const [0.4, 0.5, 0.6]) {
      canvas.drawLine(
        Offset(s * x, s * 0.78),
        Offset(s * x, s * (x == 0.5 ? 0.96 : 0.9)),
        Paint()
          ..color = _c(DiwaliPalette.saffron)
          ..strokeWidth = s * 0.03,
      );
    }
  }

  void _laddu(Canvas canvas, double s) {
    final c = Offset(s / 2, s * 0.55);
    canvas.drawCircle(c, s * 0.34, _p(DiwaliPalette.saffron));
    if (!revealed) return;
    final dots = Paint()..color = DiwaliPalette.goldDeep;
    final rng = math.Random(3);
    for (var i = 0; i < 22; i++) {
      final a = rng.nextDouble() * 2 * math.pi;
      final r = rng.nextDouble() * s * 0.28;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r,
        s * 0.018,
        dots,
      );
    }
  }

  void _sparkler(Canvas canvas, double s) {
    canvas.drawLine(
      Offset(s * 0.5, s * 0.5),
      Offset(s * 0.5, s * 0.96),
      Paint()
        ..color = _c(DiwaliPalette.creamMuted)
        ..strokeWidth = s * 0.04
        ..strokeCap = StrokeCap.round,
    );
    final c = Offset(s / 2, s * 0.32);
    const rays = 14;
    final ray = Paint()
      ..color = _c(DiwaliPalette.gold)
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      final len = s * (i.isEven ? 0.26 : 0.17);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * s * 0.05,
        c + Offset(math.cos(a), math.sin(a)) * len,
        ray,
      );
    }
    canvas.drawCircle(c, s * 0.05, _p(DiwaliPalette.flameCore));
  }

  void _garland(Canvas canvas, double s) {
    const flowers = 9;
    for (var i = 0; i < flowers; i++) {
      final t = i / (flowers - 1);
      final c = Offset(
        s * (0.08 + 0.84 * t),
        s * (0.22 + 0.5 * math.sin(t * math.pi)),
      );
      for (var k = 0; k < 6; k++) {
        final a = k * math.pi / 3;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * s * 0.035,
          s * 0.04,
          _p(i.isEven ? DiwaliPalette.orange : DiwaliPalette.gold),
        );
      }
      canvas.drawCircle(c, s * 0.03, _p(DiwaliPalette.saffron));
    }
  }

  void _thali(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    canvas
      ..drawCircle(c, s * 0.46, _p(DiwaliPalette.goldDeep))
      ..drawCircle(c, s * 0.4, _p(DiwaliPalette.gold));
    final small = _p(DiwaliPalette.orange);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * s * 0.26,
        s * 0.065,
        small,
      );
    }
    canvas
      ..drawCircle(c, s * 0.12, _p(DiwaliPalette.orange))
      ..drawCircle(c, s * 0.05, _p(DiwaliPalette.flameCore));
  }

  void _rocket(Canvas canvas, double s) {
    canvas
      ..save()
      ..translate(s / 2, s / 2)
      ..rotate(math.pi / 5)
      ..translate(-s / 2, -s / 2);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(s * 0.4, s * 0.3, s * 0.6, s * 0.72),
      Radius.circular(s * 0.03),
    );
    canvas
      ..drawLine(
        Offset(s * 0.5, s * 0.72),
        Offset(s * 0.5, s * 0.98),
        Paint()
          ..color = _c(DiwaliPalette.creamMuted)
          ..strokeWidth = s * 0.03,
      )
      ..drawRRect(body, _p(DiwaliPalette.error))
      ..drawPath(
        Path()
          ..moveTo(s * 0.4, s * 0.3)
          ..lineTo(s * 0.5, s * 0.12)
          ..lineTo(s * 0.6, s * 0.3)
          ..close(),
        _p(DiwaliPalette.gold),
      )
      ..drawRect(
        Rect.fromLTRB(s * 0.4, s * 0.46, s * 0.6, s * 0.54),
        _p(DiwaliPalette.gold),
      )
      ..drawPath(
        Path()
          ..moveTo(s * 0.4, s * 0.72)
          ..lineTo(s * 0.3, s * 0.82)
          ..lineTo(s * 0.4, s * 0.62)
          ..close(),
        _p(DiwaliPalette.gold),
      )
      ..drawPath(
        Path()
          ..moveTo(s * 0.6, s * 0.72)
          ..lineTo(s * 0.7, s * 0.82)
          ..lineTo(s * 0.6, s * 0.62)
          ..close(),
        _p(DiwaliPalette.gold),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_ObjectPainter oldDelegate) =>
      oldDelegate.id != id || oldDelegate.revealed != revealed;
}
