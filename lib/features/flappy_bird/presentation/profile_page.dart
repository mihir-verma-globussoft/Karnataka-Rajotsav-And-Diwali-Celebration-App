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
  Widget build(BuildContext context, WidgetRef ref) => ArcadeBackground(
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
                ArcadePanel(
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
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (data.profile.email != null) Text(data.profile.email!),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _editUsername(context, ref, data.profile.username),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit username'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.push(FlappyBirdRoutes.character),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Retake character photo'),
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
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: ArcadePanel(
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
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
