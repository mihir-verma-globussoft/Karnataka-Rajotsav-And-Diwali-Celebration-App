/// Route paths and tags owned by the Deepavali feature.
abstract final class DeepavaliRoutes {
  /// Every path must start with this prefix.
  static const String prefix = '/deepavali';

  static const String destination = '$prefix/destination/:id';
  static const String decorate = '$prefix/decorate';
  static const String photoBooth = '$prefix/photo-booth';

  static String destinationPath(String id) => '$prefix/destination/$id';

  static String heroTag(String id) => 'deepavali-destination-$id';
}
