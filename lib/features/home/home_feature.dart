import 'package:go_router/go_router.dart';

import '../../app/feature_module.dart';
import 'presentation/home_page.dart';

/// Route paths for this feature. Other features link here, never to literals.
abstract final class HomeRoutes {
  static const String home = '/';
}

/// App shell: the landing screen listing every registered feature.
class HomeFeature implements FeatureModule {
  const HomeFeature();

  @override
  String get id => 'home';

  @override
  FeatureTab? get tab => null;

  @override
  FeatureEntry? get entry => null;

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: HomeRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
  ];
}
