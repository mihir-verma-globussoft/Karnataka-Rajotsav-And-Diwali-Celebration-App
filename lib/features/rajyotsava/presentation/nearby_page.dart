import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/models.dart';
import '../domain/nearby.dart';
import '../rajyotsava_providers.dart';
import '../rajyotsava_routes.dart';
import 'widgets/rajyotsava_widgets.dart';

/// Near me: sorts Karnataka's districts by distance from the person's
/// location (asked only when they tap "Use my location"), or lets them
/// search and choose a district by hand.
class NearbyPage extends ConsumerStatefulWidget {
  const NearbyPage({super.key});

  @override
  ConsumerState<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends ConsumerState<NearbyPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final districts = ref.watch(rajyotsavaContentProvider).districts;
    final nearby = ref.watch(nearbyControllerProvider);
    final ranked = rankDistricts(
      districts,
      nearby.point,
    ).where((r) => matchesDistrict(r.district, _query)).toList();
    final located = nearby.status == NearbyStatus.found;

    return Scaffold(
      appBar: AppBar(title: const Text('Near me')),
      body: SafeArea(
        child: ConstrainedBody(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    _LocationCard(state: nearby),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const ValueKey('district-search'),
                      controller: _search,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search a district or town',
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() {
                                  _search.clear();
                                  _query = '';
                                }),
                              ),
                      ),
                    ),
                    SectionHeader(
                      title: located ? 'Nearest districts' : 'All districts',
                      kannada: 'ಜಿಲ್ಲೆಗಳು',
                    ),
                    if (ranked.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          'No district matches "$_query".',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                sliver: SliverList.builder(
                  itemCount: ranked.length,
                  itemBuilder: (context, i) => _DistrictCard(
                    ranked: ranked[i],
                    nearest: located && i == 0 && _query.isEmpty,
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

/// Explains the feature, offers "Use my location" and shows its outcome.
class _LocationCard extends ConsumerWidget {
  const _LocationCard({required this.state});

  final NearbyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = ref.read(nearbyControllerProvider.notifier);
    final locating = state.status == NearbyStatus.locating;
    final districts = ref.watch(rajyotsavaContentProvider).districts;

    final (
      String message,
      String? actionLabel,
      VoidCallback? action,
    ) = switch (state.status) {
      NearbyStatus.idle || NearbyStatus.locating => (
        'Use your location to sort Karnataka\'s districts by distance, '
            'or search and choose one below.',
        null,
        null,
      ),
      NearbyStatus.found => _foundMessage(districts, state),
      NearbyStatus.denied => (
        'Location permission was not given. You can still choose a '
            'district below.',
        null,
        null,
      ),
      NearbyStatus.deniedForever => (
        'Location is turned off for Globus Habba. Allow it in Settings, '
            'or choose a district below.',
        'Open settings',
        controller.openAppSettings,
      ),
      NearbyStatus.servicesOff => (
        'Location services are off on this device. Turn them on, or '
            'choose a district below.',
        'Location settings',
        controller.openLocationSettings,
      ),
      NearbyStatus.unavailable => (
        'We couldn\'t find your location right now. Try again, or '
            'choose a district below.',
        null,
        null,
      ),
    };

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBadge(icon: Icons.near_me),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Famous places near you',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                key: const ValueKey('nearby-message'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  key: const ValueKey('use-my-location'),
                  onPressed: locating ? null : controller.locate,
                  icon: locating
                      ? const SizedBox.square(
                          dimension: AppIconSizes.sm,
                          child: CircularProgressIndicator.adaptive(),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    locating
                        ? 'Finding you…'
                        : state.status == NearbyStatus.idle
                        ? 'Use my location'
                        : 'Try again',
                  ),
                ),
                if (actionLabel != null)
                  OutlinedButton(onPressed: action, child: Text(actionLabel)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Only approximate location is used, on this phone, and it is '
              'not saved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (String, String?, VoidCallback?) _foundMessage(
    List<District> districts,
    NearbyState state,
  ) {
    final ranked = rankDistricts(districts, state.point);
    if (ranked.isEmpty) return ('Location found.', null, null);
    final nearest = ranked.first;
    final km = nearest.distanceKm!.round();
    final message = nearest.distanceKm! > outsideKarnatakaKm
        ? 'You seem to be outside Karnataka. The nearest district is '
              '${nearest.district.name}, about $km km away.'
        : 'You are near ${nearest.district.name} '
              '(${nearest.district.kannadaName}), about $km km from '
              '${nearest.district.headquarters}.';
    return (message, null, null);
  }
}

class _DistrictCard extends StatelessWidget {
  const _DistrictCard({required this.ranked, required this.nearest});

  final RankedDistrict ranked;

  /// Highlights the closest district.
  final bool nearest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final district = ranked.district;
    final km = ranked.distanceKm;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: nearest ? scheme.tertiaryContainer : scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RajyotsavaRoutes.district(district.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IconBadge(
                icon: nearest ? Icons.my_location : Icons.location_city,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(district.name, style: theme.textTheme.titleMedium),
                    Text(
                      district.kannadaName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      district.knownFor,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (km != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        nearest
                            ? 'Nearest · ${km.round()} km'
                            : '${km.round()} km away',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
