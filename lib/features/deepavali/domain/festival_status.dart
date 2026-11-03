import 'festival_dates.dart';

enum FestivalPhase {
  /// Before the first of the five days.
  before,

  /// Inside the five days, but not on Lakshmi Puja itself.
  festivalWeek,

  /// Lakshmi Puja day.
  diwaliDay,

  /// After the last of the five days.
  after,
}

/// Where "now" sits relative to the festival. Pure function of its inputs.
class FestivalStatus {
  const FestivalStatus({
    required this.phase,
    this.untilPuja,
    this.today,
    this.next,
  });

  /// Computes the status at [now] (any time zone; compared as an instant).
  factory FestivalStatus.at(DateTime now, FestivalDates dates) {
    final instant = now.toUtc();
    FestivalDay? today;
    FestivalDay? next;
    for (final d in festivalDays) {
      if (!instant.isBefore(dates.start(d)) && instant.isBefore(dates.end(d))) {
        today = d;
      }
      if (next == null && dates.start(d).isAfter(instant)) next = d;
    }
    final puja = dates.pujaStart;
    final remaining = puja.isAfter(instant) ? puja.difference(instant) : null;

    final FestivalPhase phase;
    if (instant.isBefore(dates.firstStart)) {
      phase = FestivalPhase.before;
    } else if (!instant.isBefore(dates.lastEnd)) {
      phase = FestivalPhase.after;
    } else if (today == dates.lakshmiPuja) {
      phase = FestivalPhase.diwaliDay;
    } else {
      phase = FestivalPhase.festivalWeek;
    }
    return FestivalStatus(
      phase: phase,
      untilPuja: remaining,
      today: today,
      next: next,
    );
  }

  final FestivalPhase phase;

  /// Time until Lakshmi Puja begins; null once it has begun.
  final Duration? untilPuja;

  /// The festival day happening now, if any.
  final FestivalDay? today;

  /// The next festival day that has not started, if any.
  final FestivalDay? next;
}
