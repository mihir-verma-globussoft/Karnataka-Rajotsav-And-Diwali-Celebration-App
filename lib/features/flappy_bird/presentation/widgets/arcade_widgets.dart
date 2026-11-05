import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/arcade_tokens.dart';

export '../../../../core/theme/arcade_tokens.dart';

class ArcadeBackground extends StatelessWidget {
  const ArcadeBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Stack(fit: StackFit.expand, children: [const DiwaliBackdrop(), child]);
}

/// A consistent, accessible navigation treatment for the full-screen arcade
/// destinations. Keeping this here prevents the profile, settings, and
/// leaderboard from drifting into separate header styles.
class ArcadeNavigationHeader extends StatelessWidget {
  const ArcadeNavigationHeader({
    required this.title,
    required this.highlight,
    required this.onBack,
    super.key,
  });

  final String title;
  final String highlight;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall
        ?.copyWith(color: FlappyPalette.white, fontWeight: FontWeight.w800);
    return Semantics(
      header: true,
      child: Row(
        children: [
          SizedBox.square(
            dimension: AppSizes.minTouchTarget,
            child: IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: FlappyPalette.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: title,
                style: titleStyle,
                children: [
                  TextSpan(
                    text: highlight,
                    style: titleStyle?.copyWith(
                      color: FlappyPalette.festivalGold,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class DiwaliBackdrop extends StatelessWidget {
  const DiwaliBackdrop({this.showGround = true, super.key});

  final bool showGround;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(painter: _DiwaliBackdropPainter(showGround)),
  );
}

class _DiwaliBackdropPainter extends CustomPainter {
  const _DiwaliBackdropPainter(this.showGround);

  final bool showGround;

  static const _stars = <Offset>[
    Offset(.08, .10),
    Offset(.18, .23),
    Offset(.29, .08),
    Offset(.43, .19),
    Offset(.56, .07),
    Offset(.68, .25),
    Offset(.78, .11),
    Offset(.91, .21),
    Offset(.12, .39),
    Offset(.38, .34),
    Offset(.61, .42),
    Offset(.86, .36),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [FlappyPalette.midnight, FlappyPalette.sky, FlappyPalette.dusk],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    for (var index = 0; index < _stars.length; index++) {
      final point = _stars[index];
      canvas.drawCircle(
        Offset(point.dx * size.width, point.dy * size.height),
        index.isEven ? 1.8 : 1.1,
        Paint()
          ..color = FlappyPalette.white.withValues(alpha: ArcadeOpacity.stars),
      );
    }

    _firework(
      canvas,
      Offset(size.width * .20, size.height * .23),
      size.shortestSide * .09,
      FlappyPalette.festivalGold,
    );
    _firework(
      canvas,
      Offset(size.width * .78, size.height * .18),
      size.shortestSide * .075,
      FlappyPalette.sparkPink,
    );
    _firework(
      canvas,
      Offset(size.width * .58, size.height * .36),
      size.shortestSide * .05,
      FlappyPalette.sparkCyan,
    );

    if (!showGround) return;
    final groundTop = size.height * .84;
    canvas.drawRect(
      Rect.fromLTRB(0, groundTop, size.width, size.height),
      Paint()..color = FlappyPalette.ink.withValues(alpha: ArcadeOpacity.panel),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, groundTop, size.width, groundTop + 5),
      Paint()..color = FlappyPalette.festivalGold,
    );
    final spacing = (size.width / 7).clamp(42.0, 76.0);
    for (double x = spacing / 2; x < size.width; x += spacing) {
      _diya(canvas, Offset(x, groundTop + 20));
    }
  }

  void _firework(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: ArcadeOpacity.scrim)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 12; index++) {
      final angle = index * 3.141592653589793 * 2 / 12;
      final direction = Offset(_cos(angle), _sin(angle));
      canvas.drawLine(
        center + direction * radius * .35,
        center + direction * radius,
        paint,
      );
      canvas.drawCircle(center + direction * radius, 1.8, paint);
    }
  }

  void _diya(Canvas canvas, Offset center) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: ArcadeSizes.diyaWidth,
        height: ArcadeSizes.diyaHeight,
      ),
      Paint()..color = FlappyPalette.saffron,
    );
    final flame = Path()
      ..moveTo(center.dx, center.dy - 5)
      ..quadraticBezierTo(
        center.dx - 7,
        center.dy - 15,
        center.dx,
        center.dy - 24,
      )
      ..quadraticBezierTo(
        center.dx + 7,
        center.dy - 15,
        center.dx,
        center.dy - 5,
      )
      ..close();
    canvas.drawPath(flame, Paint()..color = FlappyPalette.festivalGold);
  }

  // Compact deterministic approximations are sufficient for decorative rays.
  double _sin(double value) => switch (value) {
    < 0.01 => 0,
    < 0.53 => .5,
    < 1.05 => .866,
    < 1.58 => 1,
    < 2.10 => .866,
    < 2.62 => .5,
    < 3.15 => 0,
    < 3.67 => -.5,
    < 4.20 => -.866,
    < 4.72 => -1,
    < 5.25 => -.866,
    < 5.77 => -.5,
    _ => 0,
  };

  double _cos(double value) =>
      _sin((value + 1.5707963267948966) % 6.283185307179586);

  @override
  bool shouldRepaint(covariant _DiwaliBackdropPainter oldDelegate) =>
      oldDelegate.showGround != showGround;
}

class ArcadePanel extends StatelessWidget {
  const ArcadePanel({
    required this.child,
    this.padding,
    this.border,
    this.backgroundColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final color =
        backgroundColor ??
        Theme.of(context).colorScheme.surface
            .withValues(alpha: ArcadeOpacity.card);
    return Material(
      color: color,
      elevation: ArcadeSizes.panelElevation,
      borderRadius: AppRadius.lgAll,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          border: border,
        ),
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    required this.username,
    this.avatarUrl,
    this.radius = 24,
    super.key,
  });

  final String username;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$username profile picture',
    image: true,
    child: CircleAvatar(
      radius: radius,
      foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
      onForegroundImageError: avatarUrl == null ? null : (_, _) {},
      child: Text(
        username.isEmpty ? '?' : username.characters.first.toUpperCase(),
      ),
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlighted = false,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = highlighted
        ? FlappyPalette.festivalGold
        : theme.colorScheme.primary;

    return ArcadePanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      border: highlighted
          ? Border.all(
              color: FlappyPalette.festivalGold,
              width: ArcadeSizes.goldBorder,
            )
          : Border.all(
              color: FlappyPalette.white.withValues(
                alpha: ArcadeOpacity.hairline,
              ),
              width: ArcadeSizes.hairline,
            ),
      backgroundColor: highlighted
          ? FlappyPalette.selectedSurface.withValues(
              alpha: ArcadeOpacity.selected,
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primaryColor, size: ArcadeSizes.statIcon),
          const SizedBox(height: ArcadeSizes.tightGap),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: highlighted ? FlappyPalette.festivalGold : null,
            ),
          ),
          const SizedBox(height: ArcadeSizes.tightGap),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: highlighted
                  ? FlappyPalette.festivalGold.withValues(
                      alpha: ArcadeOpacity.selected,
                    )
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ArcadeActionButton extends StatelessWidget {
  const ArcadeActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.primary = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label)),
      ],
    );
    return SizedBox(
      width: double.infinity,
      child: primary
          ? FilledButton(onPressed: onPressed, child: child)
          : OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}
