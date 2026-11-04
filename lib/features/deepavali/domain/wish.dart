import 'text_tools.dart';

/// Longest wish, in characters.
const int wishMax = 80;

/// Longest name on a wish.
const int wishNameMax = 30;

/// Wishes kept on the wall; the oldest go first.
const int wallMax = 50;

/// One wish and the diya lit for it. Wishes live on this device only.
class Wish {
  const Wish({
    required this.id,
    required this.text,
    required this.from,
    required this.litAtMillis,
  });

  /// Unique within the wall.
  final int id;
  final String text;

  /// Optional name; empty when none.
  final String from;

  /// When it was lit, as milliseconds since the epoch.
  final int litAtMillis;

  DateTime get litAt => DateTime.fromMillisecondsSinceEpoch(litAtMillis);

  Map<String, Object> toJson() => {
    'id': id,
    'text': text,
    'from': from,
    'litAt': litAtMillis,
  };

  /// Reads a stored wish, or returns null if [json] is damaged. Text is
  /// tidied again, so a hand-edited or corrupted store can never put an
  /// over-long wish on the wall.
  static Wish? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final text = json['text'];
    final from = json['from'];
    final at = json['litAt'];
    if (id is! int || text is! String || at is! int) return null;
    final clean = cleanText(text, wishMax);
    if (clean.isEmpty) return null;
    return Wish(
      id: id,
      text: clean,
      from: from is String ? cleanText(from, wishNameMax) : '',
      litAtMillis: at,
    );
  }
}

/// The tidied wish text, or null if nothing is left after tidying.
String? tidyWish(String text) {
  final clean = cleanText(text, wishMax);
  return clean.isEmpty ? null : clean;
}

/// The wall of lit diyas: newest first, at most [wallMax]. Immutable.
class WishWall {
  WishWall([List<Wish> wishes = const []])
    : wishes = List<Wish>.unmodifiable(
        wishes.length > wallMax ? wishes.sublist(0, wallMax) : wishes,
      );

  /// Newest first.
  final List<Wish> wishes;

  bool get isEmpty => wishes.isEmpty;
  int get count => wishes.length;

  /// An id no wish on the wall uses.
  int nextId(int candidate) {
    var id = candidate;
    final used = {for (final w in wishes) w.id};
    while (used.contains(id)) {
      id++;
    }
    return id;
  }

  /// Puts a new wish at the front; the oldest fall off past [wallMax].
  WishWall add(Wish wish) => WishWall([wish, ...wishes]);

  WishWall remove(int id) => WishWall([
    for (final w in wishes)
      if (w.id != id) w,
  ]);

  Wish? byId(int id) {
    for (final w in wishes) {
      if (w.id == id) return w;
    }
    return null;
  }
}
