import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/data/wish_prefs_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/content/guess_objects.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/festival_dates.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/festival_status.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/quiz_session.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/wish.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/wish_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/more_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/wall_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_theme.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/diwali_motion.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/timeline_stepper.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/wish_sheets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers.dart';

class _WishStore implements WishStore {
  _WishStore([List<Wish> start = const []]) : saved = List.of(start);
  List<Wish> saved;
  bool failSave = false;
  int saves = 0;
  @override
  Future<List<Wish>> load() async => List.of(saved);
  @override
  Future<void> save(List<Wish> wishes) async {
    if (failSave) throw StateError('disk full');
    saves++;
    saved = List.of(wishes);
  }
}

Wish _wish(int id, [String text = 'A wish']) =>
    Wish(id: id, text: text, from: '', litAtMillis: id);

DateTime _ist(int day, [int hour = 12]) => DateTime.utc(
  2026,
  11,
  day,
  hour,
).subtract(const Duration(hours: 5, minutes: 30));

void main() {
  reduceMotionForAllTests();

  group('Wish', () {
    test('tidying trims and collapses; blanks are refused', () {
      expect(tidyWish('  May  all\nbe well '), 'May all be well');
      expect(tidyWish('   '), isNull);
      expect(tidyWish(''), isNull);
    });

    test('wishes are cut at the limit without splitting emoji', () {
      expect(tidyWish('a' * 200)!.length, wishMax);
      final emoji = tidyWish('🪔' * 200)!;
      expect(emoji.runes.length, wishMax);
    });

    test('json round trip', () {
      const w = Wish(id: 5, text: 'Peace', from: 'Asha', litAtMillis: 99);
      final back = Wish.tryParse(w.toJson())!;
      expect(back.id, 5);
      expect(back.text, 'Peace');
      expect(back.from, 'Asha');
      expect(back.litAtMillis, 99);
    });

    test('damaged entries are rejected, not trusted', () {
      expect(Wish.tryParse(null), isNull);
      expect(Wish.tryParse('x'), isNull);
      expect(Wish.tryParse({'id': 'a', 'text': 't', 'litAt': 1}), isNull);
      expect(Wish.tryParse({'id': 1, 'text': 5, 'litAt': 1}), isNull);
      expect(Wish.tryParse({'id': 1, 'text': 't'}), isNull);
      expect(Wish.tryParse({'id': 1, 'text': '   ', 'litAt': 1}), isNull);
    });

    test('a stored over-long wish is cut when read', () {
      final w = Wish.tryParse({
        'id': 1,
        'text': 'x' * 500,
        'from': 'n' * 500,
        'litAt': 1,
      })!;
      expect(w.text.length, wishMax);
      expect(w.from.length, wishNameMax);
    });
  });

  group('WishWall', () {
    test('newest first', () {
      final wall = WishWall().add(_wish(1)).add(_wish(2)).add(_wish(3));
      expect(wall.wishes.map((w) => w.id), [3, 2, 1]);
    });

    test('keeps at most $wallMax, dropping the oldest', () {
      var wall = WishWall();
      for (var i = 1; i <= wallMax + 5; i++) {
        wall = wall.add(_wish(i));
      }
      expect(wall.count, wallMax);
      expect(wall.wishes.first.id, wallMax + 5);
      expect(wall.byId(1), isNull);
      expect(wall.byId(6), isNotNull);
    });

    test('an over-long list is trimmed on the way in', () {
      final wall = WishWall([for (var i = 0; i < 80; i++) _wish(i)]);
      expect(wall.count, wallMax);
    });

    test('remove and lookup', () {
      final wall = WishWall().add(_wish(1)).add(_wish(2)).remove(1);
      expect(wall.wishes.map((w) => w.id), [2]);
      expect(wall.byId(1), isNull);
      expect(wall.remove(99).count, 1);
    });

    test('ids never collide', () {
      final wall = WishWall().add(_wish(10)).add(_wish(11));
      expect(wall.nextId(10), 12);
      expect(wall.nextId(50), 50);
    });

    test('wishes cannot be changed from outside', () {
      final wall = WishWall().add(_wish(1));
      expect(() => wall.wishes.add(_wish(2)), throwsUnsupportedError);
    });
  });

  group('PrefsWishStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('saves and loads, newest first, across instances', () async {
      const store = PrefsWishStore();
      await store.save([_wish(2, 'Second'), _wish(1, 'First')]);
      final loaded = await const PrefsWishStore().load();
      expect(loaded.map((w) => w.text), ['Second', 'First']);
    });

    test('nothing stored reads as empty', () async {
      expect(await const PrefsWishStore().load(), isEmpty);
    });

    test('garbage reads as empty instead of crashing', () async {
      SharedPreferences.setMockInitialValues({
        'deepavali.wall.v1': 'not json{',
      });
      expect(await const PrefsWishStore().load(), isEmpty);
      SharedPreferences.setMockInitialValues({'deepavali.wall.v1': '{"a":1}'});
      expect(await const PrefsWishStore().load(), isEmpty);
    });

    test('bad entries are skipped, good ones kept', () async {
      SharedPreferences.setMockInitialValues({
        'deepavali.wall.v1':
            '[{"id":1,"text":"ok","from":"","litAt":1},"junk",{"id":2}]',
      });
      final loaded = await const PrefsWishStore().load();
      expect(loaded.map((w) => w.text), ['ok']);
    });

    test('only $wallMax are read back', () async {
      await const PrefsWishStore().save([
        for (var i = 0; i < 70; i++) _wish(i),
      ]);
      expect((await const PrefsWishStore().load()).length, wallMax);
    });
  });

  group('WallNotifier', () {
    late _WishStore store;
    late ProviderContainer container;

    setUp(() {
      store = _WishStore();
      container = ProviderContainer(
        overrides: [
          wishStoreProvider.overrideWithValue(store),
          deepavaliNowProvider.overrideWithValue(() => DateTime(2026, 11, 8)),
        ],
      );
    });
    tearDown(() => container.dispose());

    WallNotifier notifier() => container.read(wallProvider.notifier);
    Future<WishWall> wall() => container.read(wallProvider.future);

    test('loads what was saved', () async {
      store.saved = [_wish(1, 'Saved earlier')];
      expect((await wall()).wishes.single.text, 'Saved earlier');
    });

    test('adding lights a diya and saves it', () async {
      expect(
        await notifier().add('  Good health ', 'Asha'),
        AddWishResult.saved,
      );
      final w = (await wall()).wishes.single;
      expect(w.text, 'Good health');
      expect(w.from, 'Asha');
      expect(store.saved.single.text, 'Good health');
    });

    test('an empty wish is refused and nothing is saved', () async {
      expect(await notifier().add('   ', ''), AddWishResult.empty);
      expect((await wall()).isEmpty, isTrue);
      expect(store.saves, 0);
    });

    test('two wishes at the same instant get different ids', () async {
      await notifier().add('One', '');
      await notifier().add('Two', '');
      final ids = (await wall()).wishes.map((w) => w.id).toSet();
      expect(ids.length, 2);
    });

    test('a failed save keeps the diya for this session and says so', () async {
      store.failSave = true;
      expect(await notifier().add('Still here', ''), AddWishResult.notSaved);
      expect((await wall()).wishes.single.text, 'Still here');
      expect(store.saved, isEmpty);
    });

    test('removing deletes it and saves', () async {
      await notifier().add('Gone soon', '');
      final id = (await wall()).wishes.single.id;
      expect(await notifier().remove(id), isTrue);
      expect((await wall()).isEmpty, isTrue);
      expect(store.saved, isEmpty);
    });

    test('the wall is capped at $wallMax', () async {
      for (var i = 0; i < wallMax + 3; i++) {
        await notifier().add('Wish $i', '');
      }
      expect((await wall()).count, wallMax);
      expect(store.saved.length, wallMax);
    });
  });

  group('guess the object', () {
    test('eight distinct objects, all with a fact', () {
      expect(guessObjects.length, guessRounds);
      expect(guessObjects.map((o) => o.id).toSet().length, guessRounds);
      expect(guessObjects.map((o) => o.name).toSet().length, guessRounds);
      for (final o in guessObjects) {
        expect(o.fact.trim(), isNotEmpty, reason: o.id);
      }
      expect(guessObjectById('diya')!.name, 'Diya');
      expect(guessObjectById('nope'), isNull);
    });

    test('every question has the right answer plus three other objects', () {
      for (var seed = 0; seed < 20; seed++) {
        for (final q in buildGuessQuestions(seed)) {
          final object = guessObjectById(q.id)!;
          expect(q.options.length, 4);
          expect(q.options.toSet().length, 4);
          expect(q.options[q.correctIndex], object.name);
          expect(q.explanation, object.fact);
          for (final o in q.options) {
            expect(guessObjects.any((x) => x.name == o), isTrue);
          }
        }
      }
    });

    test('distractors change with the seed', () {
      List<List<String>> options(int seed) => [
        for (final q in buildGuessQuestions(seed)) q.options,
      ];
      expect(options(1), options(1));
      expect(options(1), isNot(options(2)));
    });

    test('a game plays every object once and scores like the quiz', () {
      var s = QuizSession.start(
        buildGuessQuestions(4),
        seed: 4,
        count: guessRounds,
      );
      expect(s.total, guessRounds);
      expect(s.items.map((i) => i.question.id).toSet().length, guessRounds);
      for (var i = 0; i < s.total; i++) {
        final right = s.current.correctIndex;
        s = s.answer(i < 6 ? right : (right + 1) % 4).next();
      }
      expect(s.finished, isTrue);
      expect(s.score, 6);
      expect(s.tier, QuizTier.brightSpark);
    });
  });

  group('timeline highlight', () {
    FestivalDay? today(DateTime now) =>
        FestivalStatus.at(now, deepavaliDates).today;

    test('each of the five days highlights its own step', () {
      final days = [for (final d in festivalDays) d.id];
      expect(today(_ist(6))!.id, days[0]);
      expect(today(_ist(7))!.id, days[1]);
      expect(today(_ist(8))!.id, days[2]);
      expect(today(_ist(9))!.id, days[3]);
      expect(today(_ist(10))!.id, days[4]);
    });

    test('the day changes at midnight India time', () {
      expect(today(_ist(7, 23))!.id, festivalDays[1].id);
      expect(today(_ist(8, 0))!.id, festivalDays[2].id);
    });

    test('nothing is highlighted outside the five days', () {
      expect(today(_ist(5, 23)), isNull);
      expect(today(_ist(11, 1)), isNull);
      expect(today(DateTime.utc(2027, 3, 1)), isNull);
    });
  });

  group('MoreSection', () {
    late _WishStore store;
    DateTime now = DateTime(2026, 11, 8, 12);

    Widget app({
      double scale = 1,
      Size size = const Size(360, 800),
      double keyboard = 0,
    }) => ProviderScope(
      overrides: [
        wishStoreProvider.overrideWithValue(store),
        deepavaliNowProvider.overrideWithValue(() => now),
        quizSeedProvider.overrideWithValue(() => 3),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: TextScaler.linear(scale),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: MaterialApp(
          theme: DiwaliTheme.data,
          home: const Scaffold(
            body: DiwaliMotionScope(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: MoreSection(),
              ),
            ),
          ),
        ),
      ),
    );

    setUp(() {
      store = _WishStore();
      now = DateTime(2026, 11, 8, 12);
    });

    void moreTest(
      String name,
      Future<void> Function(WidgetTester tester) body, {
      Size size = const Size(360, 800),
    }) => testWidgets(name, (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await body(tester);
    });

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    final expected = QuizSession.start(
      buildGuessQuestions(3),
      seed: 3,
      count: guessRounds,
    );

    moreTest('shows the three extras', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('More to Explore'), findsOneWidget);
      expect(find.text('Virtual Diya Wall'), findsOneWidget);
      expect(find.text('Guess the Diwali object'), findsOneWidget);
      expect(find.text('Festival timeline'), findsOneWidget);
      expect(find.text('Light the first diya.'), findsOneWidget);
      expect(
        find.textContaining('saved on this phone only'),
        findsOneWidget,
        reason: 'the wall says it is private to this device',
      );
    });

    moreTest('lighting a diya adds it to the wall and saves it', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Light a diya');
      expect(find.text('Make a wish'), findsOneWidget);
      // Cannot light with an empty wish.
      final button = find.widgetWithText(InkWell, 'Light a diya');
      expect(button, findsWidgets);
      await tester.enterText(
        find.widgetWithText(TextField, 'Your wish'),
        'Health for everyone',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Your name (optional)'),
        'Ravi',
      );
      await tester.pump();
      await tester.tap(find.text('Light a diya').last);
      await tester.pumpAndSettle();
      expect(find.text('Make a wish'), findsNothing);
      expect(find.text('1 wish'), findsOneWidget);
      expect(find.text('Light the first diya.'), findsNothing);
      expect(store.saved.single.text, 'Health for everyone');
      expect(store.saved.single.from, 'Ravi');
    });

    moreTest('the wish field stops at the limit and the button needs a wish', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Light a diya');
      await tester.enterText(
        find.widgetWithText(TextField, 'Your wish'),
        '   ',
      );
      await tester.pump();
      await tester.tap(find.text('Light a diya').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(store.saved, isEmpty, reason: 'blank wish is not accepted');
      expect(find.text('Make a wish'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Your wish'),
        'x' * (wishMax + 20),
      );
      await tester.pump();
      expect(find.text('$wishMax/$wishMax'), findsOneWidget);
    });

    moreTest('a failed save says so but the diya stays', (tester) async {
      store.failSave = true;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Light a diya');
      await tester.enterText(
        find.widgetWithText(TextField, 'Your wish'),
        'Hope',
      );
      await tester.pump();
      await tester.tap(find.text('Light a diya').last);
      await tester.pumpAndSettle();
      expect(find.text(wishNotSavedMessage), findsOneWidget);
      expect(find.text('1 wish'), findsOneWidget);
    });

    moreTest('saved wishes come back after a restart', (tester) async {
      store.saved = [_wish(2, 'Second'), _wish(1, 'First')];
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('2 wishes'), findsOneWidget);
      expect(find.text('Light the first diya.'), findsNothing);
    });

    moreTest('tapping a diya reads the wish and it can be removed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      store.saved = [
        const Wish(id: 1, text: 'Peace on earth', from: 'Asha', litAtMillis: 0),
      ];
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final diya = find.bySemanticsLabel(
        RegExp('^Wish: Peace on earth, from Asha'),
      );
      expect(diya, findsOneWidget);
      await tester.tap(diya);
      await tester.pumpAndSettle();
      expect(find.text('Peace on earth'), findsOneWidget);
      expect(find.textContaining('— Asha'), findsOneWidget);
      expect(find.textContaining('Lit on 1 January 1970'), findsOneWidget);

      await tester.tap(find.text('Remove this wish'));
      await tester.pumpAndSettle();
      expect(find.text('Light the first diya.'), findsOneWidget);
      expect(store.saved, isEmpty);
      handle.dispose();
    });

    moreTest('with more than a screenful, View all opens every wish', (
      tester,
    ) async {
      store.saved = [for (var i = 20; i >= 1; i--) _wish(i, 'Wish $i')];
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('20 wishes'), findsOneWidget);
      await tapText(tester, 'View all 20');
      expect(find.text('All wishes (20)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    moreTest('guess game: play all rounds and see the result', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Start guessing');
      for (var r = 0; r < guessRounds; r++) {
        expect(find.text('Round ${r + 1} of $guessRounds'), findsOneWidget);
        final item = expected.items[r];
        // Get the first six right.
        final pick = r < 6 ? item.correctIndex : (item.correctIndex + 1) % 4;
        await tapText(tester, item.options[pick]);
        expect(
          find.textContaining(r < 6 ? 'Yes, it’s a' : 'Not quite. It’s a'),
          findsOneWidget,
        );
        expect(find.text(item.question.explanation), findsOneWidget);
        await tapText(tester, r == guessRounds - 1 ? 'See results' : 'Next');
      }
      expect(find.text('You got 6 of 8'), findsOneWidget);
      expect(find.textContaining('Bright spark'), findsOneWidget);
      await tapText(tester, 'Play again');
      expect(find.text('Round 1 of 8'), findsOneWidget);
    });

    moreTest('guess game: an answer is locked and Quit goes back', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Start guessing');
      final item = expected.items[0];
      final wrong = item.options[(item.correctIndex + 1) % 4];
      await tapText(tester, wrong);
      await tapText(tester, item.correctOption);
      expect(find.textContaining('Not quite. It’s a'), findsOneWidget);
      await tapText(tester, 'Quit');
      expect(find.text('Start guessing'), findsOneWidget);
    });

    moreTest('the timeline highlights today and opens a day', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.textContaining('Today is Lakshmi Puja'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Lakshmi Puja, .*, today$')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r', today$')), findsOneWidget);
      for (final d in festivalDays) {
        expect(find.bySemanticsLabel(RegExp('^${d.title}, ')), findsOneWidget);
      }
      await tester.ensureVisible(find.bySemanticsLabel(RegExp('^Dhanteras, ')));
      await tester.tap(find.bySemanticsLabel(RegExp('^Dhanteras, ')));
      await tester.pumpAndSettle();
      expect(find.textContaining('The festival begins'), findsOneWidget);
      handle.dispose();
    });

    moreTest(
      'the timeline shows a button when more days are off to the right',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(TimelineStepper));
        await tester.pumpAndSettle();
        final more = find.bySemanticsLabel('Show the last days');
        expect(more, findsOneWidget);
        await tester.tap(more);
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Show the last days'),
          findsNothing,
          reason: 'at the end there is nothing more to show',
        );
        handle.dispose();
      },
    );

    moreTest('timeline steps grow with the text size', (tester) async {
      Future<double> widthAt(double scale) async {
        late double w;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Builder(
              builder: (context) {
                w = timelineStepWidth(context);
                return const SizedBox();
              },
            ),
          ),
        );
        return w;
      }

      expect(await widthAt(1), AppSizes.timelineStep);
      expect(await widthAt(2), AppSizes.timelineStep * 2);
    });

    moreTest('outside the festival nothing is marked as today', (tester) async {
      now = DateTime(2027, 2, 1, 12);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp(r', today$')), findsNothing);
      expect(find.textContaining('Five days, one festival'), findsOneWidget);
      handle.dispose();
    });

    for (final (name, size, scale) in [
      ('320x568 at 2x text', const Size(320, 568), 2.0),
      ('360x800', const Size(360, 800), 1.0),
      ('600x900', const Size(600, 900), 1.0),
    ]) {
      moreTest('every card fits at $name', size: size, (tester) async {
        store.saved = [
          for (var i = 14; i >= 1; i--) _wish(i, 'Wish number $i'),
        ];
        await tester.pumpWidget(app(scale: scale, size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tapText(tester, 'Start guessing');
        expect(tester.takeException(), isNull);
        final item = expected.items[0];
        await tapText(tester, item.options[item.correctIndex]);
        expect(tester.takeException(), isNull);

        await tapText(tester, 'Light a diya');
        expect(tester.takeException(), isNull);
      });
    }

    moreTest('the add sheet stays usable with the keyboard open', (
      tester,
    ) async {
      await tester.pumpWidget(app(keyboard: 320));
      await tester.pumpAndSettle();
      await tapText(tester, 'Light a diya');
      expect(tester.takeException(), isNull);
      expect(find.text('Make a wish'), findsOneWidget);
    });
  });
}
