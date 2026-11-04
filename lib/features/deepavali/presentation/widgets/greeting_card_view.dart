import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/greeting.dart';
import '../theme/diwali_palette.dart';
import '../theme/greeting_styles.dart';
import '../theme/rangoli_palette.dart';
import 'diya_art.dart';

/// The greeting card, 4:5. It is a picture: its text does not follow the
/// phone's text size (it is shared as an image), and it fits any message by
/// scaling down. Screen readers get the whole card as one summary.
class GreetingCardView extends StatelessWidget {
  const GreetingCardView({required this.card, super.key});

  final GreetingCard card;

  // Layout, as fractions of the card width / height.
  static const double aspect = 4 / 5;
  static const double _sidePad = 0.1;
  static const double _topPad = 0.24;
  static const double _bottomPad = 0.27;
  static const double _titleScale = 0.085;
  static const double _bodyScale = 0.052;
  static const double _gap = 0.03;
  static const double _ornamentWidth = 0.4;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspect,
    child: Semantics(
      label: card.summary,
      image: true,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            final style = GreetingStyles.of(card.design);
            final text = Theme.of(context).textTheme;
            return MediaQuery.withNoTextScaling(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GreetingBackground(design: card.design),
                  ),
                  if (card.design == GreetingDesign.goldenDiyas)
                    Positioned(
                      left: w * _sidePad,
                      right: w * _sidePad,
                      bottom: h * 0.05,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final scale in const [0.8, 1.0, 0.8])
                            DiyaArt(width: w * 0.2 * scale, ignite: 1),
                        ],
                      ),
                    ),
                  Positioned(
                    left: w * _sidePad,
                    right: w * _sidePad,
                    top: h * _topPad,
                    bottom: h * _bottomPad,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: w * (1 - 2 * _sidePad),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Happy Deepavali!',
                              textAlign: TextAlign.center,
                              style: text.headlineSmall?.copyWith(
                                fontSize: w * _titleScale,
                                fontWeight: FontWeight.w700,
                                color: style.title,
                              ),
                            ),
                            if (card.hasMessage) ...[
                              SizedBox(height: w * _gap),
                              _Ornament(
                                color: style.accent,
                                width: w * _ornamentWidth,
                              ),
                              SizedBox(height: w * _gap),
                              Text(
                                card.message,
                                textAlign: TextAlign.center,
                                style: text.bodyLarge?.copyWith(
                                  fontSize: w * _bodyScale,
                                  color: style.body,
                                ),
                              ),
                            ],
                            if (card.hasFrom) ...[
                              SizedBox(height: w * _gap),
                              Text(
                                '— ${card.from}',
                                textAlign: TextAlign.center,
                                style: text.bodyLarge?.copyWith(
                                  fontSize: w * _bodyScale,
                                  fontStyle: FontStyle.italic,
                                  color: style.accent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// Just the artwork of a design (no words). Also used for the small design
/// pickers.
class GreetingBackground extends StatelessWidget {
  const GreetingBackground({required this.design, super.key});

  final GreetingDesign design;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: GreetingPainter(design),
      child: const SizedBox.expand(),
    ),
  );
}

class GreetingPainter extends CustomPainter {
  const GreetingPainter(this.design);

  final GreetingDesign design;

  // Painter-local geometry (fractions of the card width unless noted).
  static const double _frame = 0.04;
  static const double _stroke = 0.006;
  static const double _starMinAlpha = 0.3;
  static const double _starAlphaSpan = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    final style = GreetingStyles.of(design);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: style.background,
        ).createShader(rect),
    );
    switch (design) {
      case GreetingDesign.goldenDiyas:
        _frameLine(canvas, size, style.title);
        _sparkles(canvas, size, style.title);
      case GreetingDesign.rangoliBorder:
        _rangoliBorder(canvas, size);
      case GreetingDesign.nightLanterns:
        _stars(canvas, size, style.body);
        _lanterns(canvas, size, style);
      case GreetingDesign.marigoldGarland:
        _garland(canvas, size);
    }
  }

  void _frameLine(Canvas canvas, Size size, Color color) {
    final inset = size.width * _frame;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          inset,
          inset,
          size.width - 2 * inset,
          size.height - 2 * inset,
        ),
        Radius.circular(inset),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * _stroke
        ..color = color.withValues(alpha: AppOpacity.strong),
    );
  }

  /// A few fixed twinkles: the same card every time.
  void _sparkles(Canvas canvas, Size size, Color color) {
    final p = Paint()..color = color.withValues(alpha: AppOpacity.strong);
    const spots = [
      Offset(0.18, 0.12),
      Offset(0.82, 0.1),
      Offset(0.5, 0.07),
      Offset(0.1, 0.5),
      Offset(0.9, 0.55),
    ];
    for (var i = 0; i < spots.length; i++) {
      final r = size.width * (i.isEven ? 0.012 : 0.008);
      canvas.drawCircle(
        Offset(spots[i].dx * size.width, spots[i].dy * size.height),
        r,
        p,
      );
    }
  }

  void _rangoliBorder(Canvas canvas, Size size) {
    final w = size.width;
    final colours = [for (final c in RangoliPalette.colours) c.color];
    final ring = Paint();
    // Dots all round the edge, cycling through the eight festival colours.
    const perSide = 9;
    final inset = w * _frame * 1.4;
    final dot = w * 0.016;
    var n = 0;
    void put(double x, double y) {
      ring.color = colours[n % colours.length];
      canvas.drawCircle(Offset(x, y), dot, ring);
      n++;
    }

    for (var i = 0; i < perSide; i++) {
      final t = i / (perSide - 1);
      put(inset + t * (w - 2 * inset), inset);
    }
    final rows = (perSide * size.height / w).round();
    for (var i = 1; i < rows; i++) {
      put(w - inset, inset + i / rows * (size.height - 2 * inset));
    }
    for (var i = 0; i < perSide; i++) {
      final t = i / (perSide - 1);
      put(w - inset - t * (w - 2 * inset), size.height - inset);
    }
    for (var i = rows - 1; i > 0; i--) {
      put(inset, inset + i / rows * (size.height - 2 * inset));
    }
    // A small mandala at the top and bottom.
    _mandala(canvas, Offset(w / 2, size.height * 0.13), w * 0.075, colours);
    _mandala(canvas, Offset(w / 2, size.height * 0.87), w * 0.075, colours);
  }

  void _mandala(Canvas canvas, Offset c, double r, List<Color> colours) {
    final p = Paint();
    for (var ring = 3; ring >= 0; ring--) {
      p.color = colours[(ring * 2) % colours.length];
      canvas.drawCircle(c, r * (ring + 1) / 4, p);
    }
    const petals = 8;
    for (var i = 0; i < petals; i++) {
      final a = i * 2 * math.pi / petals;
      p.color = colours[(i + 1) % colours.length];
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 1.25,
        r * 0.2,
        p,
      );
    }
  }

  void _stars(Canvas canvas, Size size, Color color) {
    final p = Paint();
    final rng = math.Random(7); // fixed seed: the same sky every time
    for (var i = 0; i < 40; i++) {
      p.color = color.withValues(
        alpha: _starMinAlpha + rng.nextDouble() * _starAlphaSpan,
      );
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        size.width * (0.002 + rng.nextDouble() * 0.004),
        p,
      );
    }
  }

  void _lanterns(Canvas canvas, Size size, GreetingStyle style) {
    final w = size.width;
    const xs = [0.22, 0.5, 0.78];
    const drops = [0.1, 0.06, 0.12];
    for (var i = 0; i < xs.length; i++) {
      final x = xs[i] * w;
      final bottom = (drops[i] + 0.1) * size.height;
      final body = Rect.fromCenter(
        center: Offset(x, bottom - w * 0.045),
        width: w * 0.12,
        height: w * 0.09,
      );
      canvas
        ..drawLine(
          Offset(x, 0),
          Offset(x, body.top),
          Paint()
            ..color = style.accent
            ..strokeWidth = w * _stroke,
        )
        ..drawCircle(
          body.center,
          w * 0.11,
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    DiwaliPalette.flameCore.withValues(alpha: AppOpacity.glow),
                    DiwaliPalette.flameCore.withValues(alpha: 0),
                  ],
                ).createShader(
                  Rect.fromCircle(center: body.center, radius: w * 0.11),
                ),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(body, Radius.circular(w * 0.03)),
          Paint()..color = i.isEven ? style.accent : DiwaliPalette.gold,
        )
        ..drawRect(
          Rect.fromLTWH(
            body.left - w * 0.01,
            body.top - w * 0.01,
            body.width + w * 0.02,
            w * 0.014,
          ),
          Paint()..color = DiwaliPalette.goldDeep,
        )
        ..drawRect(
          Rect.fromLTWH(
            body.left - w * 0.01,
            body.bottom,
            body.width + w * 0.02,
            w * 0.014,
          ),
          Paint()..color = DiwaliPalette.goldDeep,
        );
    }
  }

  void _garland(Canvas canvas, Size size) {
    final w = size.width;
    // Two sagging garlands across the top and one along the bottom.
    void strand(Offset a, Offset b, double sag) {
      const flowers = 13;
      for (var i = 0; i < flowers; i++) {
        final t = i / (flowers - 1);
        final x = a.dx + (b.dx - a.dx) * t;
        final y = a.dy + (b.dy - a.dy) * t + math.sin(t * math.pi) * sag;
        _marigold(canvas, Offset(x, y), w * 0.03, i.isEven);
      }
    }

    strand(Offset(0, w * 0.05), Offset(w, w * 0.05), w * 0.1);
    strand(Offset(0, w * 0.02), Offset(w, w * 0.02), w * 0.18);
    strand(
      Offset(0, size.height - w * 0.06),
      Offset(w, size.height - w * 0.06),
      -w * 0.08,
    );
  }

  void _marigold(Canvas canvas, Offset c, double r, bool deep) {
    final petals = Paint()
      ..color = deep ? DiwaliPalette.orange : DiwaliPalette.gold;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.55,
        r * 0.5,
        petals,
      );
    }
    canvas.drawCircle(c, r * 0.4, Paint()..color = DiwaliPalette.saffron);
  }

  @override
  bool shouldRepaint(GreetingPainter oldDelegate) =>
      oldDelegate.design != design;
}

/// A thin line with a diamond in the middle, set between title and message.
class _Ornament extends StatelessWidget {
  const _Ornament({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: CustomPaint(
      painter: _OrnamentPainter(color),
      child: SizedBox(height: width * _OrnamentPainter._heightRatio),
    ),
  );
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter(this.color);

  final Color color;

  static const double _heightRatio = 0.08;
  static const double _gapRatio = 0.06;
  static const double _stroke = 0.012;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.center(Offset.zero);
    final gap = size.width * _gapRatio;
    final line = Paint()
      ..color = color.withValues(alpha: AppOpacity.strong)
      ..strokeWidth = size.width * _stroke;
    canvas
      ..drawLine(Offset(0, mid.dy), Offset(mid.dx - gap, mid.dy), line)
      ..drawLine(Offset(mid.dx + gap, mid.dy), Offset(size.width, mid.dy), line)
      ..drawPath(
        Path()
          ..moveTo(mid.dx, mid.dy - gap * 0.7)
          ..lineTo(mid.dx + gap * 0.7, mid.dy)
          ..lineTo(mid.dx, mid.dy + gap * 0.7)
          ..lineTo(mid.dx - gap * 0.7, mid.dy)
          ..close(),
        Paint()..color = color,
      );
  }

  @override
  bool shouldRepaint(_OrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}
