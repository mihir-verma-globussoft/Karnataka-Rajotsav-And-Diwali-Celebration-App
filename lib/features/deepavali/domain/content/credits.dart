import 'destinations.dart';

/// One credited work.
class CreditEntry {
  const CreditEntry({
    required this.title,
    required this.by,
    required this.licence,
    this.source,
  });

  /// What it is, e.g. a song name or a photo's city.
  final String title;

  /// Author or owner.
  final String by;

  /// Licence, or a plain statement when there is none to quote.
  final String licence;

  /// Where it came from, when there is a page to point to.
  final String? source;
}

class CreditGroup {
  const CreditGroup(this.heading, this.entries, {this.note});

  final String heading;
  final List<CreditEntry> entries;

  /// A line shown under the heading.
  final String? note;
}

/// Audio files in `assets/deepavali/audio/` and who made them. A test checks
/// that this list and the folder always match, so no file ships uncredited.
const List<({String file, CreditEntry credit})> audioCredits = [
  (
    file: 'music.mp3',
    credit: CreditEntry(
      title: 'Background song “Happy Diwali”',
      by: 'From the film Home Delivery, T-Series',
      licence: 'Supplied by the app team',
    ),
  ),
  (
    file: 'tap.mp3',
    credit: CreditEntry(
      title: 'Tap sound',
      by: 'Kenney, Interface Sounds',
      licence: 'CC0 (public domain)',
      source: 'https://opengameart.org/content/interface-sounds',
    ),
  ),
  (
    file: 'diya_light.mp3',
    credit: CreditEntry(
      title: 'Diya-lighting sound',
      by: 'Kenney, Interface Sounds',
      licence: 'CC0 (public domain)',
      source: 'https://opengameart.org/content/interface-sounds',
    ),
  ),
  (
    file: 'correct.mp3',
    credit: CreditEntry(
      title: 'Correct-answer sound',
      by: 'Kenney, Interface Sounds',
      licence: 'CC0 (public domain)',
      source: 'https://opengameart.org/content/interface-sounds',
    ),
  ),
  (
    file: 'wrong.mp3',
    credit: CreditEntry(
      title: 'Wrong-answer sound',
      by: 'Kenney, Interface Sounds',
      licence: 'CC0 (public domain)',
      source: 'https://opengameart.org/content/interface-sounds',
    ),
  ),
  (
    file: 'win.mp3',
    credit: CreditEntry(
      title: 'Win sound',
      by: 'Fupi, Win Jingle',
      licence: 'CC0 (public domain)',
      source: 'https://opengameart.org/content/win-jingle',
    ),
  ),
  (
    file: 'gust.mp3',
    credit: CreditEntry(
      title: 'Gust of wind',
      by: 'remaxim, Short wind sound',
      licence: 'CC0 (public domain)',
      source: 'https://opengameart.org/content/short-wind-sound',
    ),
  ),
];

/// The font bundled with the tab.
const CreditEntry fontCredit = CreditEntry(
  title: 'Poppins typeface',
  by: 'The Poppins Project Authors, Indian Type Foundry',
  licence: 'SIL Open Font Licence 1.1',
  source: 'https://github.com/itfoundry/Poppins',
);

/// Where the written facts come from.
const CreditEntry factsCredit = CreditEntry(
  title: 'Facts about cities, festival days and customs',
  by: 'Wikipedia contributors',
  licence: 'CC BY-SA 4.0',
  source: 'https://www.wikipedia.org',
);

/// Everything shown on the Credits & licences sheet, in order.
List<CreditGroup> get creditGroups => [
  CreditGroup('Photos', [
    for (final d in destinations)
      CreditEntry(
        title: d.name,
        by: d.photo.author,
        licence: d.photo.isSupplied
            ? 'Supplied by the app team'
            : d.photo.license,
        source: d.photo.isSupplied ? null : d.photo.sourceUrl,
      ),
  ], note: 'Drawings, diyas and the greeting cards are made in the app.'),
  CreditGroup('Music and sounds', [for (final a in audioCredits) a.credit]),
  const CreditGroup('Typeface', [fontCredit]),
  const CreditGroup('Facts', [factsCredit]),
];
