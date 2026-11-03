/// One of the five commonly recognised days of Deepavali.
///
/// [offsetFromLakshmiPuja] places the day relative to the configured Lakshmi
/// Puja date (-2 .. +2). Regional calendars differ; the text says so.
class FestivalDay {
  const FestivalDay({
    required this.id,
    required this.title,
    required this.alsoKnownAs,
    required this.summary,
    required this.offsetFromLakshmiPuja,
  });

  final String id;
  final String title;
  final String alsoKnownAs;
  final String summary;
  final int offsetFromLakshmiPuja;
}

/// The five days, in order. Content is concise and flags regional variation;
/// it still needs the content reviewer's sign-off (plan D11).
const List<FestivalDay> festivalDays = [
  FestivalDay(
    id: 'dhanteras',
    title: 'Dhanteras',
    alsoKnownAs: 'Dhanatrayodashi',
    summary:
        'The festival begins. Many families buy something new, often metal '
        'such as gold, silver or utensils, and light lamps in the evening.',
    offsetFromLakshmiPuja: -2,
  ),
  FestivalDay(
    id: 'naraka_chaturdashi',
    title: 'Naraka Chaturdashi',
    alsoKnownAs: 'Choti Diwali',
    summary:
        'Remembers the defeat of the demon Narakasura by Krishna. In '
        'Karnataka and much of South India this is the main day, begun with '
        'a pre-dawn oil bath and new clothes.',
    offsetFromLakshmiPuja: -1,
  ),
  FestivalDay(
    id: 'lakshmi_puja',
    title: 'Lakshmi Puja',
    alsoKnownAs: 'Diwali night',
    summary:
        'In much of North and West India this is the main evening. Homes are '
        'cleaned and lit with diyas, and families worship Lakshmi, who is '
        'associated with prosperity.',
    offsetFromLakshmiPuja: 0,
  ),
  FestivalDay(
    id: 'govardhan_puja',
    title: 'Govardhan Puja',
    alsoKnownAs: 'Balipratipada, Bali Padyami',
    summary:
        'Many North Indian communities offer a mound of food (Annakut) for '
        'Govardhan Puja. In parts of Karnataka and Maharashtra the day '
        'remembers King Bali, and in Gujarat it begins the new year.',
    offsetFromLakshmiPuja: 1,
  ),
  FestivalDay(
    id: 'bhai_dooj',
    title: 'Bhai Dooj',
    alsoKnownAs: 'Bhau Beej, Bhai Phota',
    summary:
        'Siblings celebrate their bond. Sisters pray for their brothers’ '
        'well-being and brothers give gifts. The name and customs change '
        'from region to region.',
    offsetFromLakshmiPuja: 2,
  ),
];

/// Calendar date of Lakshmi Puja as an Indian Standard Time (IST) civil date.
///
/// Counting uses IST midnight regardless of the device time zone, so the
/// countdown is the same for everyone. Change the constant below to move the
/// whole festival.
class FestivalDates {
  const FestivalDates({
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;
  final int month;
  final int day;

  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  FestivalDay get lakshmiPuja =>
      festivalDays.firstWhere((d) => d.offsetFromLakshmiPuja == 0);

  /// IST civil date of [d] (time-of-day is always 00:00, flagged as UTC only
  /// so that weekday and day-of-month are stable).
  DateTime civilDate(FestivalDay d) =>
      DateTime.utc(year, month, day + d.offsetFromLakshmiPuja);

  /// The instant [d] starts (IST midnight).
  DateTime start(FestivalDay d) => civilDate(d).subtract(_istOffset);

  /// The instant [d] ends.
  DateTime end(FestivalDay d) => start(d).add(const Duration(days: 1));

  DateTime get firstStart => start(festivalDays.first);
  DateTime get lastEnd => end(festivalDays.last);
  DateTime get pujaStart => start(lakshmiPuja);
}

/// Confirmed by the user: Lakshmi Puja on Sunday 8 November 2026 (IST).
const FestivalDates deepavaliDates = FestivalDates(
  year: 2026,
  month: 11,
  day: 8,
);
