import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/greeting.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/image_sharer.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/sections/greeting_section.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/state/greeting_notifier.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/diwali_theme.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/theme/greeting_styles.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/widgets/greeting_card_view.dart';

import '../../helpers.dart';

class _Sharer implements ImageSharer {
  final List<Uint8List> shared = [];
  final List<String?> captions = [];
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
    captions.add(text);
    names.add(fileName);
  }
}

/// WCAG contrast ratio between two colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  reduceMotionForAllTests();

  group('GreetingCard', () {
    test('starts with the first preset and no name', () {
      final c = GreetingCard.initial();
      expect(c.message, greetingPresets.first);
      expect(c.hasFrom, isFalse);
      expect(c.design, GreetingDesign.goldenDiyas);
    });

    test('presets are usable', () {
      expect(greetingPresets.length, 4);
      expect(greetingPresets.toSet().length, 4);
      for (final p in greetingPresets) {
        expect(p.trim(), isNotEmpty);
        expect(p.runes.length, lessThanOrEqualTo(greetingMessageMax));
      }
    });

    test('four designs with names', () {
      expect(GreetingDesign.values.length, 4);
      expect(GreetingDesign.values.map((d) => d.label).toSet().length, 4);
    });

    test('whitespace is tidied and edges trimmed', () {
      expect(
        GreetingCard.clean('  Happy \n\n  Diwali\t! ', 50),
        'Happy Diwali !',
      );
      expect(GreetingCard.clean('   ', 50), '');
    });

    test('the message is cut at the limit', () {
      final long = 'a' * (greetingMessageMax + 40);
      final c = const GreetingCard().withMessage(long);
      expect(c.message.length, greetingMessageMax);
    });

    test('exactly at the limit is kept whole', () {
      final exact = 'b' * greetingMessageMax;
      expect(const GreetingCard().withMessage(exact).message, exact);
    });

    test('the name has its own, shorter limit', () {
      final c = const GreetingCard().withFrom('N' * 80);
      expect(c.from.length, greetingNameMax);
    });

    test('a blank name counts as none', () {
      final c = const GreetingCard().withFrom('   ');
      expect(c.hasFrom, isFalse);
      expect(c.summary, isNot(contains('from')));
    });

    test('cutting never splits an emoji or an Indian-script letter', () {
      final emoji = '🪔' * (greetingMessageMax + 5);
      final cut = const GreetingCard().withMessage(emoji).message;
      expect(cut.runes.length, greetingMessageMax);
      expect(cut.runes.every((r) => r == 0x1FA94), isTrue);

      final hindi = 'दीपावली ' * 30;
      final c = const GreetingCard().withMessage(hindi);
      expect(c.message.runes.length, lessThanOrEqualTo(greetingMessageMax));
      expect(c.message, startsWith('दीपावली'));
    });

    test('design changes only when different', () {
      const c = GreetingCard();
      expect(identical(c.withDesign(c.design), c), isTrue);
      expect(
        c.withDesign(GreetingDesign.nightLanterns).design,
        GreetingDesign.nightLanterns,
      );
    });

    test('summary names the design, message and sender', () {
      const c = GreetingCard(
        design: GreetingDesign.marigoldGarland,
        message: 'Joy to all',
        from: 'Asha',
      );
      expect(c.summary, contains('Marigold Garland'));
      expect(c.summary, contains('Joy to all'));
      expect(c.summary, contains('from Asha'));
      expect(const GreetingCard().summary, contains('Happy Deepavali'));
    });

    test('equal cards are equal', () {
      expect(
        const GreetingCard(message: 'x', from: 'y'),
        const GreetingCard(message: 'x', from: 'y'),
      );
      expect(const GreetingCard(message: 'x'), isNot(const GreetingCard()));
    });
  });

  group('card colours', () {
    test(
      'every design keeps its text readable (4.5:1 on every background)',
      () {
        for (final d in GreetingDesign.values) {
          final style = GreetingStyles.of(d);
          for (final bg in style.background) {
            expect(
              _contrast(style.title, bg),
              greaterThanOrEqualTo(4.5),
              reason: '${d.name} title',
            );
            expect(
              _contrast(style.body, bg),
              greaterThanOrEqualTo(4.5),
              reason: '${d.name} body',
            );
            expect(
              _contrast(style.accent, bg),
              greaterThanOrEqualTo(4.5),
              reason: '${d.name} sender name',
            );
          }
        }
      },
    );
  });

  group('GreetingSection', () {
    late _Sharer sharer;

    final longest = GreetingCard.clean(
      List.filled(40, 'Wishing').join(' '),
      greetingMessageMax,
    );

    Widget app({
      double scale = 1,
      Size size = const Size(360, 800),
      double keyboard = 0,
    }) => ProviderScope(
      overrides: [imageSharerProvider.overrideWithValue(sharer)],
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
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: GreetingSection(),
            ),
          ),
        ),
      ),
    );

    setUp(() => sharer = _Sharer());

    void greetTest(
      String name,
      Future<void> Function(WidgetTester tester) body, {
      Size size = const Size(360, 800),
    }) => testWidgets(name, (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await body(tester);
    });

    GreetingCard card(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(GreetingSection)))
            .read(greetingProvider);

    greetTest('shows the card, designs and buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      expect(find.text('Greeting Card'), findsOneWidget);
      expect(find.text('Happy Deepavali!'), findsOneWidget);
      expect(find.text(greetingPresets.first), findsOneWidget);
      expect(find.text('Customise message'), findsOneWidget);
      expect(find.text('Share card'), findsOneWidget);
      for (final d in GreetingDesign.values) {
        expect(
          find.bySemanticsLabel(RegExp('^${d.label}(, selected)?\$')),
          findsOneWidget,
        );
      }
      handle.dispose();
    });

    greetTest(
      'the four design thumbnails share one row, even on a small phone',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(app(size: const Size(320, 568), scale: 2));
        final tops = <double>{};
        for (final d in GreetingDesign.values) {
          final f = find.bySemanticsLabel(RegExp('^${d.label}(, selected)?\$'));
          await tester.ensureVisible(f.first);
          tops.add(tester.getRect(f.first).top);
        }
        expect(tops.length, 1, reason: 'one row');
        handle.dispose();
      },
      size: const Size(320, 568),
    );

    greetTest('picking a design changes the card', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.ensureVisible(find.bySemanticsLabel('Night Sky Lanterns'));
      await tester.tap(find.bySemanticsLabel('Night Sky Lanterns'));
      await tester.pump();
      expect(card(tester).design, GreetingDesign.nightLanterns);
      expect(
        find.bySemanticsLabel('Night Sky Lanterns, selected'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Greeting card, Night Sky Lanterns')),
        findsOneWidget,
      );
      handle.dispose();
    });

    greetTest('the card is one labelled picture for screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      expect(
        find.bySemanticsLabel(
          'Greeting card, Golden Diyas: ${greetingPresets.first}',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    greetTest('customising: type a message and a name', (tester) async {
      await tester.pumpWidget(app());
      await tester.ensureVisible(find.text('Customise message'));
      await tester.tap(find.text('Customise message'));
      await tester.pumpAndSettle();
      expect(find.text('Customise your card'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Your message'),
        'Light and love to you',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'From (optional)'),
        'Asha',
      );
      await tester.pump();
      expect(card(tester).message, 'Light and love to you');
      expect(card(tester).from, 'Asha');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Light and love to you'), findsOneWidget);
      expect(find.text('— Asha'), findsOneWidget);
    });

    greetTest('a preset wish fills the message', (tester) async {
      await tester.pumpWidget(app());
      await tester.ensureVisible(find.text('Customise message'));
      await tester.tap(find.text('Customise message'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(greetingPresets[2]));
      await tester.pump();
      expect(card(tester).message, greetingPresets[2]);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Your message'))
            .controller!
            .text,
        greetingPresets[2],
      );
    });

    greetTest('the message field stops at the limit and shows a counter', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.ensureVisible(find.text('Customise message'));
      await tester.tap(find.text('Customise message'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Your message'),
        'x' * (greetingMessageMax + 30),
      );
      await tester.pump();
      expect(card(tester).message.length, greetingMessageMax);
      expect(
        find.text('$greetingMessageMax/$greetingMessageMax'),
        findsOneWidget,
      );
    });

    greetTest('clearing the name removes it from the card', (tester) async {
      await tester.pumpWidget(app());
      await tester.ensureVisible(find.text('Customise message'));
      await tester.tap(find.text('Customise message'));
      await tester.pumpAndSettle();
      final from = find.widgetWithText(TextField, 'From (optional)');
      await tester.enterText(from, 'Ravi');
      await tester.pump();
      expect(card(tester).hasFrom, isTrue);
      await tester.enterText(from, '   ');
      await tester.pump();
      expect(card(tester).hasFrom, isFalse);
    });

    greetTest('the sheet stays usable with the keyboard open', (tester) async {
      await tester.pumpWidget(app(keyboard: 320));
      await tester.ensureVisible(find.text('Customise message'));
      await tester.tap(find.text('Customise message'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Done'), findsOneWidget);
    });

    greetTest('Share card sends a PNG with the caption', (tester) async {
      await tester.pumpWidget(app());
      await tester.ensureVisible(find.text('Share card'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Share card'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();
      expect(sharer.shared.length, 1);
      expect(sharer.shared.single.take(4), [0x89, 0x50, 0x4E, 0x47]);
      expect(sharer.captions.single, greetingShareText);
      expect(sharer.names.single, 'deepavali-greeting.png');
      expect(find.text('Share card'), findsOneWidget, reason: 'button is back');
    });

    greetTest('a failed share says so and offers Retry', (tester) async {
      sharer.fail = true;
      await tester.pumpWidget(app());
      await tester.ensureVisible(find.text('Share card'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Share card'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();
      expect(find.text('Could not share the picture.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Share card'), findsOneWidget);
    });

    for (final design in GreetingDesign.values) {
      for (final (name, size, scale) in [
        ('320x568 at 2x text', const Size(320, 568), 2.0),
        ('600x900', const Size(600, 900), 1.0),
      ]) {
        greetTest(
          '${design.label} fits the longest message at $name',
          size: size,
          (tester) async {
            await tester.pumpWidget(app(scale: scale, size: size));
            final container = ProviderScope.containerOf(
              tester.element(find.byType(GreetingSection)),
            );
            container.read(greetingProvider.notifier)
              ..setDesign(design)
              ..setMessage(longest)
              ..setFrom('N' * greetingNameMax);
            await tester.pump();
            expect(tester.takeException(), isNull);
            final box = tester.getRect(find.byType(GreetingCardView));
            expect(box.width, lessThanOrEqualTo(size.width));
            expect(box.height / box.width, closeTo(5 / 4, 0.01));
          },
        );
      }
    }

    greetTest('a long unbroken word and no message still render', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GreetingSection)),
      );
      container.read(greetingProvider.notifier).setMessage('W' * 100);
      await tester.pump();
      expect(tester.takeException(), isNull);
      container.read(greetingProvider.notifier)
        ..setMessage('')
        ..setFrom('');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Happy Deepavali!'), findsOneWidget);
    });
  });
}
