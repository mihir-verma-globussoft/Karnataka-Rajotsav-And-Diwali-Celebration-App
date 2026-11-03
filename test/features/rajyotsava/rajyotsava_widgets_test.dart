import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/presentation/widgets/rajyotsava_widgets.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_providers.dart';

import '../../helpers.dart';

/// 3 November 2026: 363 days before the 72nd Rajyotsava.
final _today = DateTime(2026, 11, 3);

List<Override> _overrides({DateTime? today}) => [
  rajyotsavaClockProvider.overrideWithValue(() => today ?? _today),
  quizRandomProvider.overrideWithValue(Random(1)),
];

Future<void> _pumpHome(WidgetTester tester, {DateTime? today}) async {
  await tester.pumpWidget(testApp(overrides: _overrides(today: today)));
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
      await _pumpHome(tester);
      expect(find.text('ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವ'), findsOneWidget);
      expect(find.text('363 days to the 72nd Rajyotsava'), findsOneWidget);
      expect(find.text('Rajyotsava Quiz'), findsOneWidget);
      expect(find.text('Learn Kannada'), findsOneWidget);
      expect(find.text('Discover Karnataka'), findsOneWidget);
    });

    testWidgets('draws both stripes of the Kannada flag', (tester) async {
      await _pumpHome(tester);
      final stripes = find.descendant(
        of: find.byType(KannadaFlag),
        matching: find.byType(ColoredBox),
      );
      expect(stripes, findsNWidgets(2));
      for (final size in [
        tester.getSize(stripes.first),
        tester.getSize(stripes.last),
      ]) {
        // The banner flag is 56 wide, 3:2, so each stripe is a third high.
        expect(size.width, 56);
        expect(size.height, closeTo(56 / 3, 0.01));
      }
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
      _phone(tester, height: 3000);
      await _pumpHome(tester);
      final before = tester
          .widget<Text>(find.byKey(const ValueKey('rajyotsava-fact')))
          .data;
      await tester.tap(find.text('Next fact'));
      await tester.pump();
      final after = tester
          .widget<Text>(find.byKey(const ValueKey('rajyotsava-fact')))
          .data;
      expect(after, isNot(before));
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
      _phone(tester, height: 3000);
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
    testWidgets('switches between alphabet, phrases and numbers', (
      tester,
    ) async {
      await _pumpHome(tester);
      await _push(tester, RajyotsavaRoutes.learn);
      expect(find.text('ಅ'), findsOneWidget);

      await tester.tap(find.text('ಅ'));
      await tester.pumpAndSettle();
      expect(find.text('Sounds like "a"'), findsOneWidget);
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
