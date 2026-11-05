/// What a player can find. Names are the wire values stored in the database.
enum HuntItemKind {
  diya,
  flag;

  static HuntItemKind parse(Object? wire) => values.firstWhere(
    (kind) => kind.name == wire,
    orElse: () => HuntItemKind.diya,
  );

  String get label => switch (this) {
    HuntItemKind.diya => 'diya',
    HuntItemKind.flag => 'Kannada flag',
  };
}

/// A printed poster on an office wall. Every item is measured from one poster,
/// so all phones agree on where it is.
class HuntZone {
  const HuntZone(this.id, this.label);

  final String id;
  final String label;

  /// The image the native AR view looks for. Keep it in sync with the printed
  /// poster: see `tool/ar_hunt/make_posters.py`.
  String get posterAsset => 'assets/ar/posters/$id.png';
}

const huntZones = [
  HuntZone('a', 'Start point A'),
  HuntZone('b', 'Start point B'),
  HuntZone('c', 'Start point C'),
  HuntZone('d', 'Start point D'),
];

/// Width of the printed artwork, in metres. The AR frameworks use it to judge
/// distance, so posters must be printed at 100% scale.
const huntPosterWidthMetres = 0.18;

HuntZone? huntZoneById(String id) {
  for (final zone in huntZones) {
    if (zone.id == id) return zone;
  }
  return null;
}

class HuntItem {
  const HuntItem({
    required this.id,
    required this.zone,
    required this.kind,
    required this.x,
    required this.y,
    required this.z,
    this.hint,
    this.found = false,
    this.scale = 1,
  });

  factory HuntItem.fromJson(Map<String, dynamic> json) => HuntItem(
    id: json['id'] as String,
    zone: json['zone'] as String,
    kind: HuntItemKind.parse(json['kind']),
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    z: (json['z'] as num).toDouble(),
    hint: json['hint'] as String?,
    found: json['found'] as bool? ?? false,
    scale: (json['scale'] as num?)?.toDouble() ?? 1,
  );

  final String id;
  final String zone;
  final HuntItemKind kind;

  /// Metres from the zone's poster: see `poster_lock.dart` for the axes.
  final double x;
  final double y;
  final double z;
  final String? hint;
  final bool found;

  /// The size the organiser chose, where 1 is the standard size.
  final double scale;

  HuntItem copyWith({bool? found}) => HuntItem(
    id: id,
    zone: zone,
    kind: kind,
    x: x,
    y: y,
    z: z,
    hint: hint,
    found: found ?? this.found,
    scale: scale,
  );
}

/// Everything the hub shows for the signed-in player.
class HuntSnapshot {
  const HuntSnapshot({
    required this.isAdmin,
    required this.isActive,
    required this.items,
    required this.points,
    this.rank,
  });

  final bool isAdmin;
  final bool isActive;
  final List<HuntItem> items;
  final int points;

  /// Position on the leaderboard; null until the first find.
  final int? rank;

  int get foundCount => items.where((item) => item.found).length;

  int countOf(HuntItemKind kind) =>
      items.where((item) => item.kind == kind).length;

  int foundOf(HuntItemKind kind) =>
      items.where((item) => item.kind == kind && item.found).length;
}

class CollectResult {
  const CollectResult({
    required this.points,
    required this.firstFinder,
    required this.alreadyFound,
    required this.isAdmin,
    required this.totalPoints,
  });

  factory CollectResult.fromJson(Map<String, dynamic> json) => CollectResult(
    points: json['points'] as int,
    firstFinder: json['first_finder'] as bool,
    alreadyFound: json['already_found'] as bool,
    isAdmin: json['is_admin'] as bool,
    totalPoints: json['total_points'] as int,
  );

  final int points;
  final bool firstFinder;
  final bool alreadyFound;

  /// Admins can test finding items, but never score.
  final bool isAdmin;
  final int totalPoints;
}

class HuntLeader {
  const HuntLeader({
    required this.rank,
    required this.userId,
    required this.username,
    required this.points,
    this.avatarUrl,
  });

  factory HuntLeader.fromJson(Map<String, dynamic> json) => HuntLeader(
    rank: (json['rank'] as num).toInt(),
    userId: json['user_id'] as String,
    username: json['username'] as String,
    points: (json['high_score'] as num).toInt(),
    avatarUrl: json['avatar_url'] as String?,
  );

  final int rank;
  final String userId;
  final String username;
  final int points;
  final String? avatarUrl;
}
