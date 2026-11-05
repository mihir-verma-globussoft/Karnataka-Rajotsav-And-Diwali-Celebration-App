import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_value_view.dart';
import '../ar_feature.dart';
import '../ar_providers.dart';
import '../domain/ar_availability.dart';
import '../domain/hunt_models.dart';
import 'widgets/hunt_widgets.dart';

/// The hunt's home: your score, the way in, the leaderboard and, for admins,
/// the placing tools.
class ArPage extends ConsumerWidget {
  const ArPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Habba Hunt'),
        actions: [if (ref.watch(huntAdminToolsProvider)) const _AdminButton()],
      ),
      body: NightBackground(
        child: SafeArea(
          child: AsyncValueView<HuntSnapshot>(
            value: ref.watch(huntSnapshotProvider),
            onRetry: () => ref.invalidate(huntSnapshotProvider),
            data: (snapshot) => _Hub(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class _Hub extends ConsumerWidget {
  const _Hub({required this.snapshot});

  final HuntSnapshot snapshot;

  Future<void> _refresh(WidgetRef ref) {
    ref
      ..invalidate(huntLeadersProvider)
      ..invalidate(arAvailabilityProvider);
    return ref.refresh(huntSnapshotProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      RefreshIndicator.adaptive(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            ConstrainedBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Hero(),
                  const SizedBox(height: AppSpacing.md),
                  _ScoreCard(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.md),
                  _StartSection(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.md),
                  if (ref.watch(huntAdminToolsProvider)) ...[
                    _AdminCard(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (snapshot.items.isNotEmpty) ...[
                    _ZonesCard(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _LeadersCard(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.md),
                  const _HowToPlayCard(),
                  if (defaultTargetPlatform == TargetPlatform.android) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _ArCoreNotice(),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HuntItemArt(HuntItemKind.diya, size: AppIconSizes.hero),
            SizedBox(width: AppSpacing.md),
            HuntItemArt(HuntItemKind.flag, size: AppIconSizes.hero),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Diyas and Kannada flags are hidden all over the office.\n'
          'Find them with your camera.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.snapshot});

  final HuntSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = snapshot.items.length;
    final rank = snapshot.rank;
    return HuntCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                '${snapshot.points} points',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                rank == null ? 'Not ranked yet' : 'You are #$rank',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: snapshot.foundCount / total,
              minHeight: AppSizes.progressBar,
              borderRadius: AppRadius.xsAll,
              semanticsLabel: 'Hunt progress',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Text('Found ${snapshot.foundCount} of $total'),
                for (final kind in HuntItemKind.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HuntItemArt(kind, size: AppIconSizes.xs),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${snapshot.foundOf(kind)}/${snapshot.countOf(kind)}',
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Checks the camera and AR support, then opens [route].
Future<void> _openAr(BuildContext context, WidgetRef ref, String route) async {
  final platform = ref.read(arPlatformProvider);
  final result = await platform.prepare();
  if (!context.mounted) return;
  switch (result) {
    case ArAvailability.supported:
      await context.push<void>(route);
      if (!context.mounted) return;
      ref
        ..invalidate(huntSnapshotProvider)
        ..invalidate(huntLeadersProvider);
    case ArAvailability.cameraPermissionDenied:
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('Camera needed'),
          content: const Text(
            'The hunt shows diyas and flags through your camera. '
            'Nothing is recorded or sent anywhere.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                platform.openSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
    case ArAvailability.servicesNeedInstall:
    case ArAvailability.unsupportedDevice:
    case ArAvailability.unavailable:
      ref.invalidate(arAvailabilityProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_blockedMessage(result))));
  }
}

String _blockedMessage(ArAvailability availability) => switch (availability) {
  ArAvailability.servicesNeedInstall =>
    'Install Google Play Services for AR to play.',
  ArAvailability.unsupportedDevice =>
    'This phone does not support AR, but you can still follow the leaderboard.',
  _ => 'AR is not available right now. Please try again.',
};

class _StartSection extends ConsumerWidget {
  const _StartSection({required this.snapshot});

  final HuntSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = snapshot.items.length;
    if (!snapshot.isActive) {
      return const _Note(
        icon: Icons.nightlight_outlined,
        text: 'The hunt has closed. Thanks for playing!',
      );
    }
    if (total == 0) {
      return const _Note(
        icon: Icons.hourglass_empty,
        text: 'Nothing has been hidden yet. Check back soon!',
      );
    }
    if (snapshot.foundCount == total) {
      return const _Note(
        icon: Icons.celebration_outlined,
        text: 'You found everything! See how you did on the leaderboard.',
      );
    }
    final availability = ref.watch(arAvailabilityProvider).value;
    if (availability == ArAvailability.unsupportedDevice) {
      return _Note(
        icon: Icons.phonelink_erase_outlined,
        text: _blockedMessage(availability!),
      );
    }
    return FilledButton.icon(
      key: const ValueKey('start-hunting'),
      onPressed: () => _openAr(context, ref, ArRoutes.hunt),
      icon: const Icon(Icons.view_in_ar),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          snapshot.foundCount == 0 ? 'Start hunting' : 'Keep hunting',
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => HuntCard(
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _ZonesCard extends StatelessWidget {
  const _ZonesCard({required this.snapshot});

  final HuntSnapshot snapshot;

  @override
  Widget build(BuildContext context) => HuntCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Start points'),
        const SizedBox(height: AppSpacing.sm),
        for (final zone in huntZones)
          if (snapshot.items.any((item) => item.zone == zone.id))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  PosterThumb(zone: zone),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(zone.label)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(_progress(zone)),
                ],
              ),
            ),
      ],
    ),
  );

  String _progress(HuntZone zone) {
    final here = snapshot.items.where((item) => item.zone == zone.id);
    return '${here.where((item) => item.found).length}/${here.length}';
  }
}

class _LeadersCard extends ConsumerWidget {
  const _LeadersCard({required this.snapshot});

  final HuntSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final you = ref.watch(huntRepositoryProvider).currentUserId;
    final leaders = ref.watch(huntLeadersProvider);
    return HuntCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Leaderboard'),
          const SizedBox(height: AppSpacing.sm),
          leaders.when(
            skipLoadingOnReload: true,
            loading: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            error: (_, _) => TextButton.icon(
              onPressed: () => ref.invalidate(huntLeadersProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Could not load. Try again'),
            ),
            data: (rows) => rows.isEmpty
                ? const Text('No one on the board yet. Be the first!')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final leader in rows.take(5))
                        HuntLeaderRow(
                          leader: leader,
                          isYou: leader.userId == you,
                        ),
                      TextButton(
                        onPressed: () => context.push<void>(
                          snapshot.items.isNotEmpty &&
                                  snapshot.foundCount == snapshot.items.length
                              ? ArRoutes.celebration
                              : ArRoutes.leaderboard,
                        ),
                        child: const Text('See the full leaderboard'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _HowToPlayCard extends StatelessWidget {
  const _HowToPlayCard();

  @override
  Widget build(BuildContext context) => const HuntCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('How to play'),
        SizedBox(height: AppSpacing.sm),
        _Step(
          icon: Icons.photo_camera_outlined,
          text:
              'Find a Habba Hunt poster on an office wall and point your '
              'camera at it until it locks.',
        ),
        _Step(
          icon: Icons.directions_walk,
          text:
              'Walk around and follow the heat meter. Things appear when '
              'you are close.',
        ),
        _Step(
          icon: Icons.touch_app_outlined,
          text:
              'Tap a diya or flag to collect it. 10 points each, and 15 if '
              'you are the first to find it.',
        ),
        _Step(
          icon: Icons.health_and_safety_outlined,
          text: 'Look up as you walk. Mind people, stairs and cables.',
        ),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AppIconSizes.sm,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

Future<void> _unlockAdmin(BuildContext context, WidgetRef ref) async {
  final pin = await showDialog<String>(
    context: context,
    builder: (context) => const _PinDialog(),
  );
  if (pin == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));
  try {
    final unlocked = await ref.read(huntRepositoryProvider).unlockAdmin(pin);
    if (unlocked) {
      ref.invalidate(huntSnapshotProvider);
      say('Unlocked. You can place items now.');
    } else {
      say('That PIN is not right.');
    }
  } on AppFailure catch (error) {
    say(error.message);
  }
}

/// The way in for the organiser, always in the top bar: asks for the PIN, and
/// once unlocked opens the placing screen.
class _AdminButton extends ConsumerWidget {
  const _AdminButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(huntSnapshotProvider).value?.isAdmin ?? false;
    return IconButton(
      tooltip: isAdmin ? 'Place diyas and flags' : 'Admin: enter PIN',
      icon: Icon(
        isAdmin
            ? Icons.admin_panel_settings
            : Icons.admin_panel_settings_outlined,
      ),
      onPressed: () => isAdmin
          ? _openAr(context, ref, ArRoutes.place)
          : _unlockAdmin(context, ref),
    );
  }
}

class _AdminCard extends ConsumerWidget {
  const _AdminCard({required this.snapshot});

  final HuntSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!snapshot.isAdmin) {
      return HuntCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Admin'),
            const SizedBox(height: AppSpacing.xs),
            const Text('Enter the organiser PIN to place diyas and flags.'),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              key: const ValueKey('admin-unlock'),
              onPressed: () => _unlockAdmin(context, ref),
              icon: const Icon(Icons.lock_open),
              label: const Text('Enter PIN'),
            ),
          ],
        ),
      );
    }
    return HuntCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Admin'),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Your own finds never score, so you can test freely. Players see '
            'changes the next time they open the hunt.',
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonalIcon(
            key: const ValueKey('admin-place'),
            onPressed: () => _openAr(context, ref, ArRoutes.place),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Place diyas and flags'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const ValueKey('admin-items'),
            onPressed: () async {
              await context.push<void>(ArRoutes.items);
              ref.invalidate(huntSnapshotProvider);
            },
            icon: const Icon(Icons.list_alt),
            label: Text('All placed items (${snapshot.items.length})'),
          ),
        ],
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Organiser PIN'),
    content: TextField(
      key: const ValueKey('admin-pin'),
      controller: _pin,
      autofocus: true,
      obscureText: true,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'PIN'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('admin-pin-submit'),
        onPressed: () => Navigator.pop(context, _pin.text.trim()),
        child: const Text('Unlock'),
      ),
    ],
  );
}

/// Required wording for apps using ARCore:
/// https://developers.google.com/ar/develop/privacy-requirements
class _ArCoreNotice extends StatelessWidget {
  const _ArCoreNotice();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        'This application runs on Google Play Services for AR (ARCore), '
        'which is provided by Google.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      TextButton(
        onPressed: () => launchUrl(
          Uri.parse('https://policies.google.com/privacy'),
          mode: LaunchMode.externalApplication,
        ),
        child: const Text('Google Privacy Policy'),
      ),
    ],
  );
}
