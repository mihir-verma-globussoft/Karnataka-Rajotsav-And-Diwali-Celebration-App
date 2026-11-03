import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/discover_detail_page.dart';
import 'presentation/discover_page.dart';
import 'presentation/district_page.dart';
import 'presentation/learn_kannada_page.dart';
import 'presentation/nearby_page.dart';
import 'presentation/quiz_page.dart';
import 'presentation/rajyotsava_page.dart';
import 'presentation/widgets/rajyotsava_widgets.dart';
import 'rajyotsava_routes.dart';

export 'rajyotsava_routes.dart';

class RajyotsavaFeature implements FeatureModule {
  const RajyotsavaFeature();

  @override
  String get id => 'rajyotsava';

  @override
  FeatureTab? get tab => FeatureTab(
    order: 0,
    label: 'Rajyotsava',
    icon: Icons.temple_hindu_outlined,
    selectedIcon: Icons.temple_hindu,
    builder: (context) => const RajyotsavaTheme(child: RajyotsavaPage()),
  );

  @override
  FeatureEntry? get entry => null;

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: RajyotsavaRoutes.quiz,
      name: 'rajyotsava_quiz',
      builder: (context, state) => const RajyotsavaTheme(child: QuizPage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.learn,
      name: 'rajyotsava_learn',
      builder: (context, state) =>
          const RajyotsavaTheme(child: LearnKannadaPage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.discover,
      name: 'rajyotsava_discover',
      builder: (context, state) => const RajyotsavaTheme(child: DiscoverPage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.nearby,
      name: 'rajyotsava_nearby',
      builder: (context, state) => const RajyotsavaTheme(child: NearbyPage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.districtPattern,
      name: 'rajyotsava_district',
      builder: (context, state) => RajyotsavaTheme(
        child: DistrictPage(id: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: RajyotsavaRoutes.discoverItemPattern,
      name: 'rajyotsava_discover_item',
      builder: (context, state) => RajyotsavaTheme(
        child: DiscoverDetailPage(id: state.pathParameters['id'] ?? ''),
      ),
    ),
  ];
}
