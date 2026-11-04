import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../theme/diwali_palette.dart';

/// Thin gold rule with a centred diamond. Purely decorative.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});

  static const double _height = 16;

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: SizedBox(
      height: _height,
      width: double.infinity,
      child: CustomPaint(painter: _OrnamentPainter()),
    ),
  );
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter();

  // Painter-local geometry.
  static const double _gap = 14;
  static const double _gem = 6;
  static const double _stroke = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final cx = size.width / 2;
    final line = Paint()
      ..shader = LinearGradient(
        colors: [
          DiwaliPalette.gold.withValues(alpha: 0),
          DiwaliPalette.gold.withValues(alpha: AppOpacity.strong),
        ],
      ).createShader(Rect.fromLTWH(0, 0, cx - _gap, _stroke))
      ..strokeWidth = _stroke;
    canvas.drawLine(Offset(0, cy), Offset(cx - _gap, cy), line);
    final right = Paint()
      ..shader = LinearGradient(
        colors: [
          DiwaliPalette.gold.withValues(alpha: AppOpacity.strong),
          DiwaliPalette.gold.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(cx + _gap, 0, cx - _gap, _stroke))
      ..strokeWidth = _stroke;
    canvas.drawLine(Offset(cx + _gap, cy), Offset(size.width, cy), right);
    final gem = Path()
      ..moveTo(cx, cy - _gem)
      ..lineTo(cx + _gem, cy)
      ..lineTo(cx, cy + _gem)
      ..lineTo(cx - _gem, cy)
      ..close();
    canvas.drawPath(gem, Paint()..color = DiwaliPalette.gold);
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) => false;
}
