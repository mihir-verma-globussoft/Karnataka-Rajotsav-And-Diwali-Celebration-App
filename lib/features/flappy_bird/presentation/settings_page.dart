import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/game_preferences.dart';
import '../flappy_bird_feature.dart';
import '../flappy_bird_providers.dart';
import 'widgets/arcade_widgets.dart';

final _packageInfoProvider = FutureProvider.autoDispose<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class FlappySettingsView extends ConsumerWidget {
  const FlappySettingsView({super.key});

  Future<void> _setSound(
    BuildContext context,
    WidgetRef ref,
    GamePreferences preferences,
    bool enabled,
  ) async {
    try {
      await ref
          .read(gamePreferencesRepositoryProvider)
          .save(preferences.copyWith(soundEffectsEnabled: enabled));
      ref.invalidate(gamePreferencesProvider);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sound preference could not be saved.')),
        );
      }
    }
  }

  Future<void> _setBackgroundMusic(
    BuildContext context,
    WidgetRef ref,
    GamePreferences preferences,
    bool enabled,
  ) async {
    try {
      await ref
          .read(gamePreferencesRepositoryProvider)
          .save(preferences.copyWith(backgroundMusicEnabled: enabled));
      ref.invalidate(gamePreferencesProvider);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background music preference could not be saved.'),
          ),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(flappyAuthRepositoryProvider).signOut();
      ref.invalidate(flappyAuthStateProvider);
      if (context.mounted) context.go(FlappyBirdRoutes.root);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not log out. Please try again.')),
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your profile, scores and game history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final pending = ref.read(pendingGameRepositoryProvider);
      for (final result in await pending.loadAll()) {
        await pending.remove(result.gameId);
      }
      await ref.read(flappyAuthRepositoryProvider).deleteAccount();
      ref.invalidate(flappyAuthStateProvider);
      if (context.mounted) context.go(FlappyBirdRoutes.root);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account could not be deleted.')),
        );
      }
    }
  }

  Future<void> _openPrivacy(BuildContext context, WidgetRef ref) async {
    final source = ref.read(appConfigProvider).privacyPolicyUrl;
    final uri = Uri.tryParse(source);
    if (uri == null || !uri.isScheme('https') || !await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy policy link is not configured.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(gamePreferencesProvider);
    final packageInfo = ref.watch(_packageInfoProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/flappy_bird/dashboard_background.png',
          fit: BoxFit.cover,
        ),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ArcadeNavigationHeader(
                title: 'Game ',
                highlight: 'Settings',
                onBack: context.canPop() ? context.pop : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _SettingsPanel(
                child: preferences.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(gamePreferencesProvider),
                  ),
                  data: (value) => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sound effects'),
                    subtitle: const Text('Flap and collision feedback'),
                    value: value.soundEffectsEnabled,
                    onChanged: (enabled) =>
                        _setSound(context, ref, value, enabled),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsPanel(
                child: preferences.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(gamePreferencesProvider),
                  ),
                  data: (value) => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.music_note_rounded),
                    title: const Text('Background music'),
                    subtitle: const Text('Festival music during gameplay'),
                    value: value.backgroundMusicEnabled,
                    onChanged: (enabled) =>
                        _setBackgroundMusic(context, ref, value, enabled),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsPanel(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy policy'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _openPrivacy(context, ref),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Application version'),
                      trailing: Text(
                        packageInfo.maybeWhen(
                          data: (value) =>
                              '${value.version}+${value.buildNumber}',
                          orElse: () => '…',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => _deleteAccount(context, ref),
                icon: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  'Delete account',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.child});

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
    ),
    child: IconTheme(
      data: const IconThemeData(color: FlappyPalette.festivalGold),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: FlappyPalette.white),
        child: child,
      ),
    ),
  );
}
