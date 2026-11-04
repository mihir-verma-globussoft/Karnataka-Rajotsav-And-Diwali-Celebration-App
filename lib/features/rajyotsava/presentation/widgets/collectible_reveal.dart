import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/easter_eggs.dart';
import 'collectible_card.dart';
import 'rajyotsava_motion.dart';
import 'rajyotsava_widgets.dart';

/// Shows a discovery over the current screen: the screen dims, a short
/// announcement appears and the card springs in with a turn. With reduced
/// motion it simply fades in. [photo] is the collectible's photo asset.
Future<void> showCollectibleReveal(
  BuildContext context, {
  required Reveal reveal,
  String? photo,
  int total = 0,
  bool revisit = false,
}) {
  final reduce = reduceMotion(context);
  return Navigator.of(context, rootNavigator: true).push(
    _RevealRoute<void>(
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: AppColors.scrim,
      transitionDuration: reduce ? AppDurations.medium : AppDurations.slow,
      // Closing is quicker than the springy entrance, so Close feels
      // immediate.
      reverseTransitionDuration: AppDurations.medium,
      pageBuilder: (context, _, _) => RajyotsavaTheme(
        child: _RevealView(
          reveal: reveal,
          photo: photo,
          total: total,
          revisit: revisit,
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        if (reduce) return FadeTransition(opacity: animation, child: child);
        final spring = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: AnimatedBuilder(
            animation: spring,
            // While it opens or closes, the reveal turns as a picture taken
            // once, not as live text redrawn at a new size on every frame.
            child: _SnapshotWhileMoving(animation: animation, child: child),
            builder: (context, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _entryPerspective)
                ..rotateY((1 - spring.value) * pi / 2)
                ..scaleByDouble(
                  _entryScale + (1 - _entryScale) * spring.value,
                  _entryScale + (1 - _entryScale) * spring.value,
                  1,
                  1,
                ),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

/// A dialog route whose closing can be quicker than its opening.
class _RevealRoute<T> extends RawDialogRoute<T> {
  _RevealRoute({
    required super.pageBuilder,
    required super.transitionBuilder,
    required super.barrierDismissible,
    required super.barrierLabel,
    required super.barrierColor,
    required super.transitionDuration,
    required this.reverseTransitionDuration,
  });

  @override
  final Duration reverseTransitionDuration;
}

/// Shows [child] as a snapshot while [animation] runs, and live otherwise.
class _SnapshotWhileMoving extends StatefulWidget {
  const _SnapshotWhileMoving({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_SnapshotWhileMoving> createState() => _SnapshotWhileMovingState();
}

class _SnapshotWhileMovingState extends State<_SnapshotWhileMoving> {
  final SnapshotController _snapshot = SnapshotController();

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_update);
    _update(widget.animation.status);
  }

  void _update(AnimationStatus status) =>
      _snapshot.allowSnapshotting = status.isAnimating;

  @override
  void dispose() {
    widget.animation.removeStatusListener(_update);
    _snapshot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SnapshotWidget(controller: _snapshot, child: widget.child);
}

const double _entryPerspective = 0.001;
const double _entryScale = 0.6;

class _RevealView extends StatelessWidget {
  const _RevealView({
    required this.reveal,
    required this.photo,
    required this.total,
    required this.revisit,
  });

  final Reveal reveal;
  final String? photo;
  final int total;

  /// Reopened from the collection, not newly discovered.
  final bool revisit;

  /// Room above and below the card for the message and Close button.
  static const double _chrome = 220;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final width = min(
      min(size.width - AppSpacing.lg * 2, AppSizes.collectibleCardMaxWidth),
      (size.height - _chrome) * CollectibleCard.aspectRatio,
    ).clamp(AppSizes.badgeLarge, AppSizes.collectibleCardMaxWidth);

    final reveal = this.reveal;
    final (title, subtitle, Widget card) = switch (reveal) {
      NewCollectible(:final collectible) => (
        revisit
            ? collectible.kannadaTitle
            : 'ನಿಮಗೆ ಕರ್ನಾಟಕದ ಒಂದು ರಹಸ್ಯ ಸಿಕ್ಕಿದೆ!',
        revisit ? 'From your collection' : 'You discovered a Karnataka secret!',
        CollectibleCard(collectible: collectible, photo: photo, width: width),
      ),
      CollectionComplete() => (
        'ಎಲ್ಲ ರಹಸ್ಯಗಳು ನಿಮ್ಮವು!',
        'You found all ${total > 0 ? '$total ' : ''}Karnataka secrets!',
        _CompletionCard(width: width),
      ),
    };

    return SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.kannadaYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onNight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                card,
                const SizedBox(height: AppSpacing.md),
                if (reveal is NewCollectible)
                  Text(
                    'Drag to tilt · Tap to flip',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.onNightMuted,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  key: const ValueKey('collectible-close'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of a card once every collectible has been found.
class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: width / CollectibleCard.aspectRatio,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: AppRadius.lgAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.kannadaYellow,
              AppColors.rangoliMarigold,
              AppColors.kannadaRed,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: AppIconSizes.hero,
                color: AppColors.ink,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Karnataka Treasure Hunter',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'ಕರ್ನಾಟಕದ ಇತಿಹಾಸ, ಸಂಸ್ಕೃತಿ ಮತ್ತು ಪ್ರಕೃತಿಯ ಎಲ್ಲ ರಹಸ್ಯಗಳನ್ನು '
                'ನೀವು ಕಂಡುಕೊಂಡಿದ್ದೀರಿ.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Revisit them any time in your collection.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
