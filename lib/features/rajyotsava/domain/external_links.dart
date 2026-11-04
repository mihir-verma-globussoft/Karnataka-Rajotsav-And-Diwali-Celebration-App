/// Opens other apps: maps for directions, YouTube for songs and folk arts.
abstract interface class ExternalLinks {
  /// Opens the device's maps app with directions to [destination] (a place
  /// name or address). The maps app starts from the current location when it
  /// can, and otherwise asks for a starting point. Returns false when no app
  /// could open it.
  Future<bool> openDirections(String destination);

  /// Opens YouTube (app or browser) searching for [query]. Returns false
  /// when nothing could open it.
  Future<bool> openYouTubeSearch(String query);
}

/// Directions link builders, kept pure so they are easy to test.
abstract final class MapLinks {
  /// Apple Maps: always installed on iPhone; `daddr` alone means "from my
  /// location" (or asks for a start when location is off).
  static Uri appleMaps(String destination) =>
      Uri.https('maps.apple.com', '/', {'daddr': destination, 'dirflg': 'd'});

  /// Google Maps universal link: opens the Google Maps app on Android (or the
  /// browser), from the current location when available.
  static Uri googleMaps(String destination) => Uri.https(
    'www.google.com',
    '/maps/dir/',
    {'api': '1', 'destination': destination},
  );

  static Uri youTubeSearch(String query) =>
      Uri.https('www.youtube.com', '/results', {'search_query': query});
}
