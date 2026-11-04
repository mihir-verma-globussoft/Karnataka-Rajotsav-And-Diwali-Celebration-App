import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/cinema_page.dart';
import 'presentation/culture_page.dart';
import 'presentation/discover_detail_page.dart';
import 'presentation/discover_page.dart';
import 'presentation/district_page.dart';
import 'presentation/learn_kannada_page.dart';
import 'presentation/nearby_page.dart';
import 'presentation/photo_credits_page.dart';
import 'presentation/quiz_page.dart';
import 'presentation/rajyotsava_page.dart';
import 'presentation/widgets/easter_egg_scope.dart';
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
    builder: (context) => _screen(const RajyotsavaPage()),
  );

  @override
  FeatureEntry? get entry => null;

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: RajyotsavaRoutes.quiz,
      name: 'rajyotsava_quiz',
      builder: (context, state) => _screen(const QuizPage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.learn,
      name: 'rajyotsava_learn',
      builder: (context, state) => _screen(const LearnKannadaPage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.discover,
      name: 'rajyotsava_discover',
      builder: (context, state) => _screen(const DiscoverPage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.photoCredits,
      name: 'rajyotsava_photo_credits',
      builder: (context, state) => _screen(const PhotoCreditsPage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.cinema,
      name: 'rajyotsava_cinema',
      builder: (context, state) => _screen(const CinemaPage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.culture,
      name: 'rajyotsava_culture',
      builder: (context, state) => _screen(const CulturePage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.nearby,
      name: 'rajyotsava_nearby',
      builder: (context, state) => _screen(const NearbyPage()),
    ),
    GoRoute(
      path: RajyotsavaRoutes.districtPattern,
      name: 'rajyotsava_district',
      builder: (context, state) =>
          _screen(DistrictPage(id: state.pathParameters['id'] ?? '')),
    ),
    GoRoute(
      path: RajyotsavaRoutes.discoverItemPattern,
      name: 'rajyotsava_discover_item',
      builder: (context, state) =>
          _screen(DiscoverDetailPage(id: state.pathParameters['id'] ?? '')),
    ),
  ];
}

/// Every Rajyotsava screen: the section's theme, and shake-to-discover
/// easter eggs while it is on screen.
Widget _screen(Widget page) =>
    RajyotsavaTheme(child: EasterEggScope(child: page));
