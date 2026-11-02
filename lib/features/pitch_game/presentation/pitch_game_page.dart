import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';

/// Scaffold only: the module owner replaces this with the real screen.
class PitchGamePage extends StatelessWidget {
  const PitchGamePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('High Pitch / Low Pitch')),
    body: const SafeArea(
      child: EmptyView(
        message: 'Not implemented yet.',
        icon: Icons.construction_outlined,
      ),
    ),
  );
}
