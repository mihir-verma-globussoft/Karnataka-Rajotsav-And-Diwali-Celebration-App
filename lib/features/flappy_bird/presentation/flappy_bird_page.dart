import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
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
            return Scaffold(
              appBar: AppBar(
                title: const Text('Flappy Bird Arcade'),
                leading: backButton(),
              ),
              body: const SafeArea(child: _DashboardView()),
            );
          },
        );
  }
}

class ProtectedFlappyPage extends ConsumerWidget {
  const ProtectedFlappyPage({
    required this.title,
    required this.builder,
    super.key,
  });

  final String title;
  final Widget Function(PlayerProfile player) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: BackButton(
        onPressed: () => context.canPop()
            ? context.pop()
            : context.go(FlappyBirdRoutes.root),
      ),
    ),
    body: SafeArea(
      child: ref
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
          ),
    ),
  );
}

class FlappySetupRequiredView extends StatelessWidget {
  const FlappySetupRequiredView({super.key});

  @override
  Widget build(BuildContext context) => const ArcadeBackground(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ArcadePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings_suggest_outlined, size: 48),
              SizedBox(height: AppSpacing.md),
              Text(
                'Account setup required',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
      backgroundColor: const Color(0xFF1B0B2E),
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
                      horizontal: AppSpacing.md,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _GoogleSignInButton(
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
                                  color: Colors.black.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _message!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
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

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        splashColor: Colors.grey.withValues(alpha: 0.2),
        highlightColor: Colors.grey.withValues(alpha: 0.1),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE3E3E3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4285F4),
                    ),
                  ),
                )
              else
                Image.asset(
                  'assets/auth/google_logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  loading ? 'Signing in...' : 'Continue with Google',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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
  Widget build(BuildContext context) => ArcadeBackground(
    child: ref
        .watch(dashboardProvider)
        .when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (dashboard) => RefreshIndicator.adaptive(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              await ref.read(dashboardProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                110,
              ),
              children: [
                ArcadePanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      PlayerAvatar(
                        username: dashboard.profile.username,
                        avatarUrl: dashboard.profile.displayAvatarUrl,
                        radius: 24,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dashboard.profile.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dashboard.profile.email ?? 'Player',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit Profile',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.push(FlappyBirdRoutes.profile),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            context.push(FlappyBirdRoutes.settings),
                        icon: const Icon(Icons.settings_outlined, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Log out',
                        visualDensity: VisualDensity.compact,
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.55,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(
                      label: 'Personal best',
                      value: '${dashboard.stats.highScore}',
                      icon: Icons.emoji_events_outlined,
                    ),
                    StatCard(
                      label: 'Games played',
                      value: '${dashboard.stats.totalGames}',
                      icon: Icons.sports_esports_outlined,
                    ),
                    StatCard(
                      label: 'Total score',
                      value: '${dashboard.stats.totalScore}',
                      icon: Icons.stars_outlined,
                    ),
                    StatCard(
                      label: 'Global rank',
                      value: dashboard.stats.globalRank == null
                          ? '—'
                          : '#${dashboard.stats.globalRank}',
                      icon: Icons.military_tech_outlined,
                      highlighted: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ArcadeActionButton(
                  label: 'PLAY GAME',
                  icon: Icons.play_arrow_rounded,
                  primary: true,
                  onPressed: () => context.push(FlappyBirdRoutes.game),
                ),
                const SizedBox(height: AppSpacing.xs),
                ArcadeActionButton(
                  label: 'LEADERBOARD',
                  icon: Icons.leaderboard_outlined,
                  onPressed: () => context.push(FlappyBirdRoutes.leaderboard),
                ),
                const SizedBox(height: AppSpacing.xs),
                ArcadeActionButton(
                  label: 'MY PROFILE',
                  icon: Icons.person_outline,
                  onPressed: () => context.push(FlappyBirdRoutes.profile),
                ),
                const SizedBox(height: AppSpacing.xs),
                ArcadeActionButton(
                  label: 'SETTINGS',
                  icon: Icons.settings_outlined,
                  onPressed: () => context.push(FlappyBirdRoutes.settings),
                ),
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
