import 'wish.dart';

/// Keeps the wall between launches. Implementations must not throw from
/// [load] (a damaged store reads as empty); [save] may throw so the app can
/// say the wish was not saved.
abstract interface class WishStore {
  Future<List<Wish>> load();
  Future<void> save(List<Wish> wishes);
}
