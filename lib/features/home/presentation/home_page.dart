import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/feature_module.dart';
import '../../../app/providers.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = [
      for (final m in ref.watch(featureModulesProvider))
        if (m.entry != null) m.entry!,
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rajotsav & Diwali'),
        actions: const [_ThemeModeButton()],
      ),
      body: SafeArea(
        child: ConstrainedBody(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _EntryCard(entry: entries[i]),
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final FeatureEntry entry;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.all(AppSpacing.md),
      leading: Icon(entry.icon, size: 32),
      title: Text(entry.title),
      subtitle: Text(entry.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(entry.path),
    ),
  );
}

class _ThemeModeButton extends ConsumerWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      icon: const Icon(Icons.brightness_6_outlined),
      initialValue: mode,
      onSelected: ref.read(themeModeProvider.notifier).set,
      itemBuilder: (_) => const [
        PopupMenuItem(value: ThemeMode.system, child: Text('System')),
        PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
        PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
      ],
    );
  }
}
