import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/easter_eggs.dart';
import 'rajyotsava_motion.dart';

/// A collectible as a 3D trading card: drag to tilt it, tap to flip it.
/// The photo is only ever rotated, never stretched.
class CollectibleCard extends ConsumerStatefulWidget {
  const CollectibleCard({
    required this.collectible,
    required this.photo,
    this.width = AppSizes.collectibleCardMaxWidth,
    super.key,
  });

  final Collectible collectible;

  /// Asset path of its photo, or null for the category artwork.
  final String? photo;
  final double width;

  /// Trading-card proportion, width to height.
  static const double aspectRatio = 5 / 7;

  @override
  ConsumerState<CollectibleCard> createState() => _CollectibleCardState();
}

class _CollectibleCardState extends ConsumerState<CollectibleCard>
    with TickerProviderStateMixin {
  /// 0 shows the front, 1 the back.
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: AppDurations.flip,
  )..addStatusListener((_) => _updateSnapshot());

  /// While the card moves, its face is drawn once as a picture and the
  /// picture is turned. Turning live text makes the phone redraw every
  /// letter on every frame, at a new size; at rest the face is live again,
  /// so it stays sharp and the back can scroll.
  final SnapshotController _snapshot = SnapshotController();

  /// True from the first drag until the tilt has sprung back.
  var _dragging = false;

  void _updateSnapshot() {
    _snapshot.allowSnapshotting =
        _dragging || _flip.isAnimating || _spring.isAnimating;
  }

  /// Springs the tilt back to flat after a drag.
  late final AnimationController _spring =
      AnimationController(vsync: this, duration: AppDurations.medium)
        ..addStatusListener((_) => _updateSnapshot())
        ..addListener(
          () => setState(
            () => _tilt = Offset.lerp(
              _released,
              Offset.zero,
              Curves.easeOutBack.transform(_spring.value),
            )!,
          ),
        );

  /// Tilt in radians: dx turns around the vertical axis, dy around the
  /// horizontal one.
  Offset _tilt = Offset.zero;
  Offset _released = Offset.zero;

  static const double _maxTilt = 0.45;
  static const double _dragToRadians = 0.006;
  static const double _perspective = 0.0012;
  static const double _shadowBlur = 24;

  /// How far the shadow slides per radian of tilt.
  static const double _shadowShift = 30;

  @override
  void dispose() {
    _flip.dispose();
    _spring.dispose();
    _snapshot.dispose();
    super.dispose();
  }

  void _toggle() {
    ref.read(hapticsProvider).selection();
    if (reduceMotion(context)) {
      _flip.value = _flip.value < 0.5 ? 1 : 0;
    } else if (_flip.value < 0.5) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  void _drag(DragUpdateDetails d) {
    _spring.stop();
    _dragging = true;
    _updateSnapshot();
    setState(() {
      _tilt = Offset(
        (_tilt.dx + d.delta.dx * _dragToRadians).clamp(-_maxTilt, _maxTilt),
        (_tilt.dy - d.delta.dy * _dragToRadians).clamp(-_maxTilt, _maxTilt),
      );
    });
  }

  void _release(DragEndDetails _) {
    _released = _tilt;
    _dragging = false;
    _spring.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = width / CollectibleCard.aspectRatio;
    final back = _flip.value >= 0.5;
    return Semantics(
      button: true,
      label:
          '${widget.collectible.title} collectible card, '
          '${back ? 'back' : 'front'}. Double tap to flip.',
      child: GestureDetector(
        onTap: _toggle,
        onPanUpdate: _drag,
        onPanEnd: _release,
        child: AnimatedBuilder(
          animation: _flip,
          builder: (context, _) {
            final reduce = reduceMotion(context);
            // Eased, so the turn starts and lands softly.
            final flipAngle = reduce
                ? 0.0
                : Curves.easeInOutCubic.transform(_flip.value) * pi;
            final showBack = _flip.value >= 0.5;
            final face = showBack
                ? _CardBack(collectible: widget.collectible)
                : _CardFront(
                    collectible: widget.collectible,
                    photo: widget.photo,
                  );
            // Past edge-on the card turns from -90° back to 0° instead of on
            // to 180°: it looks the same, and the back is drawn the right
            // way round rather than through a costly mirror.
            final turn = showBack ? flipAngle - pi : flipAngle;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, _perspective)
              ..rotateX(_tilt.dy)
              ..rotateY(_tilt.dx + turn);
            // The shadow is drawn flat, outside the 3D transform: a blur
            // under perspective is recomputed every frame and made tilting
            // and flipping miss frames on a real phone. It narrows as the
            // card turns edge-on during a flip.
            final card = Transform(
              alignment: Alignment.center,
              transform: transform,
              // Draws the card flat into a texture and tilts the texture,
              // instead of drawing every clip and gradient through the 3D
              // perspective: much cheaper on the GPU.
              filterQuality: FilterQuality.medium,
              child: SizedBox(
                width: width,
                height: height,
                child: _CardFrame(
                  rarity: widget.collectible.rarity,
                  tilt: _tilt,
                  child: SnapshotWidget(
                    controller: _snapshot,
                    child: AnimatedSwitcher(
                      duration: reduce ? AppDurations.medium : Duration.zero,
                      child: KeyedSubtree(key: ValueKey(showBack), child: face),
                    ),
                  ),
                ),
              ),
            );
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(
                    -_tilt.dx * _shadowShift,
                    _tilt.dy * _shadowShift,
                  ),
                  child: Transform.scale(
                    scaleX: cos(flipAngle).abs(),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.lgAll,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.scrim,
                              blurRadius: _shadowBlur,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                card,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The card's foil border and moving shine.
class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.rarity,
    required this.tilt,
    required this.child,
  });

  final EggRarity rarity;
  final Offset tilt;
  final Widget child;

  static const double _border = 4;

  @override
  Widget build(BuildContext context) {
    final foil = rarity == EggRarity.legendary
        ? const [
            AppColors.kannadaYellow,
            AppColors.rangoliMarigold,
            AppColors.diwaliFlameCore,
            AppColors.rangoliMarigold,
          ]
        : const [
            AppColors.kannadaRed,
            AppColors.accentSaffron,
            AppColors.kannadaRed,
          ];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: foil,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_border),
        child: ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppColors.sectionSheet),
              child,
              // Glare that slides across as the card tilts.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + tilt.dx * 3, -1 - tilt.dy * 3),
                      end: Alignment(1 + tilt.dx * 3, 1 - tilt.dy * 3),
                      colors: [
                        AppColors.onBanner.withValues(alpha: 0),
                        AppColors.onBanner.withValues(alpha: AppOpacity.faint),
                        AppColors.onBanner.withValues(alpha: 0),
                      ],
                      stops: const [0.3, 0.5, 0.7],
                    ),
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

class _CardFront extends StatelessWidget {
  const _CardFront({required this.collectible, required this.photo});

  final Collectible collectible;
  final String? photo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = this.photo;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photo != null)
          Image.asset(
            photo,
            fit: BoxFit.cover,
            semanticLabel: 'Photo of ${collectible.title}',
            errorBuilder: (_, _, _) => _Artwork(category: collectible.category),
          )
        else
          _Artwork(category: collectible.category),
        // Darkens the bottom so the title reads over any photo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.ink.withValues(alpha: 0),
                AppColors.ink.withValues(alpha: AppOpacity.strong),
                AppColors.ink,
              ],
              stops: const [0.35, 0.7, 1],
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          // Both badges shrink (and truncate) on small cards with large
          // text instead of overflowing.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _Badge(
                  text: collectible.category.label,
                  background: AppColors.ink.withValues(
                    alpha: AppOpacity.strong,
                  ),
                  foreground: AppColors.onBanner,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: _Badge(
                  text: collectible.rarity.label,
                  background: collectible.rarity == EggRarity.legendary
                      ? AppColors.kannadaYellow
                      : AppColors.kannadaRed,
                  foreground: collectible.rarity == EggRarity.legendary
                      ? AppColors.ink
                      : AppColors.onBanner,
                  icon: collectible.rarity == EggRarity.legendary
                      ? Icons.auto_awesome
                      : Icons.star,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                collectible.kannadaTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.kannadaYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                collectible.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.onBanner,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                collectible.tagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onNightMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap to flip',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onNightMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.collectible});

  final Collectible collectible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = theme.textTheme.labelLarge?.copyWith(
      color: AppColors.kannadaYellow,
    );
    final body = theme.textTheme.bodySmall?.copyWith(color: AppColors.onNight);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bannerTop, AppColors.sectionBottom],
        ),
      ),
      // Scrolls, so long text and large text sizes always fit.
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            collectible.kannadaTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.kannadaYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            collectible.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.onBanner,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(collectible.kannadaDescription, style: body),
          const SizedBox(height: AppSpacing.xs),
          Text(
            collectible.englishDescription,
            style: body?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('History', style: heading),
          Text(collectible.history, style: body),
          const SizedBox(height: AppSpacing.md),
          Text('Facts', style: heading),
          for (final fact in collectible.facts)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.star,
                    size: AppIconSizes.xs,
                    color: AppColors.kannadaYellow,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(fact, style: body)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text('Why it matters', style: heading),
          Text(collectible.importance, style: body),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: background, borderRadius: AppRadius.lgAll),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSizes.xs, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: foreground, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Category artwork when a collectible has no photo.
class _Artwork extends StatelessWidget {
  const _Artwork({required this.category});

  final EggCategory category;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.bannerTop, AppColors.sectionBottom],
      ),
    ),
    child: Center(
      child: Icon(
        switch (category) {
          EggCategory.personality => Icons.person,
          EggCategory.place => Icons.account_balance,
          EggCategory.culture => Icons.theater_comedy,
          EggCategory.nature => Icons.landscape,
        },
        size: AppIconSizes.hero,
        color: AppColors.kannadaYellow,
      ),
    ),
  );
}
