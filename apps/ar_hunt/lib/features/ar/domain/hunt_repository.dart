import 'hunt_models.dart';

/// Reasons the server gives for refusing a find.
class HuntClosedException implements Exception {
  const HuntClosedException();
}

class HuntItemGoneException implements Exception {
  const HuntItemGoneException();
}

/// Finds came faster than a person can walk. Safe to send again later.
class HuntTooFastException implements Exception {
  const HuntTooFastException();
}

abstract interface class HuntRepository {
  /// The signed-in player, or null when there is no session.
  String? get currentUserId;

  Future<HuntSnapshot> load();

  /// The top of the leaderboard, best first.
  Future<List<HuntLeader>> leaders({int limit = 50});

  /// Safe to repeat: a player can only score an item once.
  Future<CollectResult> collect(String itemId);

  /// True if the PIN was right, which makes this player an admin for good.
  /// The server stops accepting tries after too many wrong ones.
  Future<bool> unlockAdmin(String pin);

  /// Admin only; the server refuses everyone else.
  Future<HuntItem> placeItem({
    required String zone,
    required HuntItemKind kind,
    required double x,
    required double y,
    required double z,
    String? hint,
  });

  /// Admin only. Points already earned from the item are kept.
  Future<void> removeItem(String itemId);
}

/// Finds this phone has made but the server has not confirmed yet.
abstract interface class PendingFindsStore {
  Future<List<String>> load();

  Future<void> add(String itemId);

  Future<void> remove(String itemId);
}

/// Sends finds saved while offline. Never loses one the server has not seen.
Future<void> syncPendingFinds(
  HuntRepository repository,
  PendingFindsStore store,
) async {
  for (final itemId in await store.load()) {
    try {
      await repository.collect(itemId);
      await store.remove(itemId);
    } on HuntItemGoneException {
      await store.remove(itemId);
    } on HuntClosedException {
      await store.remove(itemId);
    } on HuntTooFastException {
      // Spacing has passed by the next load; keep it until then.
    } on Object {
      return;
    }
  }
}

/// Short sounds for good news. Follows the phone's silent switch.
abstract interface class HuntSounds {
  Future<void> found();

  Future<void> allFound();
}
