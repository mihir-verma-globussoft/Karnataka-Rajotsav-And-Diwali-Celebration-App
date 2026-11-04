import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/ar_scene.dart';
import '../../domain/hunt_models.dart';

/// The night-sky gradient behind the screens without a camera.
class NightBackground extends StatelessWidget {
  const NightBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.diwaliNight,
          AppColors.diwaliPlum,
          AppColors.diwaliMaroon,
        ],
      ),
    ),
    child: child,
  );
}

/// A card on the night gradient.
class HuntCard extends StatelessWidget {
  const HuntCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppRadius.lgAll,
      border: Border.all(
        color: AppColors.diwaliGold.withValues(alpha: AppOpacity.border),
      ),
    ),
    child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
  );
}

/// A panel over the live camera, dark enough to read over any picture.
class ArPanel extends StatelessWidget {
  const ArPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.arPanel,
      borderRadius: AppRadius.lgAll,
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.onArPanel),
        child: child,
      ),
    ),
  );
}

/// A small icon-and-text label over the camera.
class ArChip extends StatelessWidget {
  const ArChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.arPanel,
      borderRadius: AppRadius.xlAll,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs + AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSizes.xs, color: AppColors.diwaliGold),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: AppColors.onArPanel),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A short note over the camera, announced to screen readers.
class ArMessageBanner extends StatelessWidget {
  const ArMessageBanner({required this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppDurations.fast,
    child: message == null
        ? const SizedBox.shrink()
        : Padding(
            key: ValueKey(message),
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Semantics(
              liveRegion: true,
              child: ArPanel(
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: AppColors.onArPanel),
                ),
              ),
            ),
          ),
  );
}

/// What to do when tracking is struggling; null when all is well.
String? trackingHint(ArTracking tracking) => switch (tracking) {
  ArTracking.normal => null,
  ArTracking.initializing => 'Move your phone slowly to get started.',
  ArTracking.tooFast => 'Slow down a little.',
  ArTracking.tooDark => 'It is too dark here. Find some more light.',
  ArTracking.lowDetail => 'Point at something with more detail.',
  ArTracking.unavailable => 'Trying to find where you are…',
};

/// The screen before a poster is locked on: shows what to look for.
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({
    required this.progress,
    required this.tooFar,
    required this.tracking,
    required this.title,
    super.key,
  });

  final double progress;
  final bool tooFar;
  final ArTracking tracking;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locking = progress > 0;
    final String instruction;
    if (tooFar) {
      instruction = 'Move closer to the poster.';
    } else if (locking) {
      instruction = 'Hold steady…';
    } else {
      instruction =
          trackingHint(tracking) ?? 'Point your camera at a Habba Hunt poster.';
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: math.min(
                  AppSizes.arViewfinder,
                  constraints.maxWidth * 0.6,
                ),
                child: CustomPaint(painter: _ViewfinderPainter(progress)),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ArPanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          instruction,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.onArPanel,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.onArPanel,
                        ),
                      ),
                      if (locking) ...[
                        const SizedBox(height: AppSpacing.sm),
                        LinearProgressIndicator(
                          value: progress,
                          borderRadius: AppRadius.xsAll,
                          minHeight: AppSizes.progressBar,
                        ),
                      ] else ...[
                        const SizedBox(height: AppSpacing.sm),
                        ExcludeSemantics(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final zone in huntZones)
                                PosterThumb(zone: zone),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const corner = AppSizes.arViewfinderCorner;
    final paint = Paint()
      ..color = progress > 0 ? AppColors.diwaliSuccess : AppColors.diwaliGold
      ..strokeWidth = AppSizes.arViewfinderStroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, corner)
        ..lineTo(0, 0)
        ..lineTo(corner, 0)
        ..moveTo(w - corner, 0)
        ..lineTo(w, 0)
        ..lineTo(w, corner)
        ..moveTo(w, h - corner)
        ..lineTo(w, h)
        ..lineTo(w - corner, h)
        ..moveTo(corner, h)
        ..lineTo(0, h)
        ..lineTo(0, h - corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) => old.progress != progress;
}

class PosterThumb extends StatelessWidget {
  const PosterThumb({required this.zone, super.key});

  final HuntZone zone;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.smAll,
    child: Image.asset(
      zone.posterAsset,
      width: AppSizes.arPosterThumb,
      height: AppSizes.arPosterThumb,
      cacheWidth: AppSizes.photoDecodeWidth,
      fit: BoxFit.cover,
      semanticLabel: 'Poster for ${zone.label}',
    ),
  );
}

/// A little painted diya or Kannada flag.
class HuntItemArt extends StatelessWidget {
  const HuntItemArt(this.kind, {this.size = AppIconSizes.lg, super.key});

  final HuntItemKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: kind.label,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ItemArtPainter(kind)),
    ),
  );
}

class _ItemArtPainter extends CustomPainter {
  const _ItemArtPainter(this.kind);

  final HuntItemKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width, size.height);
    switch (kind) {
      case HuntItemKind.diya:
        final flame = Path()
          ..moveTo(0.5, 0.08)
          ..quadraticBezierTo(0.72, 0.38, 0.5, 0.55)
          ..quadraticBezierTo(0.28, 0.38, 0.5, 0.08);
        canvas
          ..drawPath(flame, Paint()..color = AppColors.diwaliOrange)
          ..drawOval(
            const Rect.fromLTRB(0.42, 0.3, 0.58, 0.55),
            Paint()..color = AppColors.diwaliFlameCore,
          )
          ..drawPath(
            Path()
              ..moveTo(0.1, 0.55)
              ..quadraticBezierTo(0.5, 0.65, 0.9, 0.55)
              ..quadraticBezierTo(0.8, 0.92, 0.5, 0.92)
              ..quadraticBezierTo(0.2, 0.92, 0.1, 0.55),
            Paint()..color = AppColors.arClay,
          );
      case HuntItemKind.flag:
        canvas
          ..drawRect(
            const Rect.fromLTRB(0.14, 0.08, 0.2, 0.94),
            Paint()..color = AppColors.diwaliGoldDeep,
          )
          ..drawRect(
            const Rect.fromLTRB(0.2, 0.12, 0.9, 0.34),
            Paint()..color = AppColors.kannadaYellow,
          )
          ..drawRect(
            const Rect.fromLTRB(0.2, 0.34, 0.9, 0.56),
            Paint()..color = AppColors.kannadaRed,
          );
    }
  }

  @override
  bool shouldRepaint(_ItemArtPainter old) => old.kind != kind;
}

/// One line on the leaderboard.
class HuntLeaderRow extends StatelessWidget {
  const HuntLeaderRow({required this.leader, required this.isYou, super.key});

  final HuntLeader leader;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = leader.avatarUrl;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isYou
            ? theme.colorScheme.primary.withValues(alpha: AppOpacity.faint)
            : AppColors.transparent,
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSizes.minTouchTarget,
              ),
              child: Text(
                '#${leader.rank}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            CircleAvatar(
              foregroundImage: avatar == null ? null : NetworkImage(avatar),
              onForegroundImageError: avatar == null ? null : (_, _) {},
              child: Text(
                leader.username.isEmpty
                    ? '?'
                    : leader.username[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isYou ? '${leader.username} (you)' : leader.username,
                    style: theme.textTheme.bodyLarge,
                  ),
                  Text(
                    '${leader.points} pts',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
