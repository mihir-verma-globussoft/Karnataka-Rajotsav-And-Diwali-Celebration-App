import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/permission_denied_view.dart';
import '../../../core/widgets/state_views.dart';
import '../ar_providers.dart';
import '../domain/ar_availability.dart';

/// Entry screen for the AR module. Real AR rendering lives in native code and
/// is not implemented yet; this screen only reports availability.
class ArPage extends ConsumerWidget {
  const ArPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Karnataka AR')),
    body: SafeArea(
      child: AsyncValueView<ArAvailability>(
        value: ref.watch(arAvailabilityProvider),
        onRetry: () => ref.invalidate(arAvailabilityProvider),
        data: (availability) => switch (availability) {
          ArAvailability.supported => const EmptyView(
            message: 'AR is available. The experience is not implemented yet.',
            icon: Icons.view_in_ar_outlined,
          ),
          ArAvailability.cameraPermissionDenied => PermissionDeniedView(
            message: 'Camera access is needed for AR.',
            onRetry: () => ref.invalidate(arAvailabilityProvider),
          ),
          ArAvailability.servicesNeedInstall => const EmptyView(
            message:
                'Install or update Google Play Services for AR to continue.',
            icon: Icons.system_update_outlined,
          ),
          ArAvailability.unsupportedDevice => const EmptyView(
            message: 'This device does not support AR.',
            icon: Icons.phonelink_erase_outlined,
          ),
          ArAvailability.unavailable => const EmptyView(
            message: 'AR is not available right now.',
            icon: Icons.view_in_ar_outlined,
          ),
        },
      ),
    ),
  );
}
