import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/feature_module.dart';
import '../../../app/providers.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../games_providers.dart';

/// Each game card gets its own pastel gradient in turn, left to right (its
/// text panel).
const List<(Color, Color)> _panels = [
  (AppColors.gameSunny, AppColors.gameSunnyEnd),
  (AppColors.gameMint, AppColors.gameMintEnd),
  (AppColors.gameLavender, AppColors.gameLavenderEnd),
];

/// Games tab: a friendly header and one colourful card per game. The cards
/// come from features that register an entry with
/// `group: FeatureGroups.games`.
///
/// Every time the tab opens, the cards fly in one after another, a light
/// sweeps across each, and the icons and arrows bob for a few seconds, then
/// everything rests. With reduced motion, the page is simply shown.
/// Background music plays while the Games tab is active and visible.
class GamesPage extends ConsumerStatefulWidget {
  const GamesPage({super.key});

  @override
  ConsumerState<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends ConsumerState<GamesPage>
    with TickerProviderStateMixin {
  /// Gap between one card starting and the next.
  static final Duration _step = AppDurations.stagger * 2;

  /// Bobbing legs (up or down) before the icons come to rest.
  static const int _bobs = 8;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _total,
  );
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  );
  bool _wasActive = false;

  // Background music follows the tab's visibility (see games_providers.dart).
  late final AppLifecycleListener _lifecycle;
  late final GamesAudioController _audioController;
  var _foreground = true;

  @override
  void initState() {
    super.initState();
    _audioController = ref.read(gamesAudioStateProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        _report();
      },
    );
  }

  void _report() {
    final visible =
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _audioController.setTabVisible(visible);
    });
  }

  /// Header, then three cards, each entering then getting its shine.
  static Duration get _total =>
      _step * 3 + AppDurations.entrance + AppDurations.slow;

  /// 0..1 of [_enter] at which something starting [after] in begins.
  static double _at(Duration after) =>
      after.inMilliseconds / _total.inMilliseconds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The tab stays mounted while hidden; replay when it comes back.
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_wasActive) _play();
    _wasActive = active;
    _report();
  }

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      return;
    }
    _enter.forward(from: 0);
    _bob.repeat(reverse: true, count: _bobs);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    final controller = _audioController;
    scheduleMicrotask(() => controller.setTabVisible(false));
    _enter.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final games = [
      for (final m in ref.watch(featureModulesProvider))
        if (m.entry?.group == FeatureGroups.games) m.entry!,
    ]..sort((a, b) => a.order.compareTo(b.order));

    // A festive picture behind everything. It is always dark, so the status
    // bar icons are light whatever the app theme.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.gamesBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _Backdrop(),
            SafeArea(
              child: games.isEmpty
                  ? const EmptyView(
                      message: 'No games yet.',
                      icon: Icons.sports_esports_outlined,
                    )
                  : ConstrainedBody(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          // Keeps the last card clear of the floating bar.
                          AppSizes.floatingBarClearance,
                        ),
                        children: [
                          _Header(
                            fade: CurvedAnimation(
                              parent: _enter,
                              curve: Interval(0, _at(AppDurations.entrance)),
                            ),
                            bob: _bob,
                          ),
                          for (var i = 0; i < games.length; i++) ...[
                            const SizedBox(height: AppSpacing.md),
                            _GameCard(
                              entry: games[i],
                              colors: _panels[i % _panels.length],
                              fromLeft: i.isEven,
                              enter: CurvedAnimation(
                                parent: _enter,
                                curve: Interval(
                                  _at(_step * (i + 1)),
                                  _at(_step * (i + 1) + AppDurations.entrance),
                                ),
                              ),
                              shine: CurvedAnimation(
                                parent: _enter,
                                curve: Interval(
                                  _at(_step * (i + 1) + AppDurations.entrance),
                                  1,
                                ),
                              ),
                              bob: _bob,
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps header text readable over the busy picture.
const List<Shadow> _textShadow = [
  Shadow(color: AppColors.scrim, blurRadius: AppSpacing.sm),
];

/// The festive Diwali picture filling the page, with a light flat dimmer so
/// the cards and text stand out. It is a decoration painted behind everything
/// (not content), so it runs full-bleed under the system bars. The deep purple
/// shows while it loads or if it is missing.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.gamesBackground,
      image: DecorationImage(
        image: const AssetImage('assets/games/background.jpg'),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          AppColors.ink.withValues(alpha: AppOpacity.glow),
          BlendMode.srcOver,
        ),
        onError: (_, _) {},
      ),
    ),
    child: const SizedBox.expand(),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.fade, required this.bob});

  final Animation<double> fade;
  final Animation<double> bob;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FadeTransition(
      opacity: fade,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    "Let's play!",
                    style: text.headlineMedium?.copyWith(
                      color: AppColors.onNight,
                      shadows: _textShadow,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pick a game and beat your best score.',
                  style: text.bodyLarge?.copyWith(
                    color: AppColors.onNightMuted,
                    shadows: _textShadow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _GamesAudioMuteButton(),
          const SizedBox(width: AppSpacing.sm),
          _Bobbing(
            animation: bob,
            child: const Icon(
              Icons.emoji_events,
              size: AppIconSizes.xl,
              color: AppColors.diwaliGold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mutes or resumes the Games theme music. Hidden when the device has no
/// audio file to play.
class _GamesAudioMuteButton extends ConsumerWidget {
  const _GamesAudioMuteButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(gamesAudioStateProvider);
    if (!audioState.available) return const SizedBox.shrink();
    final muted = audioState.muted;
    return IconButton(
      key: const ValueKey('games-audio-mute'),
      tooltip: muted ? 'Play audio' : 'Mute audio',
      isSelected: muted,
      onPressed: ref.read(gamesAudioStateProvider.notifier).toggleMute,
      // The page is always dark, so the icon is always light.
      style: IconButton.styleFrom(foregroundColor: AppColors.onNight),
      icon: const Icon(Icons.volume_up),
      selectedIcon: const Icon(Icons.volume_off),
    );
  }
}

/// Moves [child] up and down with [animation], by a few points.
class _Bobbing extends StatelessWidget {
  const _Bobbing({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        -AppSpacing.xs * Curves.easeInOut.transform(animation.value),
      ),
      child: child,
    ),
  );
}

class _GameCard extends ConsumerStatefulWidget {
  const _GameCard({
    required this.entry,
    required this.colors,
    required this.fromLeft,
    required this.enter,
    required this.shine,
    required this.bob,
  });

  final FeatureEntry entry;
  final (Color, Color) colors;
  final bool fromLeft;
  final Animation<double> enter;
  final Animation<double> shine;
  final Animation<double> bob;

  @override
  ConsumerState<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends ConsumerState<_GameCard> {
  static const double _slide = 0.4;
  static const double _startScale = 0.9;

  /// Width of the travelling light, as a share of the card.
  static const double _shineWidth = 0.15;

  /// Width : height of the picture at the top of the card.
  static const double _pictureAspect = 16 / 9;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final entry = widget.entry;
    final (panelStart, panelEnd) = widget.colors;
    const onCard = AppColors.ink;

    final bounce = CurvedAnimation(
      parent: widget.enter,
      curve: Curves.easeOutBack,
    );
    return FadeTransition(
      opacity: CurvedAnimation(parent: widget.enter, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween(
          begin: Offset(widget.fromLeft ? -_slide : _slide, 0),
          end: Offset.zero,
        ).animate(bounce),
        child: ScaleTransition(
          scale: Tween(begin: _startScale, end: 1.0).animate(bounce),
          child: AnimatedScale(
            scale: _pressed ? AppScale.pressed : 1,
            duration: AppDurations.fast,
            curve: Curves.easeOut,
            child: ClipRRect(
              borderRadius: AppRadius.xlAll,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Picture(
                        entry: entry,
                        badge: AppColors.ink,
                        aspect: _pictureAspect,
                        bob: widget.bob,
                      ),
                      // Text sits on a pastel panel below the picture, so it is readable
                      // whatever the image.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [panelStart, panelEnd],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: text.titleLarge?.copyWith(color: onCard),
                              ),
                              Text(
                                entry.subtitle,
                                style: text.bodyMedium?.copyWith(color: onCard),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _PlayPill(bob: widget.bob),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // A light that sweeps across once the card has landed.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: widget.shine,
                        builder: (context, _) {
                          final p =
                              -_shineWidth +
                              (1 + 2 * _shineWidth) * widget.shine.value;
                          double at(double v) => v.clamp(0.0, 1.0);
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: const [
                                  AppColors.transparent,
                                  AppColors.glassHighest,
                                  AppColors.transparent,
                                ],
                                stops: [
                                  at(p - _shineWidth),
                                  at(p),
                                  at(p + _shineWidth),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        onHighlightChanged: (v) => setState(() => _pressed = v),
                        onTap: () async {
                          unawaited(ref.read(hapticsProvider).tap());
                          // Pause the theme music while a game is open.
                          final audio = ref.read(
                            gamesAudioStateProvider.notifier,
                          );
                          audio.setRouteActive(false);
                          try {
                            await context.push(entry.path);
                          } finally {
                            audio.setRouteActive(true);
                          }
                        },
                        child: Semantics(
                          button: true,
                          label: '${entry.title}. ${entry.subtitle}',
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The game's picture, shown in full with no overlay, with the
/// game's icon in a bobbing badge on top. Falls back to a plain colour when
/// the entry has no picture.
class _Picture extends StatelessWidget {
  const _Picture({
    required this.entry,
    required this.badge,
    required this.aspect,
    required this.bob,
  });

  final FeatureEntry entry;
  final Color badge;
  final double aspect;
  final Animation<double> bob;

  @override
  Widget build(BuildContext context) {
    final image = entry.image;
    return AspectRatio(
      aspectRatio: aspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // No picture: a dark panel with the game's icon, never a hole.
          if (image == null)
            ColoredBox(
              color: AppColors.ink,
              child: Center(
                child: Icon(
                  entry.icon,
                  size: AppIconSizes.hero,
                  color: AppColors.onBanner.withValues(
                    alpha: AppOpacity.secondaryText,
                  ),
                ),
              ),
            )
          else
            Image.asset(
              image,
              fit: BoxFit.cover,
              alignment: entry.imageAlignment,
              excludeFromSemantics: true,
              // Pixel art stays crisp when enlarged; photos stay smooth.
              filterQuality: image.endsWith('.png')
                  ? FilterQuality.none
                  : FilterQuality.medium,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: _Bobbing(
              animation: bob,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.withValues(alpha: AppOpacity.strong),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Icon(
                    entry.icon,
                    size: AppIconSizes.md,
                    color: AppColors.onBanner,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark "Play" button look; the arrow nudges right while the page bobs.
class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.bob});

  final Animation<double> bob;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.ink,
      borderRadius: AppRadius.xlAll,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Play',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppColors.onBanner),
          ),
          const SizedBox(width: AppSpacing.xs),
          AnimatedBuilder(
            animation: bob,
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: AppIconSizes.sm,
              color: AppColors.onBanner,
            ),
            builder: (context, child) => Transform.translate(
              offset: Offset(
                AppSpacing.xs * Curves.easeInOut.transform(bob.value),
                0,
              ),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );
}
