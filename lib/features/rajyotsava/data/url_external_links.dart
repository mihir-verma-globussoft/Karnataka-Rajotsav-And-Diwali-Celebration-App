import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/external_links.dart';

/// [ExternalLinks] using url_launcher: Apple Maps on iOS, Google Maps on
/// Android, and YouTube in its app when installed.
class UrlExternalLinks implements ExternalLinks {
  const UrlExternalLinks();

  @override
  Future<bool> openDirections(String destination) => _open(
    defaultTargetPlatform == TargetPlatform.iOS
        ? MapLinks.appleMaps(destination)
        : MapLinks.googleMaps(destination),
  );

  @override
  Future<bool> openYouTubeSearch(String query) =>
      _open(MapLinks.youTubeSearch(query));

  Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
