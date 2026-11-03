import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rajyotsava_providers.dart';

/// Opens the maps app with directions to [destination]: Apple Maps on
/// iPhone, Google Maps on Android. The maps app routes from the current
/// location, or asks for a starting point when location is off.
class DirectionsButton extends ConsumerWidget {
  const DirectionsButton({
    required this.destination,
    required this.placeName,
    this.expanded = false,
    super.key,
  });

  /// Text searched in the maps app, e.g. "Hampi, Karnataka".
  final String destination;

  /// Name read out by screen readers, e.g. "Hampi".
  final String placeName;

  /// A labelled button instead of an icon-only one.
  final bool expanded;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ref
        .read(externalLinksProvider)
        .openDirections(destination);
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open a maps app.')),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tooltip = 'Directions to $placeName';
    if (expanded) {
      return Semantics(
        label: tooltip,
        excludeSemantics: true,
        child: FilledButton.icon(
          onPressed: () => _open(context, ref),
          icon: const Icon(Icons.directions),
          label: const Text('Get directions'),
        ),
      );
    }
    return IconButton(
      tooltip: tooltip,
      onPressed: () => _open(context, ref),
      icon: Icon(
        Icons.directions,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
