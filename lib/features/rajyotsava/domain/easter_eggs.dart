import 'dart:math';

/// Groups of Karnataka collectibles.
enum EggCategory {
  personality('Personalities', 'ಮಹನೀಯರು'),
  place('Places', 'ಸ್ಥಳಗಳು'),
  culture('Culture', 'ಸಂಸ್ಕೃತಿ'),
  nature('Nature', 'ಪ್ರಕೃತಿ');

  const EggCategory(this.label, this.kannada);

  final String label;
  final String kannada;
}

/// How special a collectible looks: legendary cards get a gold foil.
enum EggRarity {
  rare('Rare'),
  legendary('Legendary');

  const EggRarity(this.label);

  final String label;
}

/// A hidden Karnataka collectible, revealed as a two-sided card.
class Collectible {
  const Collectible({
    required this.id,
    required this.category,
    required this.rarity,
    required this.title,
    required this.kannadaTitle,
    required this.tagline,
    required this.history,
    required this.facts,
    required this.importance,
    required this.kannadaDescription,
    required this.englishDescription,
    this.photoKey,
  });

  /// Stable id, saved with discoveries; never change it once shipped.
  final String id;
  final EggCategory category;
  final EggRarity rarity;
  final String title;
  final String kannadaTitle;

  /// One line on the front of the card.
  final String tagline;

  /// Historical background (back of the card).
  final String history;

  /// Short facts, dates and achievements.
  final List<String> facts;

  /// Why it matters to Karnataka.
  final String importance;
  final String kannadaDescription;
  final String englishDescription;

  /// Key of a bundled photo in `RajyotsavaPhotos` (stars, discover or
  /// eggs map); null shows the category artwork.
  final String? photoKey;
}

/// When a collectible was first found and how often it has been found.
class Discovery {
  const Discovery({required this.discoveredAt, this.count = 1});

  final DateTime discoveredAt;
  final int count;

  Discovery foundAgain() =>
      Discovery(discoveredAt: discoveredAt, count: count + 1);

  Map<String, Object> toJson() => {
    'at': discoveredAt.toUtc().toIso8601String(),
    'count': count,
  };

  static Discovery? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = DateTime.tryParse('${json['at']}');
    final count = json['count'];
    if (at == null || count is! int || count < 1) return null;
    return Discovery(discoveredAt: at, count: count);
  }
}

/// Saved discoveries, by collectible id.
abstract interface class EasterEggStore {
  Future<Map<String, Discovery>> load();

  Future<void> save(Map<String, Discovery> discoveries);
}

/// What a discovery reveals.
sealed class Reveal {
  const Reveal();
}

/// A collectible the person had not found before.
class NewCollectible extends Reveal {
  const NewCollectible(this.collectible);
  final Collectible collectible;
}

/// Every collectible has been found: the completion card.
class CollectionComplete extends Reveal {
  const CollectionComplete();
}

/// Picks a random collectible that has not been discovered yet, or null
/// when all have been. Pure, so it is easy to test.
Collectible? pickUndiscovered(
  List<Collectible> all,
  Set<String> discovered,
  Random random,
) {
  final remaining = [
    for (final c in all)
      if (!discovered.contains(c.id)) c,
  ];
  if (remaining.isEmpty) return null;
  return remaining[random.nextInt(remaining.length)];
}
