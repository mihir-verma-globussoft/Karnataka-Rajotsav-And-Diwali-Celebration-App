/// Dates for Karnataka Rajyotsava, celebrated every year on 1 November.
library;

/// The state was formed on 1 November 1956.
const int formationYear = 1956;

/// Where [today] stands relative to Rajyotsava.
class RajyotsavaCountdown {
  const RajyotsavaCountdown({required this.daysLeft, required this.year});

  /// Days until the next 1 November; 0 on the day itself.
  final int daysLeft;

  /// Year of the celebration counted down to (or today's).
  final int year;

  bool get isToday => daysLeft == 0;

  /// Which Rajyotsava this is. 1956 was the 1st, so 2023 was the 68th and
  /// 2026 the 71st.
  int get edition => year - formationYear + 1;

  /// e.g. "71st".
  String get editionLabel => ordinal(edition);
}

RajyotsavaCountdown rajyotsavaCountdown(DateTime today) {
  // Calendar dates in UTC, so daylight-saving changes never skew the count.
  final day = DateTime.utc(today.year, today.month, today.day);
  var target = DateTime.utc(today.year, 11, 1);
  if (day.isAfter(target)) target = DateTime.utc(today.year + 1, 11, 1);
  return RajyotsavaCountdown(
    daysLeft: target.difference(day).inDays,
    year: target.year,
  );
}

/// English ordinal for a positive number: 1st, 2nd, 3rd, 4th, 11th, 21st…
String ordinal(int n) {
  final lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}
