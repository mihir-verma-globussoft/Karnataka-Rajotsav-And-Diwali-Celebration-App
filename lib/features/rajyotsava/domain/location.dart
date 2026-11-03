import 'dart:math';

/// A point on Earth in decimal degrees.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Great-circle distance between two points in kilometres (haversine).
double distanceKm(GeoPoint a, GeoPoint b) {
  const earthRadiusKm = 6371.0;
  double rad(double degrees) => degrees * pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLon = rad(b.longitude - a.longitude);
  final h =
      pow(sin(dLat / 2), 2) +
      cos(rad(a.latitude)) * cos(rad(b.latitude)) * pow(sin(dLon / 2), 2);
  return 2 * earthRadiusKm * asin(sqrt(h));
}

/// Outcome of asking the device for its location.
sealed class LocationResult {
  const LocationResult();
}

class LocationFound extends LocationResult {
  const LocationFound(this.point);
  final GeoPoint point;
}

/// The person declined; asking again is allowed.
class LocationDenied extends LocationResult {
  const LocationDenied();
}

/// The person declined permanently; only the system settings can change it.
class LocationDeniedForever extends LocationResult {
  const LocationDeniedForever();
}

/// Location services are switched off on the device.
class LocationServicesOff extends LocationResult {
  const LocationServicesOff();
}

/// No fix could be obtained (timeout, no provider, plugin error).
class LocationUnavailable extends LocationResult {
  const LocationUnavailable();
}

/// Device location, asked only when the person taps "Use my location".
abstract interface class LocationService {
  /// Asks for permission if needed, then returns an approximate position.
  Future<LocationResult> currentLocation();

  /// Opens this app's page in the system settings.
  Future<void> openAppSettings();

  /// Opens the system location settings.
  Future<void> openLocationSettings();
}
