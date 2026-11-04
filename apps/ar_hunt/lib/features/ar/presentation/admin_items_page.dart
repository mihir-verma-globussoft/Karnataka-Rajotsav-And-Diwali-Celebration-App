import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_value_view.dart';
import '../ar_providers.dart';
import '../domain/hunt_models.dart';
import 'widgets/hunt_widgets.dart';

/// Every placed item, for removing one without walking back to it.
class AdminItemsPage extends ConsumerWidget {
  const AdminItemsPage({super.key});

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    HuntItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text('Remove this ${item.kind.label}?'),
        content: const Text(
          'Players will no longer see it. Points they '
          'already earned from it stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(huntRepositoryProvider).removeItem(item.id);
      ref.invalidate(huntSnapshotProvider);
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(title: const Text('Placed items')),
    body: NightBackground(
      child: SafeArea(
        child: AsyncValueView<HuntSnapshot>(
          value: ref.watch(huntSnapshotProvider),
          onRetry: () => ref.invalidate(huntSnapshotProvider),
          isEmpty: (snapshot) => snapshot.items.isEmpty,
          emptyMessage: 'Nothing placed yet.',
          data: (snapshot) => ConstrainedBody(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: snapshot.items.length,
              itemBuilder: (context, index) {
                final item = snapshot.items[index];
                return ListTile(
                  leading: HuntItemArt(item.kind),
                  title: Text(huntZoneById(item.zone)?.label ?? item.zone),
                  subtitle: Text(item.hint ?? 'No clue'),
                  trailing: IconButton(
                    tooltip: 'Remove this ${item.kind.label}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _remove(context, ref, item),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
