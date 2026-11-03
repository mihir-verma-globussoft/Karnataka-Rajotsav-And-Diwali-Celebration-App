import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../domain/location.dart';

/// [LocationService] using the platform location APIs (Core Location on iOS,
/// fused/network location on Android). Asks for "while using the app"
/// permission only, and only approximate accuracy: enough to find the
/// nearest district.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  /// How long to wait for a fresh fix before using the last known one.
  static const Duration _timeLimit = Duration(seconds: 20);

  @override
  Future<LocationResult> currentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationServicesOff();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.deniedForever:
          return const LocationDeniedForever();
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return const LocationDenied();
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: _timeLimit,
          ),
        );
        return LocationFound(GeoPoint(position.latitude, position.longitude));
      } on TimeoutException {
        final last = await Geolocator.getLastKnownPosition();
        return last == null
            ? const LocationUnavailable()
            : LocationFound(GeoPoint(last.latitude, last.longitude));
      }
    } on Object {
      return const LocationUnavailable();
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
