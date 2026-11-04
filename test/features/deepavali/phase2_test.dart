import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/deepavali_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/festival_dates.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/festival_status.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/deepavali_page.dart';

class FakeStore implements DeepavaliStore {
  FakeStore({this.seen = false});
  bool seen;
  @override
  Future<bool> introSeen() async => seen;
  @override
  Future<void> markIntroSeen() async => seen = true;
}

/// IST wall-clock time as an instant.
DateTime ist(int d, [int h = 0, int m = 0, int s = 0]) => DateTime.utc(
  2026,
  11,
  d,
  h,
  m,
  s,
).subtract(const Duration(hours: 5, minutes: 30));

Widget host(
  FakeStore store,
  DateTime now, {
  bool reduceMotion = false,
  double textScale = 1,
  Size size = const Size(360, 800),
}) => ProviderScope(
  overrides: [
    deepavaliStoreProvider.overrideWithValue(store),
    deepavaliNowProvider.overrideWithValue(() => now),
  ],
  child: MediaQuery(
    data: MediaQueryData(
      size: size,
      disableAnimations: reduceMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: const MaterialApp(home: DeepavaliPage()),
  ),
);

/// Lets the stored flag load and the intro (if any) take its first frame.
Future<void> primeHero(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  group('FestivalStatus', () {
    FestivalStatus at(DateTime t) => FestivalStatus.at(t, deepavaliDates);

    test(
      'before the festival: countdown to Lakshmi Puja, next is Dhanteras',
      () {
        final s = at(ist(3, 12));
        expect(s.phase, FestivalPhase.before);
        expect(s.untilPuja, const Duration(days: 4, hours: 12));
        expect(s.today, isNull);
        expect(s.next!.id, 'dhanteras');
      },
    );

    test('exact boundaries', () {
      expect(at(ist(5, 23, 59, 59)).phase, FestivalPhase.before);
      expect(at(ist(6)).phase, FestivalPhase.festivalWeek);
      expect(at(ist(6)).today!.id, 'dhanteras');
      expect(at(ist(7, 23, 59, 59)).phase, FestivalPhase.festivalWeek);
      expect(at(ist(8)).phase, FestivalPhase.diwaliDay);
      expect(at(ist(8)).untilPuja, isNull);
      expect(at(ist(9)).phase, FestivalPhase.festivalWeek);
      expect(at(ist(9)).today!.id, 'govardhan_puja');
      expect(at(ist(10, 23, 59, 59)).today!.id, 'bhai_dooj');
      expect(at(ist(11)).phase, FestivalPhase.after);
      expect(at(ist(11)).next, isNull);
    });

    test('is independent of the device time zone', () {
      final instant = ist(7, 10);
      expect(at(instant.toLocal()).today!.id, at(instant.toUtc()).today!.id);
    });

    test('week state has a countdown only until Lakshmi Puja', () {
      expect(at(ist(7, 12)).untilPuja, const Duration(hours: 12));
      expect(at(ist(9, 12)).untilPuja, isNull);
    });

    test('five days are ordered, consecutive and 5 long', () {
      expect(festivalDays.map((d) => d.offsetFromLakshmiPuja), [
        -2,
        -1,
        0,
        1,
        2,
      ]);
      expect(deepavaliDates.civilDate(festivalDays.first).day, 6);
      expect(
        deepavaliDates.civilDate(deepavaliDates.lakshmiPuja).weekday,
        DateTime.sunday,
      );
    });
  });

  group('countdown section', () {
    testWidgets('shows days to go and the next milestone', (tester) async {
      await tester.pumpWidget(
        host(FakeStore(seen: true), ist(3, 12), reduceMotion: true),
      );
      expect(find.text('Deepavali · Sunday, 8 November 2026'), findsOneWidget);
      expect(find.text('04'), findsOneWidget); // days
      expect(find.text('12'), findsOneWidget); // hours
      expect(find.text('Next: Dhanteras · Fri 6 Nov'), findsOneWidget);
    });

    testWidgets('ticks with the clock while the tab is active', (tester) async {
      var now = ist(3, 12);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deepavaliStoreProvider.overrideWithValue(FakeStore(seen: true)),
            deepavaliNowProvider.overrideWithValue(() => now),
          ],
          child: const MediaQuery(
            data: MediaQueryData(size: Size(360, 800), disableAnimations: true),
            child: MaterialApp(home: DeepavaliPage()),
          ),
        ),
      );
      expect(find.text('00'), findsNWidgets(2)); // min and sec
      now = ist(3, 12, 0, 30);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      // Remaining is now 4d 11:59:30.
      expect(find.text('30'), findsOneWidget);
      expect(find.text('59'), findsOneWidget);
    });

    testWidgets('Lakshmi Puja day', (tester) async {
      await tester.pumpWidget(
        host(FakeStore(seen: true), ist(8, 9), reduceMotion: true),
      );
      expect(find.text('Happy Deepavali! Today is the day.'), findsOneWidget);
    });

    testWidgets('after the festival offers to relive it', (tester) async {
      await tester.pumpWidget(
        host(FakeStore(seen: true), ist(12), reduceMotion: true),
      );
      expect(find.textContaining('See you next year'), findsOneWidget);
      expect(find.text('Relive the celebration'), findsOneWidget);
    });

    testWidgets('spoken label has minute granularity', (tester) async {
      await tester.pumpWidget(
        host(FakeStore(seen: true), ist(3, 12, 0, 5), reduceMotion: true),
      );
      expect(
        find.bySemanticsLabel('4 days, 11 hours, 59 minutes until Deepavali'),
        findsOneWidget,
      );
    });

    testWidgets('schedule sheet lists the five days and marks today', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FakeStore(seen: true), ist(7, 9), reduceMotion: true),
      );
      await tester.scrollUntilVisible(
        find.text('View five-day schedule'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('View five-day schedule'));
      await tester.pumpAndSettle();
      expect(find.text('The five days of Deepavali'), findsOneWidget);
      for (final d in festivalDays) {
        expect(find.text(d.title), findsWidgets);
      }
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('2x text uses a 2x2 grid without overflow', (tester) async {
      await tester.pumpWidget(
        host(
          FakeStore(seen: true),
          ist(3, 12),
          reduceMotion: true,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('hero', () {
    testWidgets(
      'first run plays the intro; Skip jumps to the end and remembers',
      (tester) async {
        final store = FakeStore();
        await tester.pumpWidget(host(store, ist(3)));
        await primeHero(tester);
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Skip'), findsOneWidget);
        await tester.tap(find.text('Skip'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Skip'), findsNothing);
        expect(find.text('Replay'), findsOneWidget);
        expect(store.seen, isTrue);
      },
    );

    testWidgets('finishes on its own and remembers', (tester) async {
      final store = FakeStore();
      await tester.pumpWidget(host(store, ist(3)));
      await primeHero(tester);
      await tester.pump(const Duration(milliseconds: 3200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Replay'), findsOneWidget);
      expect(store.seen, isTrue);
    });

    testWidgets('later visits show the final state straight away', (
      tester,
    ) async {
      await tester.pumpWidget(host(FakeStore(seen: true), ist(3)));
      await primeHero(tester);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Replay'), findsOneWidget);
    });

    testWidgets('Replay runs the intro again', (tester) async {
      await tester.pumpWidget(host(FakeStore(seen: true), ist(3)));
      await primeHero(tester);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Replay'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('reduced motion shows the final scene with no replay', (
      tester,
    ) async {
      await tester.pumpWidget(host(FakeStore(), ist(3), reduceMotion: true));
      await tester.pump();
      expect(find.text('Shubh Deepavali'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Replay'), findsNothing);
    });

    testWidgets('CTA scrolls to the Explorer section', (tester) async {
      await tester.pumpWidget(
        host(FakeStore(seen: true), ist(3), reduceMotion: true),
      );
      await tester.pump();
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scroll.position.pixels, 0);
      await tester.tap(find.text('Begin the celebration'));
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, greaterThan(0));
      expect(find.text('Discover Deepavali'), findsOneWidget);
    });

    testWidgets('lays out at 320dp and 2x text', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          FakeStore(seen: true),
          ist(3),
          reduceMotion: true,
          textScale: 2,
          size: const Size(320, 568),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
