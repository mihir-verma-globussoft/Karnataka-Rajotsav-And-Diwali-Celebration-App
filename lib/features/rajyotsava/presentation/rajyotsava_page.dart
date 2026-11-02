import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';

/// Scaffold only: the module owner replaces this with the real screen.
class RajyotsavaPage extends StatelessWidget {
  const RajyotsavaPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Karnataka Rajyotsava')),
    body: const SafeArea(
      child: EmptyView(
        message: 'Not implemented yet.',
        icon: Icons.construction_outlined,
      ),
    ),
  );
}
