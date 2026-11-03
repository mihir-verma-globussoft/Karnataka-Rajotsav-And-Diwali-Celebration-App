import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../state/intro_notifier.dart';
import '../theme/diwali_palette.dart';
import '../widgets/diwali_button.dart';
import '../widgets/diwali_motion.dart';
import '../widgets/diya_art.dart';
import '../widgets/sparkle_layers.dart';

/// Festive welcome: garland, three diyas that light up, a greeting and a CTA.
///
/// The ~3 s intro plays once per install (persisted), can be skipped, and can
/// be replayed. With reduced motion everything is shown in its final, still
/// state.
class HeroSection extends ConsumerStatefulWidget {
  const HeroSection({
    required this.onBegin,
    required this.scrollController,
    super.key,
  });

  /// Scrolls to the Explorer section.
  final VoidCallback onBegin;

  /// Used only to pause idle animation once the hero is scrolled away.
  final ScrollController scrollController;

  @override
  ConsumerState<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends ConsumerState<HeroSection>
    with SingleTickerProviderStateMixin {
  static const Duration _introDuration = Duration(milliseconds: 3000);
  static const double _minHeightFactor = 0.78;
  static const double _compactDiyaWidth = 0.5;
  static const double _singleDiyaWidth = 0.6;
  static const double _maxDiyaWidth = 240;
  static const double _sideDiyaFactor = 0.5;
  static const double _hideSideBelow = 340;
  static const int _particlesCompact = 24;
  static const int _particlesLarge = 40;
  static const double _hintBob = 6;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _introDuration,
  );
  bool _introStarted = false;
  bool _onScreen = true;

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(introSeenProvider.notifier).markSeen();
      }
    });
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _intro.dispose();
    super.dispose();
  }

  void _onScroll() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final visible = bottom > 0;
    if (visible != _onScreen) setState(() => _onScreen = visible);
  }

  void _syncIntro() {
    if (!mounted) return;
    final seen = ref.read(introSeenProvider);
    final reduce = DiwaliMotion.of(context).reduceMotion;
    if (reduce) {
      _introStarted = seen.hasValue || _introStarted;
      if (_intro.value < 1) _intro.value = 1;
      return;
    }
    if (_introStarted || !seen.hasValue) return;
    _introStarted = true;
    if (seen.requireValue) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  void _replay() => _intro.forward(from: 0);

  void _skip() {
    _intro.value = 1;
    ref.read(introSeenProvider.notifier).markSeen();
  }

  @override
  Widget build(BuildContext context) {
    final motion = DiwaliMotion.of(context);
    final seen = ref.watch(introSeenProvider);

    // Starting/forcing the intro changes provider state through the status
    // listener, which is not allowed during build, so do it after the frame.
    if ((!_introStarted && seen.hasValue) ||
        (motion.reduceMotion && _intro.value < 1)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncIntro());
    }

    final idleClock = motion.animate && _onScreen ? motion.clock : null;
    final width = MediaQuery.sizeOf(context).width;
    final minHeight = MediaQuery.sizeOf(context).height * _minHeightFactor;
    final text = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _intro,
      builder: (context, _) {
        final p = _intro.value;
        double stage(double from, double to) =>
            ((p - from) / (to - from)).clamp(0.0, 1.0);
        final bg = Curves.easeOut.transform(stage(0, 0.25));
        final centre = Curves.easeOut.transform(stage(0.15, 0.5));
        final sides = Curves.easeOut.transform(stage(0.4, 0.75));
        final copy = Curves.easeOutCubic.transform(stage(0.65, 0.95));
        final cta = Curves.easeOut.transform(stage(0.85, 1));
        final introRunning = _intro.isAnimating;
        final done = p >= 1;

        // Row = side + centre + side = centre * 2 when sides are shown.
        final avail =
            math.min(width, AppSizes.maxContentWidth) - 2 * AppSpacing.md;
        final showSides = width >= _hideSideBelow;
        final diyaWidth = math.min(
          avail * (showSides ? _compactDiyaWidth : _singleDiyaWidth),
          _maxDiyaWidth,
        );
        final sideWidth = diyaWidth * _sideDiyaFactor;

        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: ParticleField(
                  count: width < 600 ? _particlesCompact : _particlesLarge,
                  fade: bg,
                  clock: idleClock,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Garland(fade: bg, clock: idleClock),
              ),
              Padding(
                padding: const EdgeInsets.only(top: Garland.height),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showSides)
                            DiyaArt(
                              width: sideWidth,
                              ignite: sides,
                              clock: idleClock,
                            ),
                          DiyaArt(
                            width: diyaWidth,
                            ignite: centre,
                            clock: idleClock,
                          ),
                          if (showSides)
                            DiyaArt(
                              width: sideWidth,
                              ignite: sides,
                              clock: idleClock,
                            ),
                        ],
                      ),
                    ),
                    Opacity(
                      opacity: copy,
                      child: Transform.translate(
                        offset: Offset(0, AppSpacing.lg * (1 - copy)),
                        child: Column(
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                'Shubh Deepavali',
                                textAlign: TextAlign.center,
                                style: text.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: DiwaliPalette.cream,
                                  shadows: [
                                    Shadow(
                                      color: DiwaliPalette.flameCore.withValues(
                                        alpha: AppOpacity.glow,
                                      ),
                                      blurRadius: AppSpacing.md,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'ದೀಪಾವಳಿಯ ಶುಭಾಶಯಗಳು  ·  शुभ दीपावली',
                              textAlign: TextAlign.center,
                              style: text.titleMedium?.copyWith(
                                color: DiwaliPalette.gold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'May light fill your home and your heart.',
                              textAlign: TextAlign.center,
                              style: text.bodyLarge?.copyWith(
                                color: DiwaliPalette.creamMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Opacity(
                      opacity: cta,
                      child: IgnorePointer(
                        ignoring: cta < 1,
                        child: Semantics(
                          label:
                              'Begin the celebration. Scrolls to Discover '
                              'Deepavali.',
                          excludeSemantics: true,
                          button: true,
                          onTap: widget.onBegin,
                          child: DiwaliButton(
                            label: 'Begin the celebration',
                            icon: Icons.auto_awesome,
                            onPressed: widget.onBegin,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: AppSizes.minTouchTarget,
                      child: Center(
                        child: introRunning
                            ? DiwaliButton(
                                label: 'Skip',
                                kind: DiwaliButtonKind.tertiary,
                                onPressed: _skip,
                              )
                            : done && !motion.reduceMotion
                            ? DiwaliButton(
                                label: 'Replay',
                                icon: Icons.replay,
                                kind: DiwaliButtonKind.tertiary,
                                onPressed: _replay,
                              )
                            : null,
                      ),
                    ),
                    ExcludeSemantics(
                      child: Opacity(
                        opacity: cta,
                        child: ValueListenableBuilder<double>(
                          valueListenable: idleClock ?? _still,
                          builder: (context, t, _) => Transform.translate(
                            offset: Offset(0, _hintBob * _bob(t)),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: DiwaliPalette.gold,
                              size: AppIconSizes.lg,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static final ValueNotifier<double> _still = ValueNotifier<double>(0);

  static double _bob(double t) => t == 0 ? 0 : (1 + math.sin(t * 2.4)) / 2;
}
