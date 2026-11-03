import 'dart:math' show pi;

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
import 'widgets/rajyotsava_song.dart';
import 'widgets/rajyotsava_widgets.dart';

/// Rajyotsava tab, full screen with no app bar: a festive banner with the
/// greeting and countdown, links to the quiz,
/// Kannada lessons and Discover Karnataka, history, facts and wishes.
class RajyotsavaPage extends ConsumerWidget {
  const RajyotsavaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Centre the content column on wide screens; the banner stays
              // full width.
              final side =
                  ((constraints.maxWidth - AppSizes.maxContentWidth) / 2).clamp(
                    AppSpacing.md,
                    double.infinity,
                  );
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _FestiveBanner(countdown: countdown, side: side),
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
                        const SectionHeader(
                          title: 'Explore',
                          kannada: 'ಅನ್ವೇಷಿಸಿ',
                        ),
                        const _ExploreTile(
                          key: ValueKey('rajyotsava-quiz'),
                          icon: Icons.quiz_outlined,
                          title: 'Rajyotsava Quiz',
                          kannada: 'ರಸಪ್ರಶ್ನೆ',
                          subtitle: 'Test what you know about Karnataka',
                          path: RajyotsavaRoutes.quiz,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _ExploreTile(
                          key: ValueKey('rajyotsava-learn'),
                          icon: Icons.translate,
                          title: 'Learn Kannada',
                          kannada: 'ಕನ್ನಡ ಕಲಿಯಿರಿ',
                          subtitle: 'Alphabet, everyday phrases and numbers',
                          path: RajyotsavaRoutes.learn,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _ExploreTile(
                          key: ValueKey('rajyotsava-discover'),
                          icon: Icons.explore_outlined,
                          title: 'Discover Karnataka',
                          kannada: 'ಕರ್ನಾಟಕ ದರ್ಶನ',
                          subtitle: 'Places, food, culture and great people',
                          path: RajyotsavaRoutes.discover,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _ExploreTile(
                          key: ValueKey('rajyotsava-nearby'),
                          icon: Icons.near_me_outlined,
                          title: 'Near me',
                          kannada: 'ನನ್ನ ಸುತ್ತಮುತ್ತ',
                          subtitle:
                              'What is famous in the districts around you',
                          path: RajyotsavaRoutes.nearby,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _ExploreTile(
                          key: ValueKey('rajyotsava-culture'),
                          icon: Icons.music_note_outlined,
                          title: 'Songs & Folk Arts',
                          kannada: 'ಹಾಡು ಮತ್ತು ಜಾನಪದ ಕಲೆ',
                          subtitle:
                              'Kannada songs and traditional arts to watch',
                          path: RajyotsavaRoutes.culture,
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
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Edge-to-edge maroon banner with the flag, the festival name, a greeting
/// and the countdown. It looks the same in light and dark mode.
class _FestiveBanner extends StatelessWidget {
  const _FestiveBanner({required this.countdown, required this.side});

  final RajyotsavaCountdown countdown;

  /// Horizontal padding, matching the content column below.
  final double side;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = countdown.editionLabel;
    final status = countdown.isToday
        ? 'Today is the $label Kannada Rajyotsava!'
        : countdown.daysLeft == 1
        ? '1 day to the $label Rajyotsava'
        : '${countdown.daysLeft} days to the $label Rajyotsava';
    const white = AppColors.onBanner;
    final whiteSoft = white.withValues(alpha: AppOpacity.secondaryText);

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
        child: Stack(
          children: [
            const Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(painter: _RangoliPainter()),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              right: side - AppSpacing.sm,
              child: const SongMuteButton(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                side,
                MediaQuery.paddingOf(context).top + AppSpacing.lg,
                side,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KannadaFlag(width: AppSizes.flag),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    header: true,
                    child: Text(
                      'ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವ',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.kannadaYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    countdown.isToday
                        ? 'Happy Kannada Rajyotsava!'
                        : 'Celebrating Karnataka',
                    style: theme.textTheme.titleLarge?.copyWith(color: white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Karnataka was formed on 1 November $formationYear. Every '
                    'year on this day we celebrate its land, language and '
                    'people.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: whiteSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DecoratedBox(
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
                            countdown.isToday ? Icons.celebration : Icons.event,
                            size: AppIconSizes.sm,
                            color: AppColors.bannerBottom,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              status,
                              key: const ValueKey('rajyotsava-countdown'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.bannerBottom,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SongNowPlaying(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faint rangoli-style rings and dots in the banner's top-right corner.
/// Pure decoration; its geometry is local to the drawing.
class _RangoliPainter extends CustomPainter {
  const _RangoliPainter();

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

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(
      size.width - _centreFromTopRight.dx,
      _centreFromTopRight.dy,
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke
      ..color = AppColors.kannadaYellow.withValues(alpha: AppOpacity.faint);
    final dot = Paint()
      ..color = AppColors.kannadaYellow.withValues(alpha: AppOpacity.subtle);
    for (var r = _firstRing; r <= _lastRing; r += _ringGap) {
      canvas.drawCircle(centre, r, ring);
    }
    // Dots sit halfway between rings.
    for (var r = _firstRing + _ringGap / 2; r < _lastRing; r += _ringGap) {
      for (var i = 0; i < _petals; i++) {
        final angle = i * 2 * pi / _petals;
        canvas.drawCircle(
          centre + Offset.fromDirection(angle, r),
          _dotRadius,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RangoliPainter oldDelegate) => false;
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.icon,
    required this.title,
    required this.kannada,
    required this.subtitle,
    required this.path,
    super.key,
  });

  final IconData icon;
  final String title;
  final String kannada;
  final String subtitle;
  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(path),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IconBadge(icon: icon),
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
                  child: Text(
                    fact,
                    key: const ValueKey('rajyotsava-fact'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
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
