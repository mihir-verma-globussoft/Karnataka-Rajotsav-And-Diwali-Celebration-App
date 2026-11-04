import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../flappy_bird_feature.dart';
import '../flappy_bird_providers.dart';
import 'widgets/arcade_widgets.dart';

class PlayerProfileView extends ConsumerWidget {
  const PlayerProfileView({super.key});

  Future<void> _editUsername(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Username',
            helperText: 'Use 3–24 characters.',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !context.mounted) return;
    try {
      await ref.read(playerRepositoryProvider).updateUsername(value);
      ref
        ..invalidate(dashboardProvider)
        ..invalidate(playerProfileProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Username updated.')));
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_message(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/flappy_bird/dashboard_background.png',
        fit: BoxFit.cover,
      ),
      SafeArea(
        child: ref
            .watch(dashboardProvider)
            .when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(dashboardProvider),
              ),
              data: (data) => RefreshIndicator.adaptive(
                onRefresh: () async {
                  ref.invalidate(dashboardProvider);
                  await ref.read(dashboardProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () =>
                              context.canPop() ? context.pop() : null,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: FlappyPalette.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text.rich(
                          TextSpan(
                            text: 'My ',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: FlappyPalette.white,
                                  fontWeight: FontWeight.w800,
                                ),
                            children: const [
                              TextSpan(
                                text: 'Profile',
                                style: TextStyle(
                                  color: FlappyPalette.festivalGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ProfilePanel(
                      child: Column(
                        children: [
                          PlayerAvatar(
                            username: data.profile.username,
                            avatarUrl: data.profile.displayAvatarUrl,
                            radius: 48,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            data.profile.username,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: FlappyPalette.white),
                          ),
                          if (data.profile.email != null)
                            Text(
                              data.profile.email!,
                              style: const TextStyle(
                                color: FlappyPalette.white70,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          _ProfileAction(
                            onPressed: () => _editUsername(
                              context,
                              ref,
                              data.profile.username,
                            ),
                            icon: Icons.edit_outlined,
                            label: 'Edit username',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _ProfileAction(
                            onPressed: () =>
                                context.push(FlappyBirdRoutes.character),
                            icon: Icons.camera_alt_outlined,
                            label: 'Retake character photo',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailRow(
                      label: 'Personal best',
                      value: '${data.stats.highScore}',
                    ),
                    _DetailRow(
                      label: 'Games played',
                      value: '${data.stats.totalGames}',
                    ),
                    _DetailRow(
                      label: 'Total score',
                      value: '${data.stats.totalScore}',
                    ),
                    _DetailRow(
                      label: 'Global rank',
                      value: data.stats.globalRank == null
                          ? 'Unranked'
                          : '#${data.stats.globalRank}',
                    ),
                    _DetailRow(
                      label: 'Member since',
                      value: _date(data.profile.createdAt),
                    ),
                  ],
                ),
              ),
            ),
      ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: _ProfilePanel(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: FlappyPalette.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: FlappyPalette.festivalGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      borderRadius: AppRadius.lgAll,
      border: Border.all(
        color: FlappyPalette.sparkPink.withValues(alpha: ArcadeOpacity.border),
        width: ArcadeSizes.goldBorder,
      ),
      gradient: LinearGradient(
        colors: [
          FlappyPalette.panel.withValues(alpha: ArcadeOpacity.card),
          FlappyPalette.sky.withValues(alpha: ArcadeOpacity.splashHighlight),
        ],
      ),
      boxShadow: const [
        BoxShadow(color: FlappyPalette.glowSoft, blurRadius: AppSpacing.md),
      ],
    ),
    child: child,
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: FlappyPalette.festivalGold),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: FlappyPalette.white,
        side: const BorderSide(color: FlappyPalette.festivalGold),
      ),
    ),
  );
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _message(Object error) => error.toString().contains('3–24')
    ? 'Username must be 3–24 characters.'
    : 'Username could not be updated.';
