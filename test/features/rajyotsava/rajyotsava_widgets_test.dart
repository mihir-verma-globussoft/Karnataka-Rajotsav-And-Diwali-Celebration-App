import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/kannada_speaker.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/rajyotsava_motion.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_providers.dart';

import '../../helpers.dart';

/// 3 November 2026: 363 days before the 72nd Rajyotsava.
final _today = DateTime(2026, 11, 3);

/// Records what would be spoken.
class _FakeSpeaker implements KannadaSpeaker {
  _FakeSpeaker({this.available = true});

  final bool available;
  final List<String> spoken = [];
  var stopped = false;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stopped = true;
}

List<Override> _overrides({DateTime? today, KannadaSpeaker? speaker}) => [
  rajyotsavaClockProvider.overrideWithValue(() => today ?? _today),
  quizRandomProvider.overrideWithValue(Random(1)),
  kannadaSpeakerProvider.overrideWithValue(speaker ?? _FakeSpeaker()),
];

Future<void> _pumpHome(
  WidgetTester tester, {
  DateTime? today,
  KannadaSpeaker? speaker,
}) async {
  await tester.pumpWidget(
    testApp(
      overrides: _overrides(today: today, speaker: speaker),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first))
      .push<void>(path)
      .ignore();
  await tester.pumpAndSettle();
}

/// Phone-sized window; optionally with large text. Use a tall [height] when
/// a test taps content far down a list: off-screen list items are not built,
/// and the floating bottom bar covers the lowest part of the tab.
void _phone(
  WidgetTester tester, {
  double width = 360,
  double height = 640,
  double text = 1,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  group('Rajyotsava tab', () {
    testWidgets('shows greeting, countdown and explore links', (tester) async {
      _phone(tester, height: 2000);
      await _pumpHome(tester);
      expect(find.text('ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವ'), findsOneWidget);
      expect(find.text('363 days to the 72nd Rajyotsava'), findsOneWidget);
      expect(find.text('Rajyotsava Quiz'), findsOneWidget);
      expect(find.text('Learn Kannada'), findsOneWidget);
      expect(find.text('Discover Karnataka'), findsOneWidget);
    });

    testWidgets('the banner flag is 3:2 and labelled', (tester) async {
      await _pumpHome(tester);
      final flag = find.byType(WavingFlag);
      expect(flag, findsOneWidget);
      final size = tester.getSize(
        find.descendant(of: flag, matching: find.byType(CustomPaint)),
      );
      expect(size.width, 56);
      expect(size.height, closeTo(56 * 2 / 3, 0.01));
      expect(find.bySemanticsLabel('Kannada flag'), findsOneWidget);
    });

    testWidgets('the countdown counts up to the days left', (tester) async {
      await tester.pumpWidget(testApp(overrides: _overrides()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('363 days to the 72nd Rajyotsava'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('363 days to the 72nd Rajyotsava'), findsOneWidget);
    });

    testWidgets('with reduced motion it shows the countdown at once', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(testApp(overrides: _overrides()));
      await tester.pump();
      await tester.pump();
      expect(find.text('363 days to the 72nd Rajyotsava'), findsOneWidget);
    });

    testWidgets('Start exploring scrolls to the Explore section', (
      tester,
    ) async {
      _phone(tester);
      await _pumpHome(tester);
      expect(find.byType(Toran), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('rajyotsava-start-exploring')),
      );
      await tester.pumpAndSettle();
      final explore = tester.getTopLeft(find.text('Explore'));
      expect(explore.dy, lessThan(200));
    });

    testWidgets('tapping the banner launches a firework, then it settles', (
      tester,
    ) async {
      _phone(tester);
      await _pumpHome(tester);
      expect(find.byType(Fireworks), findsOneWidget);
      // An empty spot on the right of the banner, below the toran.
      await tester.tapAt(const Offset(330, 150));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('celebrates on 1 November', (tester) async {
      await _pumpHome(tester, today: DateTime(2026, 11, 1));
      expect(find.text('Happy Kannada Rajyotsava!'), findsOneWidget);
      expect(
        find.text('Today is the 71st Kannada Rajyotsava!'),
        findsOneWidget,
      );
    });

    testWidgets('next fact changes the fact', (tester) async {
      _phone(tester, height: 4000);
      await _pumpHome(tester);
      String fact() => tester
          .widget<Text>(
            find.descendant(
              of: find.byType(AnimatedSwitcher),
              matching: find.byType(Text),
            ),
          )
          .data!;
      final before = fact();
      await tester.tap(find.text('Next fact'));
      await tester.pumpAndSettle();
      expect(fact(), isNot(before));
    });

    testWidgets('wishes can be heard in Kannada', (tester) async {
      _phone(tester, height: 4000);
      final speaker = _FakeSpeaker();
      await _pumpHome(tester, speaker: speaker);
      await tester.tap(
        find.byTooltip('Listen to ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವದ ಹಾರ್ದಿಕ ಶುಭಾಶಯಗಳು!'),
      );
      await tester.pump();
      expect(speaker.spoken, ['ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವದ ಹಾರ್ದಿಕ ಶುಭಾಶಯಗಳು!']);
    });

    testWidgets('copying a wish shows a confirmation', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      _phone(tester, height: 4000);
      await _pumpHome(tester);
      await tester.tap(find.byTooltip('Copy wish').first);
      // The clipboard write completes asynchronously, then the snack bar
      // animates in.
      await tester.pumpAndSettle();
      expect(copied, contains('ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವದ'));
      expect(find.text('Wish copied. Paste it in any chat.'), findsOneWidget);
    });

    for (final (key, title) in [
      ('rajyotsava-quiz', 'Rajyotsava Quiz'),
      ('rajyotsava-learn', 'Learn Kannada'),
      ('rajyotsava-discover', 'Discover Karnataka'),
    ]) {
      testWidgets('"$title" opens and back returns', (tester) async {
        _phone(tester, height: 1600);
        await _pumpHome(tester);
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        expect(find.byType(BackButton), findsOneWidget);
        expect(find.widgetWithText(AppBar, title), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(BackButton), findsNothing);
      });
    }
  });

  group('Quiz', () {
    testWidgets('answers ten questions and shows the results', (tester) async {
      _phone(tester, height: 1600);
      await _pumpHome(tester);
      await _push(tester, RajyotsavaRoutes.quiz);

      for (var i = 0; i < QuizController.questionsPerRound; i++) {
        expect(find.text('Question ${i + 1} of 10'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('quiz-option-0')));
        await tester.pump();
        expect(find.byKey(const ValueKey('quiz-next')), findsOneWidget);
        await tester.ensureVisible(find.byKey(const ValueKey('quiz-next')));
        await tester.tap(find.byKey(const ValueKey('quiz-next')));
        await tester.pump();
      }

      expect(find.byKey(const ValueKey('quiz-result')), findsOneWidget);
      expect(find.text('Your answers'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('quiz-restart')));
      await tester.pump();
      expect(find.text('Question 1 of 10'), findsOneWidget);
    });

    testWidgets('an answer cannot be changed', (tester) async {
      await _pumpHome(tester);
      await _push(tester, RajyotsavaRoutes.quiz);
      await tester.tap(find.byKey(const ValueKey('quiz-option-0')));
      await tester.pump();
      final score = tester
          .widget<Text>(find.byKey(const ValueKey('quiz-score')))
          .data;
      await tester.tap(find.byKey(const ValueKey('quiz-option-1')));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('quiz-score'))).data,
        score,
      );
    });
  });

  group('Learn Kannada', () {
    testWidgets('speaks letters, phrases and numbers in Kannada', (
      tester,
    ) async {
      final speaker = _FakeSpeaker();
      await _pumpHome(tester, speaker: speaker);
      await _push(tester, RajyotsavaRoutes.learn);

      await tester.tap(find.text('ಅ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Listen'));
      await tester.pump();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phrases'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Listen to ನಮಸ್ಕಾರ'));
      await tester.pump();

      await tester.tap(find.text('Numbers'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Listen to ಒಂದು'));
      await tester.pump();

      expect(speaker.spoken, ['ಅ', 'ನಮಸ್ಕಾರ', 'ಒಂದು']);
    });

    testWidgets('explains how to install a missing Kannada voice', (
      tester,
    ) async {
      final speaker = _FakeSpeaker(available: false);
      await _pumpHome(tester, speaker: speaker);
      await _push(tester, RajyotsavaRoutes.learn);
      await tester.tap(find.text('Phrases'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Listen to ನಮಸ್ಕಾರ'));
      await tester.pump();
      expect(
        find.textContaining('Kannada voice not installed'),
        findsOneWidget,
      );
      expect(speaker.spoken, isEmpty);
    });

    testWidgets('the letter sheet fits a small phone at 2x text', (
      tester,
    ) async {
      _phone(tester, width: 320, height: 568, text: 2);
      await _pumpHome(tester);
      await _push(tester, RajyotsavaRoutes.learn);
      await tester.tap(find.text('ಅ'));
      await tester.pumpAndSettle();
      expect(find.text('Sounds like "a"'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches between alphabet, phrases and numbers', (
      tester,
    ) async {
      await _pumpHome(tester);
      await _push(tester, RajyotsavaRoutes.learn);
      expect(find.text('ಅ'), findsOneWidget);

      await tester.tap(find.text('ಅ'));
      await tester.pumpAndSettle();
      expect(find.text('Sounds like "a"'), findsOneWidget);
      // Arrows step through the vowels without closing the sheet.
      await tester.tap(find.byTooltip('Next letter'));
      await tester.pumpAndSettle();
      expect(find.text('Sounds like "ā"'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous letter'));
      await tester.tap(find.byTooltip('Previous letter'));
      await tester.pumpAndSettle();
      expect(find.text('Sounds like "ah"'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phrases'));
      await tester.pumpAndSettle();
      expect(find.text('ನಮಸ್ಕಾರ'), findsOneWidget);

      await tester.tap(find.text('Numbers'));
      await tester.pumpAndSettle();
      expect(find.text('ಒಂದು'), findsOneWidget);
    });
  });

  group('Discover Karnataka', () {
    testWidgets('filters by category and opens a detail page', (tester) async {
      await _pumpHome(tester);
      await _push(tester, RajyotsavaRoutes.discover);
      expect(find.text('Hampi'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('discover-filter-Food')));
      await tester.pumpAndSettle();
      expect(find.text('Hampi'), findsNothing);
      expect(find.text('Mysore Pak'), findsOneWidget);

      await tester.tap(find.text('Mysore Pak'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Mysore Pak'), findsOneWidget);
      // Below the photo, so scroll to it.
      await tester.scrollUntilVisible(find.text('Highlights'), 200);
      expect(find.text('Highlights'), findsOneWidget);
    });

    testWidgets('unknown item shows not found', (tester) async {
      await _pumpHome(tester);
      await _push(tester, RajyotsavaRoutes.discoverItem('nope'));
      expect(find.text('We could not find that page.'), findsOneWidget);
      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsNothing);
    });
  });

  group('small screen, 2x text', () {
    for (final path in [
      null,
      RajyotsavaRoutes.quiz,
      RajyotsavaRoutes.learn,
      RajyotsavaRoutes.discover,
      RajyotsavaRoutes.discoverItem('hampi'),
    ]) {
      testWidgets('${path ?? 'tab'} has no overflow at 320dp', (tester) async {
        _phone(tester, width: 320, text: 2);
        await _pumpHome(tester);
        if (path != null) await _push(tester, path);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
