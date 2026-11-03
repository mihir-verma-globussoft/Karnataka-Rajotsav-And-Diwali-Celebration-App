/// Route paths of the Rajyotsava module. Every path starts with `/rajyotsava`.
abstract final class RajyotsavaRoutes {
  static const String prefix = '/rajyotsava';
  static const String quiz = '$prefix/quiz';
  static const String learn = '$prefix/learn';
  static const String discover = '$prefix/discover';

  /// Pattern for one Discover item; build links with [discoverItem].
  static const String discoverItemPattern = '$discover/:id';

  static String discoverItem(String id) => '$discover/$id';
}
