import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/google_sign_in_button.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/auth_repository.dart';
import '../domain/player.dart';
import '../flappy_bird_feature.dart';
import '../flappy_bird_providers.dart';
import 'character_avatar_view.dart';
import 'widgets/arcade_widgets.dart';

/// App-wide account gate. A configured build cannot enter the app until the
/// player has authenticated and captured their camera-only character photo.
/// Unconfigured development builds remain usable for local UI development;
/// production builds show an actionable setup error instead.
class PlayerOnboardingGate extends ConsumerWidget {
  const PlayerOnboardingGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    if (!config.hasSupabase || !config.hasGoogleAuth) {
      return config.isProd ? const FlappySetupRequiredView() : child;
    }

    return ref
        .watch(flappyAuthStateProvider)
        .when(
          loading: () => const Scaffold(body: SafeArea(child: LoadingView())),
          error: (error, _) => Scaffold(
            body: SafeArea(
              child: ErrorView(
                error: error,
                onRetry: () => ref.invalidate(flappyAuthStateProvider),
              ),
            ),
          ),
          data: (player) {
            if (player == null) return const FlappyLoginView();
            if (!player.hasCharacterAvatar) {
              return Scaffold(
                body: SafeArea(
                  child: CharacterAvatarView(
                    player: player,
                    onComplete: (_) {},
                  ),
                ),
              );
            }
            return child;
          },
        );
  }
}

class FlappyBirdPage extends ConsumerWidget {
  const FlappyBirdPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    BackButton backButton([String fallback = '/']) => BackButton(
      onPressed: () => context.canPop() ? context.pop() : context.go(fallback),
    );

    if (!config.hasSupabase || !config.hasGoogleAuth) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Flappy Bird Arcade'),
          leading: backButton(),
        ),
        body: const SafeArea(child: FlappySetupRequiredView()),
      );
    }

    return ref
        .watch(flappyAuthStateProvider)
        .when(
          loading: () => Scaffold(
            appBar: AppBar(
              title: const Text('Flappy Bird Arcade'),
              leading: backButton(),
            ),
            body: const SafeArea(child: LoadingView()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(
              title: const Text('Flappy Bird Arcade'),
              leading: backButton(),
            ),
            body: SafeArea(
              child: ErrorView(
                error: error,
                onRetry: () => ref.invalidate(flappyAuthStateProvider),
              ),
            ),
          ),
          data: (player) {
            if (player == null) return const FlappyLoginView();
            if (!player.hasCharacterAvatar) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Flappy Bird Arcade'),
                  leading: backButton(),
                ),
                body: SafeArea(
                  child: CharacterAvatarView(
                    player: player,
                    onComplete: (_) {},
                  ),
                ),
              );
            }
            return const Scaffold(
              extendBodyBehindAppBar: true,
              body: _DashboardView(),
            );
          },
        );
  }
}

class ProtectedFlappyPage extends ConsumerWidget {
  const ProtectedFlappyPage({
    required this.title,
    required this.builder,
    this.immersive = false,
    super.key,
  });

  final String title;
  final Widget Function(PlayerProfile player) builder;
  final bool immersive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref
        .watch(flappyAuthStateProvider)
        .when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(flappyAuthStateProvider),
          ),
          data: (player) => player == null
              ? _SignedOutView(
                  onReturn: () => context.go(FlappyBirdRoutes.root),
                )
              : builder(player),
        );
    return Scaffold(
      extendBodyBehindAppBar: immersive,
      appBar: immersive
          ? null
          : AppBar(
              title: Text(title),
              leading: BackButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(FlappyBirdRoutes.root),
              ),
            ),
      body: immersive ? content : SafeArea(child: content),
    );
  }
}

class FlappySetupRequiredView extends StatelessWidget {
  const FlappySetupRequiredView({super.key});

  @override
  Widget build(BuildContext context) => const ArcadeBackground(
    child: SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: ArcadePanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_suggest_outlined, size: AppIconSizes.xl),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Account setup required',
                  style: TextStyle(
                    fontSize: ArcadeText.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Run with SUPABASE_URL, SUPABASE_ANON_KEY and '
                  'GOOGLE_WEB_CLIENT_ID. See docs/FLAPPY_BIRD_SETUP.md.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class FlappyLoginView extends ConsumerStatefulWidget {
  const FlappyLoginView({super.key});

  @override
  ConsumerState<FlappyLoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<FlappyLoginView> {
  bool _loading = false;
  String? _message;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ref.read(flappyAuthRepositoryProvider).signInWithGoogle();
      ref.invalidate(flappyAuthStateProvider);
    } on AuthCancelledException {
      if (mounted) setState(() => _message = 'Sign-in was cancelled.');
    } on AuthConfigurationException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on AppFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) setState(() => _message = 'Sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlappyPalette.night,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final screenAspect = screenWidth / screenHeight;
          const imageAspect = 576.0 / 1024.0;

          final double renderedHeight;
          final double offsetY;
          if (screenAspect < imageAspect) {
            renderedHeight = screenHeight;
            offsetY = 0;
          } else {
            renderedHeight = screenWidth / imageAspect;
            offsetY = (screenHeight - renderedHeight) / 2;
          }

          // In the background image (576x1024), the line
          // "Celebrate Karnataka's Pride and the Festival of Lights" ends at y ~ 755 (73.7%).
          // The Rangoli starts at y ~ 870 (85.0%).
          // Position the button nicely in the smooth open floor area below the text line (~77.5%).
          final targetTop = offsetY + (775.0 / 1024.0) * renderedHeight;
          final buttonTop = targetTop.clamp(
            screenHeight * 0.60,
            screenHeight - 130.0,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed background poster image
              Positioned.fill(
                child: Image.asset(
                  'assets/auth/login_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // Google Login button positioned right below the festival line
              Positioned(
                top: buttonTop,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: ArcadeSizes.panelMaxWidth,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GoogleSignInButton(
                              loading: _loading,
                              onPressed: _loading ? null : _signIn,
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: FlappyPalette.black.withValues(
                                    alpha: ArcadeOpacity.border,
                                  ),
                                  borderRadius: AppRadius.mdAll,
                                  border: Border.all(
                                    color: FlappyPalette.errorAccent.withValues(
                                      alpha: ArcadeOpacity.error,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _message!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: FlappyPalette.white,
                                    fontSize: ArcadeText.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
    );
  }
}

class _DashboardView extends ConsumerStatefulWidget {
  const _DashboardView();

  @override
  ConsumerState<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<_DashboardView> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final sent = await ref
          .read(scoreSubmissionServiceProvider)
          .retryPending();
      if (sent > 0 && mounted) ref.invalidate(dashboardProvider);
    });
  }

  Future<void> _logout() async {
    try {
      await ref.read(flappyAuthRepositoryProvider).signOut();
      ref.invalidate(flappyAuthStateProvider);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not log out. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(dashboardProvider)
      .when(
        loading: () => const _DashboardBackground(child: LoadingView()),
        error: (error, _) => _DashboardBackground(
          child: ErrorView(
            error: error,
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
        ),
        data: (dashboard) => _FestivalDashboard(
          dashboard: dashboard,
          onLogout: _logout,
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            await ref.read(dashboardProvider.future);
          },
        ),
      );
}

class _DashboardBackground extends StatelessWidget {
  const _DashboardBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/flappy_bird/dashboard_background.png',
        fit: BoxFit.cover,
      ),
      SafeArea(child: child),
    ],
  );
}

class _FestivalDashboard extends StatelessWidget {
  const _FestivalDashboard({
    required this.dashboard,
    required this.onLogout,
    required this.onRefresh,
  });

  final DashboardData dashboard;
  final Future<void> Function() onLogout;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Fit the artwork to the width and scroll when it is taller than the
      // screen. Fitting to the larger side centred it, which pushed the back
      // button and profile card off the top on short or wide screens.
      final scale = constraints.maxWidth / 848;
      final canvasHeight = 1855 * scale;
      const left = 0.0;
      const top = 0.0;

      Widget position({
        required double x,
        required double y,
        required double width,
        required double height,
        required Widget child,
      }) => Positioned(
        left: left + x * scale,
        top: top + y * scale,
        width: width * scale,
        height: height * scale,
        child: child,
      );

      return RefreshIndicator.adaptive(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: math.max(canvasHeight, constraints.maxHeight),
            width: constraints.maxWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/flappy_bird/dashboard_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                position(
                  x: 38,
                  y: 116,
                  width: PosterPx.p56,
                  height: PosterPx.p56,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(FlappyBirdRoutes.root),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: FlappyPalette.white,
                      size: PosterPx.p46 * scale,
                    ),
                  ),
                ),
                position(
                  x: 140,
                  y: 119,
                  width: PosterPx.p520,
                  height: PosterPx.p70,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        text: 'Flappy Bird ',
                        style: TextStyle(
                          color: FlappyPalette.white,
                          fontSize: PosterPx.p48 * scale,
                          fontWeight: FontWeight.w800,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Arcade',
                            style: TextStyle(color: FlappyPalette.festivalGold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                position(
                  x: 662,
                  y: 122,
                  width: PosterPx.p72,
                  height: PosterPx.p62,
                  child: Icon(
                    Icons.flutter_dash,
                    color: FlappyPalette.festivalGold,
                    size: PosterPx.p72 * scale,
                  ),
                ),
                position(
                  x: 43,
                  y: 236,
                  width: PosterPx.p762,
                  height: PosterPx.p157,
                  child: _ReferenceProfileCard(
                    dashboard: dashboard,
                    scale: scale,
                    onLogout: onLogout,
                  ),
                ),
                position(
                  x: 43,
                  y: 428,
                  width: PosterPx.p371,
                  height: PosterPx.p225,
                  child: _ReferenceStatCard(
                    value: '${dashboard.stats.highScore}',
                    label: 'Personal best',
                    icon: Icons.emoji_events_rounded,
                    accent: FlappyPalette.festivalGold,
                    scale: scale,
                  ),
                ),
                position(
                  x: 435,
                  y: 428,
                  width: PosterPx.p371,
                  height: PosterPx.p225,
                  child: _ReferenceStatCard(
                    value: '${dashboard.stats.totalGames}',
                    label: 'Games played',
                    icon: Icons.sports_esports_rounded,
                    accent: FlappyPalette.sparkPink,
                    scale: scale,
                  ),
                ),
                position(
                  x: 43,
                  y: 678,
                  width: PosterPx.p371,
                  height: PosterPx.p225,
                  child: _ReferenceStatCard(
                    value: '${dashboard.stats.totalScore}',
                    label: 'Total score',
                    icon: Icons.stars_rounded,
                    accent: FlappyPalette.sparkCyan,
                    scale: scale,
                  ),
                ),
                position(
                  x: 435,
                  y: 678,
                  width: PosterPx.p371,
                  height: PosterPx.p225,
                  child: _ReferenceStatCard(
                    value: dashboard.stats.globalRank == null
                        ? '—'
                        : '#${dashboard.stats.globalRank}',
                    label: 'Global rank',
                    icon: Icons.military_tech_rounded,
                    accent: FlappyPalette.festivalGold,
                    scale: scale,
                  ),
                ),
                position(
                  x: 43,
                  y: 952,
                  width: PosterPx.p762,
                  height: PosterPx.p119,
                  child: _ReferenceActionButton(
                    label: 'PLAY GAME',
                    icon: Icons.play_arrow_rounded,
                    primary: true,
                    scale: scale,
                    onPressed: () => context.push(FlappyBirdRoutes.game),
                  ),
                ),
                position(
                  x: 43,
                  y: 1102,
                  width: PosterPx.p762,
                  height: PosterPx.p105,
                  child: _ReferenceActionButton(
                    label: 'LEADERBOARD',
                    icon: Icons.leaderboard_outlined,
                    scale: scale,
                    onPressed: () => context.push(FlappyBirdRoutes.leaderboard),
                  ),
                ),
                position(
                  x: 43,
                  y: 1222,
                  width: PosterPx.p762,
                  height: PosterPx.p105,
                  child: _ReferenceActionButton(
                    label: 'MY PROFILE',
                    icon: Icons.person_outline_rounded,
                    scale: scale,
                    onPressed: () => context.push(FlappyBirdRoutes.profile),
                  ),
                ),
                position(
                  x: 43,
                  y: 1342,
                  width: PosterPx.p762,
                  height: PosterPx.p105,
                  child: _ReferenceActionButton(
                    label: 'SETTINGS',
                    icon: Icons.settings_outlined,
                    scale: scale,
                    onPressed: () => context.push(FlappyBirdRoutes.settings),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ReferenceProfileCard extends StatelessWidget {
  const _ReferenceProfileCard({
    required this.dashboard,
    required this.scale,
    required this.onLogout,
  });

  final DashboardData dashboard;
  final double scale;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: FlappyPalette.panel.withValues(alpha: ArcadeOpacity.panel),
      borderRadius: BorderRadius.circular(PosterPx.p44 * scale),
      border: Border.all(
        color: FlappyPalette.sparkPink.withValues(alpha: ArcadeOpacity.border),
        width: ArcadeSizes.goldBorder * scale,
      ),
      boxShadow: [
        BoxShadow(
          color: FlappyPalette.sparkPink.withValues(alpha: ArcadeOpacity.half),
          blurRadius: 18 * scale,
        ),
      ],
    ),
    child: Row(
      children: [
        SizedBox(width: PosterPx.p30 * scale),
        PlayerAvatar(
          username: dashboard.profile.username,
          avatarUrl: dashboard.profile.displayAvatarUrl,
          radius: PosterPx.p64 * scale,
        ),
        SizedBox(width: PosterPx.p28 * scale),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dashboard.profile.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FlappyPalette.white,
                  fontWeight: FontWeight.w800,
                  fontSize: PosterPx.p38 * scale,
                ),
              ),
              SizedBox(height: PosterPx.p8 * scale),
              Text(
                dashboard.profile.email ?? 'Player',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FlappyPalette.white70,
                  fontSize: PosterPx.p23 * scale,
                ),
              ),
            ],
          ),
        ),
        _ProfileIcon(
          icon: Icons.edit_outlined,
          tooltip: 'Edit Profile',
          scale: scale,
          onPressed: () => context.push(FlappyBirdRoutes.profile),
        ),
        _ProfileIcon(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          scale: scale,
          onPressed: () => context.push(FlappyBirdRoutes.settings),
        ),
        _ProfileIcon(
          icon: Icons.logout_rounded,
          tooltip: 'Log out',
          scale: scale,
          onPressed: onLogout,
        ),
        SizedBox(width: PosterPx.p18 * scale),
      ],
    ),
  );
}

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon({
    required this.icon,
    required this.tooltip,
    required this.scale,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: PosterPx.p84 * scale,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: FlappyPalette.white, size: PosterPx.p48 * scale),
    ),
  );
}

class _ReferenceStatCard extends StatelessWidget {
  const _ReferenceStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    required this.scale,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;
  final double scale;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(PosterPx.p42 * scale),
      border: Border.all(color: accent, width: ArcadeSizes.goldBorder * scale),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          FlappyPalette.panel.withValues(alpha: ArcadeOpacity.card),
          accent.withValues(alpha: ArcadeOpacity.splashHighlight),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: ArcadeOpacity.half),
          blurRadius: 14 * scale,
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: accent, size: PosterPx.p60 * scale),
        SizedBox(height: PosterPx.p12 * scale),
        Text(
          value,
          style: TextStyle(
            color: FlappyPalette.white,
            fontWeight: FontWeight.w900,
            fontSize: PosterPx.p56 * scale,
          ),
        ),
        SizedBox(height: PosterPx.p8 * scale),
        Text(
          label,
          style: TextStyle(
            color: FlappyPalette.white70,
            fontSize: PosterPx.p25 * scale,
          ),
        ),
      ],
    ),
  );
}

class _ReferenceActionButton extends StatelessWidget {
  const _ReferenceActionButton({
    required this.label,
    required this.icon,
    required this.scale,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final double scale;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => Material(
    color: FlappyPalette.clear,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(PosterPx.p60 * scale),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PosterPx.p60 * scale),
          border: Border.all(
            color: primary
                ? FlappyPalette.festivalGold
                : FlappyPalette.sparkPink,
            width: ArcadeSizes.goldBorder * scale,
          ),
          gradient: primary
              ? const LinearGradient(
                  colors: [
                    FlappyPalette.festivalGold,
                    FlappyPalette.gold,
                    FlappyPalette.saffron,
                  ],
                )
              : LinearGradient(
                  colors: [
                    FlappyPalette.sky.withValues(alpha: ArcadeOpacity.card),
                    FlappyPalette.dusk.withValues(alpha: ArcadeOpacity.card),
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color:
                  (primary
                          ? FlappyPalette.festivalGold
                          : FlappyPalette.sparkPink)
                      .withValues(alpha: ArcadeOpacity.half),
              blurRadius: 16 * scale,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primary ? FlappyPalette.ink : FlappyPalette.white,
              size: PosterPx.p54 * scale,
            ),
            SizedBox(width: PosterPx.p25 * scale),
            Text(
              label,
              style: TextStyle(
                color: primary ? FlappyPalette.ink : FlappyPalette.white,
                fontSize: PosterPx.p34 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!primary) ...[
              SizedBox(width: PosterPx.p70 * scale),
              Icon(
                Icons.chevron_right_rounded,
                color: FlappyPalette.white70,
                size: PosterPx.p56 * scale,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) => ErrorView(
    error: const UnexpectedFailure('Your session ended. Please sign in again.'),
    onRetry: onReturn,
    retryLabel: 'Return to sign in',
  );
}
