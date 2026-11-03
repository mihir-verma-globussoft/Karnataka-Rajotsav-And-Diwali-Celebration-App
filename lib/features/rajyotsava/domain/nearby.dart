import 'location.dart';
import 'models.dart';

/// A district with its distance from the person, when known.
class RankedDistrict {
  const RankedDistrict(this.district, this.distanceKm);

  final District district;

  /// Kilometres from the person's location, or null when it is unknown.
  final double? distanceKm;
}

/// Beyond this distance from the nearest district headquarters the person is
/// probably outside Karnataka.
const double outsideKarnatakaKm = 120;

/// Districts sorted nearest first when [from] is known, otherwise by name.
List<RankedDistrict> rankDistricts(List<District> districts, GeoPoint? from) {
  if (from == null) {
    return [for (final d in districts) RankedDistrict(d, null)]
      ..sort((a, b) => a.district.name.compareTo(b.district.name));
  }
  return [
    for (final d in districts)
      RankedDistrict(d, distanceKm(from, GeoPoint(d.latitude, d.longitude))),
  ]..sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
}

/// Whether [district] matches a search [query] (name, Kannada name,
/// headquarters or what it is known for), ignoring case.
bool matchesDistrict(District district, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return [
    district.name,
    district.kannadaName,
    district.headquarters,
    district.knownFor,
  ].any((field) => field.toLowerCase().contains(q));
}

/// Status of the "Use my location" flow.
enum NearbyStatus {
  idle,
  locating,
  found,
  denied,
  deniedForever,
  servicesOff,
  unavailable,
}

class NearbyState {
  const NearbyState(this.status, [this.point]);

  final NearbyStatus status;

  /// The person's location when [status] is [NearbyStatus.found].
  final GeoPoint? point;
}
