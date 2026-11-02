import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/team_page.dart';

/// Team tab: photos of the six developers. Owned by the integration owner.
class TeamFeature implements FeatureModule {
  const TeamFeature();

  @override
  String get id => 'team';

  @override
  FeatureTab? get tab => FeatureTab(
    order: 3,
    label: 'Team',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
    builder: (context) => const TeamPage(),
  );

  @override
  FeatureEntry? get entry => null;

  @override
  List<RouteBase> get routes => const [];
}
