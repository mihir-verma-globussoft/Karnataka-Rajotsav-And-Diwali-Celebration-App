import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, User;

import '../../features/ar/domain/hunt_models.dart';
import '../../features/ar/domain/hunt_repository.dart';

/// `flutter run --dart-define=HUNT_DEMO=true` tries the AR on a phone with no
/// sign-in or server: you are an admin, and placed items last until the app
/// closes. Never part of a release build.
const huntDemoMode = !kReleaseMode && bool.fromEnvironment('HUNT_DEMO');

final huntDemoSession = Session(
  accessToken: 'demo',
  tokenType: 'bearer',
  user: const User(
    id: 'demo',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-11-04T00:00:00Z',
  ),
);

class DemoHuntRepository implements HuntRepository {
  final List<HuntItem> _items = [];
  final Set<String> _found = {};
  int _points = 0;
  int _nextId = 0;

  @override
  String? get currentUserId => 'demo';

  @override
  Future<HuntSnapshot> load() async => HuntSnapshot(
    isAdmin: true,
    isActive: true,
    points: _points,
    rank: _points == 0 ? null : 1,
    items: [
      for (final item in _items) item.copyWith(found: _found.contains(item.id)),
    ],
  );

  @override
  Future<List<HuntLeader>> leaders({int limit = 50}) async => [
    if (_points > 0)
      HuntLeader(rank: 1, userId: 'demo', username: 'You', points: _points),
    HuntLeader(
      rank: _points > 0 ? 2 : 1,
      userId: 'sample',
      username: 'Sample player',
      points: 10,
    ),
  ];

  @override
  Future<CollectResult> collect(String itemId) async {
    final isNew = _found.add(itemId);
    final points = isNew ? 15 : 0;
    _points += points;
    return CollectResult(
      points: points,
      firstFinder: isNew,
      alreadyFound: !isNew,
      isAdmin: false,
      totalPoints: _points,
    );
  }

  @override
  Future<HuntItem> placeItem({
    required String zone,
    required HuntItemKind kind,
    required double x,
    required double y,
    required double z,
    String? hint,
  }) async {
    final item = HuntItem(
      id: 'demo-${_nextId++}',
      zone: zone,
      kind: kind,
      x: x,
      y: y,
      z: z,
      hint: hint == null || hint.trim().isEmpty ? null : hint.trim(),
    );
    _items.add(item);
    return item;
  }

  @override
  Future<bool> unlockAdmin(String pin) async => true;

  @override
  Future<void> removeItem(String itemId) async =>
      _items.removeWhere((item) => item.id == itemId);
}
