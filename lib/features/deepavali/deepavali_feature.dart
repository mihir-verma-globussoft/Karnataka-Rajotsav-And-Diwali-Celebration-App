import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'deepavali_routes.dart';
import 'presentation/deepavali_page.dart';
import 'presentation/screens/destination_detail_screen.dart';

export 'deepavali_routes.dart';

class DeepavaliFeature implements FeatureModule {
  const DeepavaliFeature();

  @override
  String get id => 'deepavali';

  @override
  FeatureTab? get tab => FeatureTab(
    order: 1,
    label: 'Deepavali',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome,
    builder: (context) => const DeepavaliPage(),
  );

  @override
  FeatureEntry? get entry => null;

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: DeepavaliRoutes.destination,
      builder: (context, state) =>
          DestinationDetailScreen(id: state.pathParameters['id'] ?? ''),
    ),
  ];
}
