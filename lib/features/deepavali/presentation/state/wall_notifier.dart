import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';
import '../../domain/greeting.dart' show GreetingCard;
import '../../domain/wish.dart';

/// What happened when a wish was added.
enum AddWishResult { saved, notSaved, empty }

/// The diya wall. Not autoDispose: the tab stays mounted, and the wall should
/// survive switching tabs.
class WallNotifier extends AsyncNotifier<WishWall> {
  @override
  Future<WishWall> build() async =>
      WishWall(await ref.read(wishStoreProvider).load());

  /// Lights a diya for [text]. The diya shows at once; if saving fails it
  /// still stays for this session and [AddWishResult.notSaved] is returned.
  Future<AddWishResult> add(String text, String from) async {
    final clean = tidyWish(text);
    if (clean == null) return AddWishResult.empty;
    final wall = await future;
    final nowMillis = ref.read(deepavaliNowProvider)().millisecondsSinceEpoch;
    final next = wall.add(
      Wish(
        id: wall.nextId(nowMillis),
        text: clean,
        from: GreetingCard.clean(from, wishNameMax),
        litAtMillis: nowMillis,
      ),
    );
    state = AsyncData(next);
    return _save(next);
  }

  /// Removes a wish. Returns false if the change could not be saved.
  Future<bool> remove(int id) async {
    final wall = await future;
    final next = wall.remove(id);
    state = AsyncData(next);
    return await _save(next) == AddWishResult.saved;
  }

  Future<AddWishResult> _save(WishWall wall) async {
    try {
      await ref.read(wishStoreProvider).save(wall.wishes);
      return AddWishResult.saved;
    } on Object {
      return AddWishResult.notSaved;
    }
  }
}

final wallProvider = AsyncNotifierProvider<WallNotifier, WishWall>(
  WallNotifier.new,
);
