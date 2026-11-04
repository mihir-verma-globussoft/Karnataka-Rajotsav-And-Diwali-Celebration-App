import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'domain/hunt_rules.dart';
import 'presentation/admin_items_page.dart';
import 'presentation/ar_page.dart';
import 'presentation/ar_theme.dart';
import 'presentation/hunt_page.dart';
import 'presentation/leaderboard_page.dart';
import 'presentation/place_page.dart';

abstract final class ArRoutes {
  static const String root = '/ar';
  static const String hunt = '/ar/hunt';
  static const String leaderboard = '/ar/leaderboard';
  static const String place = '/ar/place';
  static const String items = '/ar/items';
}

class ArFeature implements FeatureModule {
  const ArFeature({this.adminTools = huntAdminBuild});

  /// Off in the user build, which then has no routes to the admin screens.
  final bool adminTools;

  @override
  String get id => 'ar';

  @override
  FeatureTab? get tab => null;

  @override
  FeatureEntry? get entry => const FeatureEntry(
    title: 'AR Game',
    subtitle: 'Find AR diyas and Kannada flags around the office',
    icon: Icons.view_in_ar_outlined,
    path: ArRoutes.root,
    group: FeatureGroups.games,
    order: 2,
    image: 'assets/ar/banner.png',
  );

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: ArRoutes.root,
      name: 'ar',
      builder: (context, state) => _themed(const ArPage()),
    ),
    GoRoute(
      path: ArRoutes.hunt,
      builder: (context, state) => _themed(const HuntPage()),
    ),
    GoRoute(
      path: ArRoutes.leaderboard,
      builder: (context, state) => _themed(const LeaderboardPage()),
    ),
    if (adminTools) ...[
      GoRoute(
        path: ArRoutes.place,
        builder: (context, state) => _themed(const PlacePage()),
      ),
      GoRoute(
        path: ArRoutes.items,
        builder: (context, state) => _themed(const AdminItemsPage()),
      ),
    ],
  ];

  static Widget _themed(Widget page) => Theme(data: ArTheme.data, child: page);
}
