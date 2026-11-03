/// Plain data types for the Rajyotsava module. No Flutter imports here.
library;

/// A multiple-choice quiz question.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  final String id;
  final String question;
  final List<String> options;

  /// Index into [options] of the correct answer.
  final int answerIndex;

  /// Shown after the person answers.
  final String explanation;

  String get answer => options[answerIndex];
}

/// One letter of the Kannada alphabet.
class KannadaLetter {
  const KannadaLetter(this.letter, this.sound);

  /// The letter in Kannada script, e.g. `ಅ`.
  final String letter;

  /// Latin transliteration, e.g. `a`.
  final String sound;
}

/// Groups for [KannadaPhrase].
enum PhraseCategory {
  greetings('Greetings', 'ಶುಭಾಶಯಗಳು'),
  everyday('Everyday', 'ದಿನನಿತ್ಯ'),
  festival('Festival', 'ಹಬ್ಬ');

  const PhraseCategory(this.label, this.kannada);

  final String label;
  final String kannada;
}

/// A Kannada word or phrase with its pronunciation and meaning.
class KannadaPhrase {
  const KannadaPhrase({
    required this.kannada,
    required this.pronunciation,
    required this.meaning,
    required this.category,
  });

  final String kannada;
  final String pronunciation;
  final String meaning;
  final PhraseCategory category;
}

/// A number from 1 to 10 in Kannada.
class KannadaNumber {
  const KannadaNumber({
    required this.value,
    required this.numeral,
    required this.word,
    required this.pronunciation,
  });

  final int value;

  /// Kannada digit(s), e.g. `೧`.
  final String numeral;

  /// Kannada word, e.g. `ಒಂದು`.
  final String word;
  final String pronunciation;
}

/// Categories on the Discover Karnataka screen.
enum DiscoverCategory {
  places('Places', 'ಸ್ಥಳಗಳು'),
  food('Food', 'ಆಹಾರ'),
  culture('Culture', 'ಸಂಸ್ಕೃತಿ'),
  people('People', 'ಮಹನೀಯರು');

  const DiscoverCategory(this.label, this.kannada);

  final String label;
  final String kannada;
}

/// What a [DiscoverItem] is, used to pick its icon.
enum DiscoverKind {
  monument,
  temple,
  waterfall,
  nature,
  sweet,
  dish,
  festival,
  art,
  craft,
  sport,
  writer,
  leader,
  artist,
  engineer,
}

/// A place, food, tradition or person shown on Discover Karnataka.
class DiscoverItem {
  const DiscoverItem({
    required this.id,
    required this.name,
    required this.kannadaName,
    required this.category,
    required this.kind,
    required this.tagline,
    required this.location,
    required this.description,
    required this.highlights,
    this.mapQuery,
  });

  /// URL-safe id, used in the route `/rajyotsava/discover/<id>`.
  final String id;
  final String name;
  final String kannadaName;
  final DiscoverCategory category;
  final DiscoverKind kind;

  /// One line shown on the list card.
  final String tagline;

  /// District, region or era.
  final String location;
  final String description;

  /// Short facts shown as a bulleted list on the detail screen.
  final List<String> highlights;

  /// Destination searched in the maps app for directions; null when the
  /// item is not a single place to visit.
  final String? mapQuery;
}

/// A famous place to visit, with the destination searched in the maps app.
class FamousPlace {
  const FamousPlace({required this.name, required this.mapQuery});

  final String name;

  /// e.g. "Hampi, Karnataka, India".
  final String mapQuery;
}

/// One of Karnataka's districts and what it is famous for.
class District {
  const District({
    required this.id,
    required this.name,
    required this.kannadaName,
    required this.headquarters,
    required this.latitude,
    required this.longitude,
    required this.knownFor,
    required this.famous,
    this.discoverIds = const [],
  });

  /// URL-safe id, used in `/rajyotsava/district/<id>`.
  final String id;
  final String name;
  final String kannadaName;

  /// Administrative headquarters town.
  final String headquarters;

  /// Coordinates of the headquarters, used to find the nearest districts.
  final double latitude;
  final double longitude;

  /// One line for the list.
  final String knownFor;

  /// Famous places, food, crafts and people, one per line.
  final List<String> famous;

  /// Related Discover Karnataka items.
  final List<String> discoverIds;
}

/// Songs or folk arts.
enum CultureKind { song, art }

/// A Kannada song or folk art form, with a YouTube search to watch it.
class CultureEntry {
  const CultureEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.kannadaTitle,
    required this.credit,
    required this.description,
    required this.searchQuery,
  });

  final String id;
  final CultureKind kind;
  final String title;
  final String kannadaTitle;

  /// Poet, singer or film for songs; region for folk arts.
  final String credit;
  final String description;

  /// Searched on YouTube, so people can pick an official version.
  final String searchQuery;
}

/// A film with its release year.
class Film {
  const Film(this.title, this.year);

  final String title;
  final int year;
}

enum StarRole {
  actor('Actors'),
  actress('Actresses');

  const StarRole(this.label);

  final String label;
}

/// A famous Kannada film star and their best-known films.
class FilmStar {
  const FilmStar({
    required this.id,
    required this.name,
    required this.kannadaName,
    required this.role,
    required this.knownAs,
    required this.about,
    required this.films,
  });

  final String id;
  final String name;
  final String kannadaName;
  final StarRole role;

  /// Popular title, e.g. "Annavru"; empty when there is none.
  final String knownAs;

  /// One or two sentences.
  final String about;
  final List<Film> films;
}

/// A shareable festival greeting.
class RajyotsavaWish {
  const RajyotsavaWish({required this.kannada, required this.english});

  final String kannada;
  final String english;

  /// Text copied to the clipboard.
  String get shareText => '$kannada\n$english';
}

/// A milestone in the history of Karnataka Rajyotsava.
class HistoryEvent {
  const HistoryEvent({required this.year, required this.text});

  final String year;
  final String text;
}

/// Everything the module shows. Bundled in the app (see
/// `data/bundled_rajyotsava_content.dart`), so it works offline.
class RajyotsavaContent {
  const RajyotsavaContent({
    required this.history,
    required this.facts,
    required this.wishes,
    required this.quiz,
    required this.vowels,
    required this.consonants,
    required this.phrases,
    required this.numbers,
    required this.discover,
    this.districts = const [],
    this.culture = const [],
    this.places = const {},
    this.filmStars = const [],
  });

  final List<HistoryEvent> history;
  final List<String> facts;
  final List<RajyotsavaWish> wishes;
  final List<QuizQuestion> quiz;
  final List<KannadaLetter> vowels;
  final List<KannadaLetter> consonants;
  final List<KannadaPhrase> phrases;
  final List<KannadaNumber> numbers;
  final List<DiscoverItem> discover;
  final List<District> districts;
  final List<CultureEntry> culture;

  /// Famous Kannada actors and actresses.
  final List<FilmStar> filmStars;

  /// Famous places to visit, by district id.
  final Map<String, List<FamousPlace>> places;

  /// Places to visit in the district with [districtId].
  List<FamousPlace> placesIn(String districtId) =>
      places[districtId] ?? const [];

  /// The district with [id], or null when there is none.
  District? district(String id) {
    for (final d in districts) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// The item with [id], or null when there is none.
  DiscoverItem? discoverItem(String id) {
    for (final item in discover) {
      if (item.id == id) return item;
    }
    return null;
  }
}
