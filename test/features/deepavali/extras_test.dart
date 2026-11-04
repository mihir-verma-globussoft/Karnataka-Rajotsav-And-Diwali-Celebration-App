import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/content/destinations.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/decoration.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/image_sharer.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/photo_booth.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/recommendation.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/wish.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/wish_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/screens/decorate_screen.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/screens/photo_booth_screen.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/more_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/decor_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_theme.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/diwali_motion.dart';

import '../../helpers.dart';

/// A valid 1x1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _Sharer implements ImageSharer {
  final List<Uint8List> shared = [];
  final List<String> names = [];
  bool fail = false;
  @override
  Future<void> sharePng(
    Uint8List png, {
    required String fileName,
    String? text,
  }) async {
    if (fail) throw StateError('no share sheet');
    shared.add(png);
    names.add(fileName);
  }
}

class _Picker implements PhotoPicker {
  Uint8List? result = _png;
  PhotoFailure? failure;
  final List<PhotoSource> asked = [];
  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    asked.add(source);
    if (failure != null) throw PhotoPickException(failure!);
    return result;
  }
}

class _EmptyWishStore implements WishStore {
  @override
  Future<List<Wish>> load() async => const [];
  @override
  Future<void> save(List<Wish> wishes) async {}
}

void main() {
  reduceMotionForAllTests();

  group('recommendation', () {
    List<List<int>> allAnswers() => [
      for (var a = 0; a < 4; a++)
        for (var b = 0; b < 4; b++)
          for (var c = 0; c < 4; c++)
            for (var d = 0; d < 4; d++) [a, b, c, d],
    ];

    test('four questions of four answers', () {
      expect(recommendQuestions.length, 4);
      for (final q in recommendQuestions) {
        expect(q.options.length, 4);
        expect(q.prompt.trim(), isNotEmpty);
      }
    });

    test('every point goes to a real destination', () {
      final ids = destinations.map((d) => d.id).toSet();
      for (final q in recommendQuestions) {
        for (final o in q.options) {
          expect(o.points, isNotEmpty);
          for (final entry in o.points.entries) {
            expect(ids, contains(entry.key));
            expect(entry.value, inInclusiveRange(1, 2));
          }
        }
      }
    });

    test('every one of the six cities can win', () {
      final winners = {
        for (final a in allAnswers()) recommend(a).destinationId,
      };
      expect(winners, destinations.map((d) => d.id).toSet());
    });

    test('the same answers always give the same city', () {
      for (final a in allAnswers()) {
        expect(recommend(a).destinationId, recommend(a).destinationId);
      }
    });

    test('a clear pattern picks the obvious city', () {
      // Lamps on a river, quiet water, devotion, diya pattern.
      expect(recommend([0, 0, 0, 1]).destinationId, 'varanasi');
      // Palaces, shopping, colour, palace at night.
      expect(recommend([1, 1, 3, 2]).destinationId, 'jaipur');
      // Golden-temple prayer and community.
      expect(recommend([2, 0, 2, 0]).destinationId, 'amritsar');
      // Big public lamp-lighting and devotion.
      expect(recommend([2, 3, 0, 0]).destinationId, 'ayodhya');
    });

    test('reasons are only answers that pointed to the winner', () {
      for (final a in allAnswers()) {
        final r = recommend(a);
        expect(r.reasons, isNotEmpty);
        for (final reason in r.reasons) {
          final matching = [
            for (final q in recommendQuestions)
              for (final o in q.options)
                if (o.label == reason) o,
          ];
          expect(
            matching.any((o) => o.points.containsKey(r.destinationId)),
            isTrue,
          );
        }
      }
    });

    test('the flow collects answers, goes back and finishes', () {
      var f = const RecommendFlow();
      expect(f.index, 0);
      expect(f.isDone, isFalse);
      expect(f.result, isNull);
      expect(identical(f.back(), f), isTrue);
      f = f.answer(1).answer(2);
      expect(f.index, 2);
      expect(f.back().answers, [1]);
      f = f.answer(0).answer(3);
      expect(f.isDone, isTrue);
      expect(f.result!.destinationId, isNotEmpty);
      expect(
        identical(f.answer(0), f),
        isTrue,
        reason: 'no answers after the end',
      );
    });

    test('bad options are ignored', () {
      const f = RecommendFlow();
      expect(identical(f.answer(-1), f), isTrue);
      expect(identical(f.answer(4), f), isTrue);
    });
  });

  group('DecorState', () {
    test('adding places a selected decoration near the middle', () {
      final s = DecorState().add(DecorKind.diya);
      expect(s.items.single.kind, DecorKind.diya);
      expect(s.selectedId, s.items.single.id);
      expect(s.items.single.x, closeTo(0.5, 0.2));
      expect(s.items.single.y, closeTo(0.5, 0.2));
    });

    test('new decorations never land exactly on top of each other', () {
      var s = DecorState();
      for (var i = 0; i < 10; i++) {
        s = s.add(DecorKind.lantern);
      }
      final spots = {for (final i in s.items) (i.x, i.y)};
      expect(spots.length, greaterThanOrEqualTo(5));
      expect({for (final i in s.items) i.id}.length, 10, reason: 'ids unique');
    });

    test('there is a limit, then adding does nothing', () {
      var s = DecorState();
      for (var i = 0; i < decorMax + 5; i++) {
        s = s.add(DecorKind.diya);
      }
      expect(s.items.length, decorMax);
      expect(s.isFull, isTrue);
      expect(identical(s.add(DecorKind.garland), s), isTrue);
    });

    test('moving keeps a decoration on the picture', () {
      var s = DecorState().add(DecorKind.diya);
      final id = s.items.single.id;
      s = s.moveTo(id, 0.7, 0.3);
      expect(s.byId(id)!.x, 0.7);
      expect(s.byId(id)!.y, 0.3);
      s = s.moveTo(id, 5, -5);
      expect(s.byId(id)!.x, closeTo(0.95, 1e-9));
      expect(s.byId(id)!.y, closeTo(0.05, 1e-9));
      expect(identical(s.moveTo(id, 5, -5), s), isTrue);
      expect(identical(s.moveTo(999, 0.5, 0.5), s), isTrue);
    });

    test('arrow nudges move the selected one a step', () {
      var s = DecorState().add(DecorKind.rangoli);
      final start = s.selected!;
      s = s.nudge(DecorDirection.right);
      expect(s.selected!.x, closeTo(start.x + DecorState.nudgeStep, 1e-9));
      s = s.nudge(DecorDirection.up);
      expect(s.selected!.y, closeTo(start.y - DecorState.nudgeStep, 1e-9));
      s = s.nudge(DecorDirection.left).nudge(DecorDirection.down);
      expect(s.selected!.x, closeTo(start.x, 1e-9));
      expect(s.selected!.y, closeTo(start.y, 1e-9));
    });

    test('nudging with nothing selected does nothing', () {
      final s = DecorState().add(DecorKind.diya).select(null);
      expect(identical(s.nudge(DecorDirection.left), s), isTrue);
    });

    test('selecting brings a decoration to the front', () {
      var s = DecorState().add(DecorKind.diya).add(DecorKind.lantern);
      final firstId = s.items.first.id;
      expect(s.items.last.kind, DecorKind.lantern);
      s = s.select(firstId);
      expect(s.items.last.id, firstId);
      expect(s.selectedId, firstId);
      expect(identical(s.select(firstId), s), isTrue);
      expect(identical(s.select(999), s), isTrue);
    });

    test('deselecting keeps everything', () {
      final s = DecorState().add(DecorKind.diya).select(null);
      expect(s.selectedId, isNull);
      expect(s.items.length, 1);
    });

    test('removing takes away only the selected one', () {
      var s = DecorState().add(DecorKind.diya).add(DecorKind.lantern);
      s = s.removeSelected();
      expect(s.items.length, 1);
      expect(s.items.single.kind, DecorKind.diya);
      expect(s.selectedId, isNull);
      expect(identical(s.removeSelected(), s), isTrue);
    });

    test('clear empties the house', () {
      final s = DecorState().add(DecorKind.diya).add(DecorKind.garland).clear();
      expect(s.isEmpty, isTrue);
      final empty = DecorState();
      expect(identical(empty.clear(), empty), isTrue);
    });

    test('every kind has art and a name', () {
      expect(DecorKind.values.map((k) => k.id).toSet().length, 5);
      for (final k in DecorKind.values) {
        expect(k.label, isNotEmpty);
      }
    });
  });

  GoRouter router({String initial = '/', required Widget home}) => GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      ...const DeepavaliFeature().routes,
    ],
  );

  group('MoreSection extras', () {
    late _Sharer sharer;
    late _Picker picker;
    GoRouter? goRouter;

    Widget app({
      Widget? home,
      String initial = '/',
      double scale = 1,
      Size size = const Size(360, 800),
      bool withSharer = true,
    }) {
      goRouter = router(
        initial: initial,
        home:
            home ??
            const Scaffold(
              body: DiwaliMotionScope(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: MoreSection(),
                ),
              ),
            ),
      );
      return ProviderScope(
        overrides: [
          wishStoreProvider.overrideWithValue(_EmptyWishStore()),
          imageSharerProvider.overrideWithValue(withSharer ? sharer : null),
          photoPickerProvider.overrideWithValue(picker),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: MaterialApp.router(
            theme: DiwaliTheme.data,
            routerConfig: goRouter,
          ),
        ),
      );
    }

    setUp(() {
      sharer = _Sharer();
      picker = _Picker();
    });

    void extrasTest(
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

    extrasTest('the three launch and quiz cards are on the page', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Which city is for you?'), findsOneWidget);
      expect(find.text('Decorate your home'), findsOneWidget);
      expect(find.text('Photo booth'), findsOneWidget);
    });

    extrasTest('Start decorating opens the decorate screen and Back returns', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Start decorating');
      expect(find.byType(DecorateScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(DecorateScreen), findsNothing);
      expect(find.text('Decorate your home'), findsOneWidget);
    });

    extrasTest('Open photo booth opens the photo booth', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Open photo booth');
      expect(find.byType(PhotoBoothScreen), findsOneWidget);
    });

    extrasTest('find my city: answer four questions and read about it', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Find my city');
      // Varanasi pattern.
      final picks = [0, 0, 0, 1];
      for (var q = 0; q < 4; q++) {
        expect(find.text('Question ${q + 1} of 4'), findsOneWidget);
        await tapText(tester, recommendQuestions[q].options[picks[q]].label);
      }
      expect(find.text('Your Deepavali city is…'), findsOneWidget);
      expect(find.text('Varanasi'), findsWidgets);
      expect(find.text('Because you chose:'), findsOneWidget);
      await tapText(tester, 'Read about Varanasi');
      expect(find.text('How it’s celebrated'), findsOneWidget);
    });

    extrasTest('find my city: Previous takes an answer back; Cancel leaves', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Find my city');
      await tapText(tester, recommendQuestions[0].options[0].label);
      expect(find.text('Question 2 of 4'), findsOneWidget);
      await tapText(tester, 'Previous');
      expect(find.text('Question 1 of 4'), findsOneWidget);
      await tapText(tester, 'Cancel');
      expect(find.text('Find my city'), findsOneWidget);
    });

    extrasTest('find my city: Start again restarts', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapText(tester, 'Find my city');
      for (var q = 0; q < 4; q++) {
        await tapText(tester, recommendQuestions[q].options[0].label);
      }
      await tapText(tester, 'Start again');
      expect(find.text('Question 1 of 4'), findsOneWidget);
    });

    group('decorate screen', () {
      Future<void> open(
        WidgetTester tester, {
        double scale = 1,
        Size? size,
      }) async {
        await tester.pumpWidget(
          app(
            home: const DecorateScreen(),
            scale: scale,
            size: size ?? const Size(360, 800),
          ),
        );
        await tester.pumpAndSettle();
      }

      DecorState state(WidgetTester tester) =>
          ProviderScope.containerOf(tester.element(find.byType(DecorateScreen)))
              .read(decorProvider);

      Future<void> add(WidgetTester tester, String label) async {
        await tester.ensureVisible(find.bySemanticsLabel('Add $label'));
        await tester.tap(find.bySemanticsLabel('Add $label'));
        await tester.pump();
      }

      extrasTest('starts empty with a hint and no Share yet', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester);
        expect(find.text('Decorate your home'), findsOneWidget);
        expect(find.textContaining('Tap a decoration below'), findsOneWidget);
        for (final k in DecorKind.values) {
          expect(find.bySemanticsLabel('Add ${k.label}'), findsOneWidget);
        }
        await tester.ensureVisible(find.text('Share image'));
        await tester.tap(find.text('Share image'), warnIfMissed: false);
        await tester.pump();
        expect(sharer.shared, isEmpty, reason: 'nothing to share yet');
        handle.dispose();
      });

      extrasTest('adding puts decorations on the house', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester);
        await add(tester, 'Diya');
        await add(tester, 'Lantern');
        expect(state(tester).items.length, 2);
        expect(
          find.bySemanticsLabel(RegExp('Diya decoration')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Lantern decoration, selected'),
          findsOneWidget,
        );
        expect(find.text('Selected: Lantern'), findsOneWidget);
        handle.dispose();
      });

      extrasTest('dragging moves a decoration', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester);
        await add(tester, 'Diya');
        final before = state(tester).items.single;
        final target = find.bySemanticsLabel(RegExp('Diya decoration'));
        await tester.ensureVisible(target);
        await tester.drag(target, const Offset(60, 40));
        await tester.pump();
        final after = state(tester).items.single;
        expect(after.x, greaterThan(before.x));
        expect(after.y, greaterThan(before.y));
        handle.dispose();
      });

      extrasTest('dragging far off the picture keeps it inside', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await open(tester);
        await add(tester, 'Rangoli');
        final target = find.bySemanticsLabel(RegExp('Rangoli decoration'));
        await tester.ensureVisible(target);
        await tester.drag(target, const Offset(2000, 0));
        await tester.pump();
        expect(state(tester).items.single.x, lessThanOrEqualTo(0.95));
        handle.dispose();
      });

      extrasTest('arrow buttons and Remove work without dragging', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await open(tester);
        await add(tester, 'Garland');
        final x = state(tester).items.single.x;
        await tester.ensureVisible(find.byTooltip('Move right'));
        await tester.tap(find.byTooltip('Move right'));
        await tester.pump();
        expect(state(tester).items.single.x, greaterThan(x));
        await tester.tap(find.text('Remove'));
        await tester.pump();
        expect(state(tester).isEmpty, isTrue);
        expect(find.byTooltip('Move right'), findsNothing);
        handle.dispose();
      });

      extrasTest('tapping selects a decoration', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester);
        await add(tester, 'Diya');
        await add(tester, 'Sparkler');
        await tester.ensureVisible(
          find.bySemanticsLabel(RegExp('Diya decoration')),
        );
        await tester.tap(find.bySemanticsLabel(RegExp('Diya decoration')));
        await tester.pump();
        expect(state(tester).selected!.kind, DecorKind.diya);
        handle.dispose();
      });

      extrasTest('Clear asks first', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester);
        await add(tester, 'Diya');
        await tester.ensureVisible(find.text('Clear'));
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
        expect(find.text('Clear the house?'), findsOneWidget);
        await tester.tap(find.text('Keep them'));
        await tester.pumpAndSettle();
        expect(state(tester).items.length, 1);
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clear').last);
        await tester.pumpAndSettle();
        expect(state(tester).isEmpty, isTrue);
        handle.dispose();
      });

      extrasTest('the house fills up and says so', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(DecorateScreen)),
        );
        for (var i = 0; i < decorMax; i++) {
          container.read(decorProvider.notifier).add(DecorKind.diya);
        }
        await tester.pump();
        expect(find.textContaining('The house is full'), findsOneWidget);
        handle.dispose();
      });

      extrasTest('Share image sends a PNG of the house', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester);
        await add(tester, 'Diya');
        expect(state(tester).selectedId, isNotNull);
        await tester.ensureVisible(find.text('Share image'));
        await tester.runAsync(() async {
          await tester.tap(find.text('Share image'));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await tester.pump();
        expect(sharer.shared.length, 1);
        expect(sharer.shared.single.take(4), [0x89, 0x50, 0x4E, 0x47]);
        expect(sharer.names.single, 'my-decorated-home.png');
        handle.dispose();
      });

      extrasTest('a failed share offers Retry', (tester) async {
        sharer.fail = true;
        final handle = tester.ensureSemantics();
        await open(tester);
        await add(tester, 'Diya');
        await tester.ensureVisible(find.text('Share image'));
        await tester.runAsync(() async {
          await tester.tap(find.text('Share image'));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await tester.pump();
        expect(find.text('Could not share the picture.'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        handle.dispose();
      });

      for (final (name, size, scale) in [
        ('320x568 at 2x text', const Size(320, 568), 2.0),
        ('600x900', const Size(600, 900), 1.0),
      ]) {
        extrasTest('fits at $name', size: size, (tester) async {
          final handle = tester.ensureSemantics();
          await open(tester, scale: scale, size: size);
          for (final k in DecorKind.values) {
            await add(tester, k.label);
          }
          expect(tester.takeException(), isNull);
          handle.dispose();
        });
      }
    });

    group('photo booth', () {
      Future<void> open(
        WidgetTester tester, {
        double scale = 1,
        Size? size,
      }) async {
        await tester.pumpWidget(
          app(
            home: const PhotoBoothScreen(),
            scale: scale,
            size: size ?? const Size(360, 800),
          ),
        );
        await tester.pumpAndSettle();
      }

      extrasTest('starts with two ways to get a photo and a privacy note', (
        tester,
      ) async {
        await open(tester);
        expect(find.text('Photo booth'), findsOneWidget);
        expect(find.text('Take a photo'), findsOneWidget);
        expect(find.text('Choose from gallery'), findsOneWidget);
        expect(find.textContaining('stays on this phone'), findsOneWidget);
        expect(find.text('Share photo'), findsNothing);
      });

      extrasTest('taking a photo shows it in a frame', (tester) async {
        await open(tester);
        await tapText(tester, 'Take a photo');
        expect(picker.asked, [PhotoSource.camera]);
        expect(find.text('Happy Deepavali!'), findsOneWidget);
        expect(find.text('Retake'), findsOneWidget);
        expect(find.text('Share photo'), findsOneWidget);
        for (final f in PhotoFrame.values) {
          expect(find.text(f.label), findsOneWidget);
        }
      });

      extrasTest('choosing from the gallery works too', (tester) async {
        await open(tester);
        await tapText(tester, 'Choose from gallery');
        expect(picker.asked, [PhotoSource.gallery]);
        expect(find.text('Share photo'), findsOneWidget);
      });

      extrasTest('every frame renders', (tester) async {
        await open(tester);
        await tapText(tester, 'Take a photo');
        for (final f in PhotoFrame.values) {
          await tapText(tester, f.label);
          expect(tester.takeException(), isNull, reason: f.label);
        }
      });

      extrasTest('backing out of the camera changes nothing', (tester) async {
        picker.result = null;
        await open(tester);
        await tapText(tester, 'Take a photo');
        expect(find.text('Share photo'), findsNothing);
        expect(find.text('Take a photo'), findsOneWidget);
        expect(find.textContaining('went wrong'), findsNothing);
      });

      extrasTest(
        'camera access denied says how to fix it and offers the gallery',
        (tester) async {
          picker.failure = PhotoFailure.denied;
          await open(tester);
          await tapText(tester, 'Take a photo');
          expect(find.textContaining('Camera access is off'), findsOneWidget);
          expect(find.text('Choose from gallery'), findsOneWidget);
          // The gallery still works.
          picker.failure = null;
          await tapText(tester, 'Choose from gallery');
          expect(find.text('Share photo'), findsOneWidget);
          expect(find.textContaining('Camera access is off'), findsNothing);
        },
      );

      extrasTest('no camera on the device is explained', (tester) async {
        picker.failure = PhotoFailure.unavailable;
        await open(tester);
        await tapText(tester, 'Take a photo');
        expect(find.textContaining('No camera is available'), findsOneWidget);
      });

      extrasTest('any other failure is reported and recoverable', (
        tester,
      ) async {
        picker.failure = PhotoFailure.failed;
        await open(tester);
        await tapText(tester, 'Take a photo');
        expect(find.textContaining('Something went wrong'), findsOneWidget);
        picker.failure = null;
        await tapText(tester, 'Take a photo');
        expect(find.text('Share photo'), findsOneWidget);
        expect(find.textContaining('Something went wrong'), findsNothing);
      });

      extrasTest('Share photo sends a PNG', (tester) async {
        await open(tester);
        await tapText(tester, 'Take a photo');
        await tester.ensureVisible(find.text('Share photo'));
        await tester.runAsync(() async {
          await tester.tap(find.text('Share photo'));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await tester.pump();
        expect(sharer.shared.length, 1);
        expect(sharer.shared.single.take(4), [0x89, 0x50, 0x4E, 0x47]);
        expect(sharer.names.single, 'deepavali-photo.png');
      });

      extrasTest('without a sharer there is no Share button', (tester) async {
        await tester.pumpWidget(
          app(home: const PhotoBoothScreen(), withSharer: false),
        );
        await tester.pumpAndSettle();
        await tapText(tester, 'Take a photo');
        expect(find.text('Share photo'), findsNothing);
      });

      for (final (name, size, scale) in [
        ('320x568 at 2x text', const Size(320, 568), 2.0),
        ('600x900', const Size(600, 900), 1.0),
      ]) {
        extrasTest('fits at $name', size: size, (tester) async {
          picker.failure = PhotoFailure.denied;
          await open(tester, scale: scale, size: size);
          await tapText(tester, 'Take a photo');
          expect(tester.takeException(), isNull);
          picker.failure = null;
          await tapText(tester, 'Choose from gallery');
          expect(tester.takeException(), isNull);
        });
      }
    });
  });
}
