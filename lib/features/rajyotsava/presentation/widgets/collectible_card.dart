import 'dart:math';
import 'dart:ui' show ImageFilter;

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

  /// A legendary subject rising out of the frame, once the card has landed.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: _popDelay + AppDurations.entrance,
  )..addListener(_popHaptic);
  static const Duration _popDelay = AppDurations.slow;
  late final Animation<double> _popCurve = CurvedAnimation(
    parent: _pop,
    curve: Interval(
      _popDelay.inMilliseconds /
          (_popDelay + AppDurations.entrance).inMilliseconds,
      1,
      curve: Curves.easeOutBack,
    ),
  );
  var _popped = false;

  void _popHaptic() {
    if (_popped || _popCurve.value <= 0) return;
    _popped = true;
    ref.read(hapticsProvider).tap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.collectible.popOut == null || !_pop.isDismissed) return;
    if (reduceMotion(context)) {
      _popped = true;
      _pop.value = 1;
    } else {
      _pop.forward();
    }
  }

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
    _pop.dispose();
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
          animation: Listenable.merge([_flip, _popCurve]),
          builder: (context, _) {
            final reduce = reduceMotion(context);
            // Eased, so the turn starts and lands softly.
            final flipAngle = reduce
                ? 0.0
                : Curves.easeInOutCubic.transform(_flip.value) * pi;
            final showBack = _flip.value >= 0.5;
            final popOut = widget.collectible.popOut;
            final face = showBack
                ? _CardBack(collectible: widget.collectible)
                : _CardFront(
                    collectible: widget.collectible,
                    photo: widget.photo,
                    // The photo softens as the subject rises out of it.
                    focus: popOut == null ? 0 : _popCurve.value,
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
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: _CardFrame(
                        rarity: widget.collectible.rarity,
                        tilt: _tilt,
                        child: SnapshotWidget(
                          controller: _snapshot,
                          child: AnimatedSwitcher(
                            duration: reduce
                                ? AppDurations.medium
                                : Duration.zero,
                            child: KeyedSubtree(
                              key: ValueKey(showBack),
                              child: face,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (popOut != null && !showBack)
                      Positioned.fill(
                        child: _PopOutLayer(
                          popOut: popOut,
                          progress: _popCurve.value,
                          tilt: _tilt,
                        ),
                      ),
                    if (!showBack)
                      Positioned(
                        top: _CardFrame.border + AppSpacing.sm,
                        left: _CardFrame.border + AppSpacing.sm,
                        right: _CardFrame.border + AppSpacing.sm,
                        child: _CardBadges(collectible: widget.collectible),
                      ),
                  ],
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

  /// Width of the foil border around the face.
  static const double border = 4;

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
        padding: const EdgeInsets.all(border),
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
  const _CardFront({
    required this.collectible,
    required this.photo,
    this.focus = 0,
  });

  final Collectible collectible;
  final String? photo;

  /// 0 shows the photo sharp; towards 1 it blurs, so a subject popping out
  /// of it stands out and its copy left in the photo reads as background.
  final double focus;

  /// Blur of the photo behind a popped-out subject.
  static const double _backgroundBlur = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = this.photo;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photo != null)
          ImageFiltered(
            enabled: focus > 0,
            imageFilter: ImageFilter.blur(
              sigmaX: _backgroundBlur * focus.clamp(0, 1),
              sigmaY: _backgroundBlur * focus.clamp(0, 1),
              tileMode: TileMode.clamp,
            ),
            child: Image.asset(
              photo,
              fit: BoxFit.cover,
              semanticLabel: 'Photo of ${collectible.title}',
              errorBuilder: (_, _, _) =>
                  _Artwork(category: collectible.category),
            ),
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

/// The category and rarity badges. They sit above a pop-out, so a subject
/// rising out of the frame never covers them.
class _CardBadges extends StatelessWidget {
  const _CardBadges({required this.collectible});

  final Collectible collectible;

  @override
  Widget build(BuildContext context) =>
      // Both badges shrink (and truncate) on small cards with large text
      // instead of overflowing.
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: _Badge(
              text: collectible.category.label,
              background: AppColors.ink.withValues(alpha: AppOpacity.strong),
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
      );
}

/// A legendary card's subject, cut out of its photo, rising out of the top
/// of the frame as [progress] goes from 0 to 1. Laid out exactly like the
/// photo (same box, same cover fit), so at 0 it sits on its own image.
/// Above the frame it is free; at the sides and bottom it stays inside,
/// and its lower part fades into the photo so no edge shows.
class _PopOutLayer extends StatelessWidget {
  const _PopOutLayer({
    required this.popOut,
    required this.progress,
    required this.tilt,
  });

  final PopOut popOut;
  final double progress;
  final Offset tilt;

  /// How much bigger the subject grows as it comes forward.
  static const double _grow = 0.1;

  /// How far above the frame the top of the subject ends up, as a share of
  /// the card's height.
  static const double _clearance = 0.08;

  /// Pixels the subject slides per radian of tilt, more than the card, so
  /// it looks nearer.
  static const double _parallax = 16;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.all(_CardFrame.border),
          child: LayoutBuilder(
            builder: (context, box) {
              final h = box.maxHeight;
              final scale = 1 + _grow * p;
              // Rise just enough for the (grown) subject's top to clear
              // the frame by the clearance.
              final rise = max(
                0.0,
                1 - (1 - popOut.subjectTop) * (1 + _grow) + _clearance,
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // The photo behind falls back a little, for depth.
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: AppRadius.mdAll,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.ink.withValues(
                                alpha: AppOpacity.strong * p,
                              ),
                              AppColors.ink.withValues(alpha: 0),
                            ],
                            stops: const [0, 0.75],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      clipper: const _OpenTop(),
                      child: Transform.translate(
                        offset: Offset(
                          tilt.dx * _parallax * p,
                          -rise * h * p - tilt.dy * _parallax * p,
                        ),
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.bottomCenter,
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.onBanner,
                                AppColors.onBanner,
                                AppColors.transparent,
                              ],
                              stops: [0, 0.55, 0.85],
                            ).createShader(rect),
                            child: Image.asset(
                              popOut.asset,
                              fit: BoxFit.cover,
                              width: box.maxWidth,
                              height: h,
                              errorBuilder: (_, _, _) => const SizedBox(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Clips to the box's sides and bottom but leaves the top open, so a
/// subject can rise above the frame.
class _OpenTop extends CustomClipper<Rect> {
  const _OpenTop();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -size.height, size.width, size.height);

  @override
  bool shouldReclip(_OpenTop oldClipper) => false;
}
