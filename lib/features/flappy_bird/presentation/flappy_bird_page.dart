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
    return Scaffold(
      appBar: AppBar(title: const Text('Flappy Bird Arcade')),
      body: SafeArea(
        child: !config.hasSupabase || !config.hasGoogleAuth
            ? const FlappySetupRequiredView()
            : ref
                  .watch(flappyAuthStateProvider)
                  .when(
                    loading: () => const LoadingView(),
                    error: (error, _) => ErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(flappyAuthStateProvider),
                    ),
                    data: (player) {
                      if (player == null) return const FlappyLoginView();
                      if (!player.hasCharacterAvatar) {
                        return CharacterAvatarView(
                          player: player,
                          onComplete: (_) {},
                        );
                      }
                      return const _DashboardView();
                    },
                  ),
      ),
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
    appBar: AppBar(title: Text(title)),
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
  Widget build(BuildContext context) => ArcadeBackground(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ArcadePanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BirdMark(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Rajotsav & Diwali',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: FlappyPalette.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Sign in once to save your profile and scores across all games.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _signIn,
                    icon: _loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  'We use your name, email and profile picture for your account and leaderboard.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                ArcadePanel(
                  child: Row(
                    children: [
                      PlayerAvatar(
                        username: dashboard.profile.username,
                        avatarUrl: dashboard.profile.displayAvatarUrl,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dashboard.profile.username,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(dashboard.profile.email ?? 'Player'),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () =>
                            context.push(FlappyBirdRoutes.settings),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                      IconButton(
                        tooltip: 'Log out',
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final columns =
                        constraints.maxWidth >= 360 && textScale <= 1.5 ? 2 : 1;
                    return GridView.count(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: columns == 2 ? 1.55 : 2.7,
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
                          icon: Icons.public,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                ArcadeActionButton(
                  label: 'PLAY GAME',
                  icon: Icons.play_arrow_rounded,
                  primary: true,
                  onPressed: () => context.push(FlappyBirdRoutes.game),
                ),
                const SizedBox(height: AppSpacing.sm),
                ArcadeActionButton(
                  label: 'LEADERBOARD',
                  icon: Icons.leaderboard_outlined,
                  onPressed: () => context.push(FlappyBirdRoutes.leaderboard),
                ),
                const SizedBox(height: AppSpacing.sm),
                ArcadeActionButton(
                  label: 'MY PROFILE',
                  icon: Icons.person_outline,
                  onPressed: () => context.push(FlappyBirdRoutes.profile),
                ),
                const SizedBox(height: AppSpacing.sm),
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

class _BirdMark extends StatelessWidget {
  const _BirdMark();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Flappy Bird Arcade logo',
    image: true,
    child: const SizedBox.square(
      dimension: 84,
      child: CustomPaint(painter: _BirdMarkPainter()),
    ),
  );
}

class _BirdMarkPainter extends CustomPainter {
  const _BirdMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = FlappyPalette.gold;
    final wing = Paint()..color = const Color(0xffff8f00);
    final outline = Paint()
      ..color = FlappyPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final oval = Rect.fromLTWH(8, 18, size.width - 20, size.height - 32);
    canvas.drawOval(oval, body);
    canvas.drawOval(oval, outline);
    canvas.drawOval(const Rect.fromLTWH(13, 37, 30, 24), wing);
    canvas.drawCircle(const Offset(58, 35), 11, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(62, 35),
      4,
      Paint()..color = FlappyPalette.ink,
    );
    final beak = Path()
      ..moveTo(68, 44)
      ..lineTo(84, 51)
      ..lineTo(68, 57)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xffff5722));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
