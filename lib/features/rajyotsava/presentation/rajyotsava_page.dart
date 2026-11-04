import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/models.dart';
import '../domain/rajyotsava_calendar.dart';
import '../rajyotsava_providers.dart';
import '../rajyotsava_routes.dart';
import 'widgets/listen_button.dart';
import 'widgets/rajyotsava_motion.dart';
import 'widgets/rajyotsava_song.dart';
import 'widgets/rajyotsava_widgets.dart';
import 'widgets/secret_tap.dart';

/// Rajyotsava tab, full screen with no app bar: a festive banner with the
/// greeting and countdown, links to the quiz,
/// Kannada lessons and Discover Karnataka, history, facts and wishes.
class RajyotsavaPage extends ConsumerStatefulWidget {
  const RajyotsavaPage({super.key});

  @override
  ConsumerState<RajyotsavaPage> createState() => _RajyotsavaPageState();
}

class _RajyotsavaPageState extends ConsumerState<RajyotsavaPage> {
  final _exploreKey = GlobalKey(debugLabel: 'explore');

  /// The banner's "Start exploring" button scrolls to the Explore section.
  void _scrollToExplore() {
    final target = _exploreKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: reduceMotion(context) ? Duration.zero : AppDurations.slow,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(rajyotsavaContentProvider);
    final today = ref.watch(rajyotsavaClockProvider)();
    final countdown = rajyotsavaCountdown(today);
    // Keeps the Kannada voice ready for the wishes while the tab exists.
    ref.watch(kannadaSpeakerProvider);

    // Full-screen tab: the banner runs behind the status bar, so its icons
    // are switched to light to stay readable on the maroon.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
      ),
      child: Scaffold(
        body: RajyotsavaSongScope(
          child: RajyotsavaAmbience(
            builder: (context, motion) => LayoutBuilder(
              builder: (context, constraints) {
                // Centre the content column on wide screens; the banner stays
                // full width.
                final side =
                    ((constraints.maxWidth - AppSizes.maxContentWidth) / 2)
                        .clamp(AppSpacing.md, double.infinity);
                return Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _FestiveBanner(
                            countdown: countdown,
                            side: side,
                            motion: motion,
                            onExplore: _scrollToExplore,
                          ),
                        ),
                        SliverPadding(
                          // Bottom space keeps the last card clear of the floating
                          // bar.
                          padding: EdgeInsets.fromLTRB(
                            side,
                            AppSpacing.sm,
                            side,
                            AppSizes.floatingBarClearance,
                          ),
                          sliver: SliverList.list(
                            children: [
                              SectionHeader(
                                key: _exploreKey,
                                title: 'Explore',
                                kannada: 'ಅನ್ವೇಷಿಸಿ',
                              ),
                              const _ExploreTile(
                                key: ValueKey('rajyotsava-quiz'),
                                accent: AppColors.accentRed,
                                icon: Icons.quiz_outlined,
                                title: 'Rajyotsava Quiz',
                                kannada: 'ರಸಪ್ರಶ್ನೆ',
                                subtitle: 'Test what you know about Karnataka',
                                path: RajyotsavaRoutes.quiz,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const _ExploreTile(
                                key: ValueKey('rajyotsava-learn'),
                                accent: AppColors.accentSaffron,
                                icon: Icons.translate,
                                title: 'Learn Kannada',
                                kannada: 'ಕನ್ನಡ ಕಲಿಯಿರಿ',
                                subtitle:
                                    'Alphabet, everyday phrases and numbers',
                                path: RajyotsavaRoutes.learn,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const _ExploreTile(
                                key: ValueKey('rajyotsava-discover'),
                                accent: AppColors.accentTeal,
                                icon: Icons.explore_outlined,
                                title: 'Discover Karnataka',
                                kannada: 'ಕರ್ನಾಟಕ ದರ್ಶನ',
                                subtitle:
                                    'Places, food, culture and great people',
                                path: RajyotsavaRoutes.discover,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const _ExploreTile(
                                key: ValueKey('rajyotsava-nearby'),
                                accent: AppColors.accentGreen,
                                icon: Icons.near_me_outlined,
                                title: 'Near me',
                                kannada: 'ನನ್ನ ಸುತ್ತಮುತ್ತ',
                                subtitle: 'What is famous in the districts around you',
                                path: RajyotsavaRoutes.nearby,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const _ExploreTile(
                                key: ValueKey('rajyotsava-culture'),
                                accent: AppColors.accentMagenta,
                                icon: Icons.music_note_outlined,
                                title: 'Songs & Folk Arts',
                                kannada: 'ಹಾಡು ಮತ್ತು ಜಾನಪದ ಕಲೆ',
                                subtitle: 'Kannada songs and traditional arts to watch',
                                path: RajyotsavaRoutes.culture,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const _ExploreTile(
                                key: ValueKey('rajyotsava-cinema'),
                                accent: AppColors.accentViolet,
                                icon: Icons.movie_outlined,
                                title: 'Kannada Cinema',
                                kannada: 'ಕನ್ನಡ ಚಿತ್ರರಂಗ',
                                subtitle:
                                    'Famous actors, actresses and their films',
                                path: RajyotsavaRoutes.cinema,
                              ),
                              const SectionHeader(
                                title: 'History',
                                kannada: 'ಇತಿಹಾಸ',
                              ),
                              _HistoryCard(events: content.history),
                              const SectionHeader(
                                title: 'Did you know?',
                                kannada: 'ನಿಮಗೆ ಗೊತ್ತೇ?',
                              ),
                              _FactCard(facts: content.facts, start: today.day),
                              const SectionHeader(
                                title: 'Send wishes',
                                kannada: 'ಶುಭಾಶಯಗಳು',
                              ),
                              for (final wish in content.wishes)
                                _WishCard(wish: wish),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Confetti and fireworks over the whole tab while the
                    // ambient motion runs; touches pass through to the content.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Fireworks(
                                motion: motion,
                                bursts: Fireworks.tabBursts,
                                interactive: false,
                              ),
                            ),
                            Positioned.fill(
                              child: ConfettiField(motion: motion),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Edge-to-edge maroon banner with the flag, the festival name, a greeting
/// and the countdown. It looks the same in light and dark mode. When the tab
/// opens, the flag waves, the rangoli turns and twinkles and the countdown
/// counts up, once; with reduced motion everything is still.
class _FestiveBanner extends StatefulWidget {
  const _FestiveBanner({
    required this.countdown,
    required this.side,
    required this.motion,
    required this.onExplore,
  });

  final VoidCallback onExplore;

  /// The tab's ambient clock (toran sway, waving flag).
  final AmbientMotion motion;

  final RajyotsavaCountdown countdown;

  /// Horizontal padding, matching the content column below.
  final double side;

  @override
  State<_FestiveBanner> createState() => _FestiveBannerState();
}

class _FestiveBannerState extends State<_FestiveBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebration = AnimationController(
    vsync: this,
    duration: AppDurations.celebration,
  );
  late final Animation<double> _eased = CurvedAnimation(
    parent: _celebration,
    curve: Curves.easeOutCubic,
  );

  /// The countdown reaches its number in the first part of the celebration.
  late final Animation<double> _counting = CurvedAnimation(
    parent: _celebration,
    curve: Interval(
      0,
      AppDurations.countUp.inMilliseconds /
          AppDurations.celebration.inMilliseconds,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _celebration.value = 1;
    } else {
      startAfterFirstFrame(_celebration);
    }
  }

  @override
  void dispose() {
    _celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countdown = widget.countdown;
    final side = widget.side;
    final label = countdown.editionLabel;
    const white = AppColors.onBanner;
    final whiteSoft = white.withValues(alpha: AppOpacity.secondaryText);
    final top = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bannerTop, AppColors.bannerBottom],
        ),
        borderRadius: AppRadius.xlBottom,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.xlBottom,
        child: Builder(
          builder: (context) => Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(painter: _RangoliPainter(_eased)),
                ),
              ),
              // Tap-to-launch fireworks sit under the text and buttons, so
              // taps on empty parts of the banner launch one.
              Positioned.fill(child: Fireworks(motion: widget.motion)),
              Positioned(
                top: top,
                left: 0,
                right: 0,
                child: Toran(motion: widget.motion),
              ),
              Positioned(
                top: top + AppSizes.toran,
                right: side - AppSpacing.sm,
                child: const SongMuteButton(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  side,
                  top + AppSizes.toran + AppSpacing.sm,
                  side,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Secret: tap the flag 5 times.
                    SecretTap(
                      child: WavingFlag(
                        motion: widget.motion,
                        width: AppSizes.flag,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವ',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: AppColors.kannadaYellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FadeSlideIn(
                      index: 1,
                      child: Text(
                        countdown.isToday
                            ? 'Happy Kannada Rajyotsava!'
                            : 'Celebrating Karnataka',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FadeSlideIn(
                      index: 2,
                      child: Text(
                        'Karnataka was formed on 1 November $formationYear. '
                        'Every year on this day we celebrate its land, '
                        'language and people.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: whiteSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FadeSlideIn(
                      index: 3,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.kannadaYellow,
                          borderRadius: AppRadius.lgAll,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                countdown.isToday
                                    ? Icons.celebration
                                    : Icons.event,
                                size: AppIconSizes.sm,
                                color: AppColors.bannerBottom,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: CountUp(
                                  value: countdown.daysLeft,
                                  progress: _counting,
                                  builder: (context, days) => Text(
                                    countdown.isToday
                                        ? 'Today is the $label Kannada '
                                              'Rajyotsava!'
                                        : days == 1
                                        ? '1 day to the $label Rajyotsava'
                                        : '$days days to the $label '
                                              'Rajyotsava',
                                    key: const ValueKey('rajyotsava-countdown'),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.bannerBottom,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SongNowPlaying(),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      index: 4,
                      child: _ExploreButton(onPressed: widget.onExplore),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faint rangoli-style rings and dots in the banner's top-right corner. As
/// [progress] runs from 0 to 1 the dots turn a little and twinkle, then
/// settle. Pure decoration; its geometry is local to the drawing.
class _RangoliPainter extends CustomPainter {
  _RangoliPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  static const Offset _centreFromTopRight = Offset(
    AppSpacing.xl + AppSpacing.sm,
    AppSpacing.xxl + AppSpacing.lg,
  );
  static const double _ringStroke = 2;
  static const double _firstRing = 40;
  static const double _lastRing = 160;
  static const double _ringGap = 30;
  static const double _dotRadius = 3;
  static const int _petals = 16;

  /// How far the dots turn while settling (radians).
  static const double _turn = pi / 4;
  static const double _twinkles = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final centre = Offset(
      size.width - _centreFromTopRight.dx,
      _centreFromTopRight.dy,
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke
      ..color = AppColors.kannadaYellow.withValues(alpha: AppOpacity.faint);
    for (var r = _firstRing; r <= _lastRing; r += _ringGap) {
      canvas.drawCircle(centre, r, ring);
    }
    // Dots sit halfway between rings; alternate rings turn opposite ways.
    var ringIndex = 0;
    for (var r = _firstRing + _ringGap / 2; r < _lastRing; r += _ringGap) {
      final direction = ringIndex.isEven ? 1 : -1;
      final rotation = direction * (1 - t) * _turn;
      for (var i = 0; i < _petals; i++) {
        // Twinkle fades out as the celebration ends.
        final twinkle =
            (1 - t) * (sin((t * _twinkles + i / _petals) * 2 * pi) + 1) / 2;
        final dot = Paint()
          ..color = AppColors.kannadaYellow.withValues(
            alpha: AppOpacity.subtle + (1 - AppOpacity.subtle) * twinkle / 2,
          );
        final angle = i * 2 * pi / _petals + rotation;
        canvas.drawCircle(
          centre + Offset.fromDirection(angle, r),
          _dotRadius,
          dot,
        );
      }
      ringIndex++;
    }
  }

  @override
  bool shouldRepaint(_RangoliPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// "Start exploring": a flag-gradient pill that scrolls to the Explore
/// section.
class _ExploreButton extends StatelessWidget {
  const _ExploreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: AppColors.bannerBottom, fontWeight: FontWeight.bold);
    return Semantics(
      button: true,
      label: 'Start exploring',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.kannadaYellow, AppColors.rangoliMarigold],
          ),
          borderRadius: AppRadius.xlAll,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: AppRadius.xlAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('rajyotsava-start-exploring'),
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text('Start exploring', style: style)),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.arrow_downward,
                      size: AppIconSizes.sm,
                      color: style?.color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.accent,
    required this.icon,
    required this.title,
    required this.kannada,
    required this.subtitle,
    required this.path,
    super.key,
  });

  /// Colour of the tile's icon badge, different for each tile.
  final Color accent;
  final IconData icon;
  final String title;
  final String kannada;
  final String subtitle;
  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      // A soft gradient fill with a flag-red hairline, like the festive cards
      // elsewhere in the app.
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(
          color: scheme.primary.withValues(alpha: AppOpacity.border),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(path),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IconBadge(icon: icon, accent: accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      kannada,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.events});

  final List<HistoryEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (var i = 0; i < events.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppSizes.leadingLabel,
                    ),
                    child: Text(
                      events[i].year,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      events[i].text,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FactCard extends StatefulWidget {
  const _FactCard({required this.facts, required this.start});

  final List<String> facts;

  /// Index of the first fact shown, so the fact changes day to day.
  final int start;

  @override
  State<_FactCard> createState() => _FactCardState();
}

class _FactCardState extends State<_FactCard> {
  late int _index = widget.start;

  @override
  Widget build(BuildContext context) {
    if (widget.facts.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final fact = widget.facts[_index % widget.facts.length];
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  // The new fact cross-fades in (a plain fade, which also
                  // suits reduced motion).
                  child: AnimatedSwitcher(
                    duration: AppDurations.medium,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topLeft,
                      children: [...previous, ?current],
                    ),
                    child: Text(
                      fact,
                      key: ValueKey(fact),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _index++),
                icon: const Icon(Icons.refresh),
                label: const Text('Next fact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishCard extends StatelessWidget {
  const _WishCard({required this.wish});

  final RajyotsavaWish wish;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: wish.shareText));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Wish copied. Paste it in any chat.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wish.kannada, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    wish.english,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ListenButton(text: wish.kannada),
            IconButton(
              tooltip: 'Copy wish',
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
      ),
    );
  }
}
