import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/content/explorer_topics.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/deepavali_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/deepavali_page.dart';

class _Store implements DeepavaliStore {
  @override
  Future<bool> introSeen() async => true;
  @override
  Future<void> markIntroSeen() async {}
}

Widget _host({double scale = 1, Size size = const Size(360, 800)}) =>
    ProviderScope(
      overrides: [
        deepavaliStoreProvider.overrideWithValue(_Store()),
        deepavaliNowProvider.overrideWithValue(
          () => DateTime.utc(2026, 11, 7, 6),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: TextScaler.linear(scale),
        ),
        child: const MaterialApp(home: DeepavaliPage()),
      ),
    );

int _words(ExplorerTopic t) => [
  t.teaser,
  ...t.paragraphs,
  t.regionalNote ?? '',
  t.didYouKnow ?? '',
].join(' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

void main() {
  group('explorer content', () {
    test('has the six requested topics with unique ids', () {
      expect(explorerTopics.map((t) => t.id).toSet().length, 6);
      expect(
        explorerTopics.map((t) => t.title),
        containsAll([
          'Significance',
          'Traditions',
          'Rangoli',
          'Festive sweets',
          'Rituals',
          'Five days of Diwali',
        ]),
      );
    });

    test('is concise and complete', () {
      for (final t in explorerTopics) {
        expect(t.title.trim(), isNotEmpty);
        expect(t.teaser.trim(), isNotEmpty);
        expect(_words(t), lessThanOrEqualTo(180), reason: t.id);
        if (t.id != fiveDaysTopicId) {
          expect(t.paragraphs, isNotEmpty, reason: t.id);
          expect(t.regionalNote, isNotNull, reason: '${t.id} regional note');
        }
      }
    });
  });

  group('explorer section', () {
    testWidgets('every text topic opens its sheet and closes', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host());
      await tester.pump();
      for (final t in explorerTopics.where((t) => t.id != fiveDaysTopicId)) {
        await tester.scrollUntilVisible(
          find.text(t.title),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(t.title));
        await tester.pumpAndSettle();
        expect(find.text('Regional note'), findsOneWidget, reason: t.id);
        expect(find.text(t.paragraphs.first), findsOneWidget, reason: t.id);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Regional note'), findsNothing);
      }
    });

    testWidgets('five days card opens the timeline with today marked', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Five days of Diwali'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Five days of Diwali'));
      await tester.pumpAndSettle();
      expect(find.text('The five days of Deepavali'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('all six cards are visible with real height', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host());
      await tester.pump();
      for (final t in explorerTopics) {
        await tester.scrollUntilVisible(
          find.text(t.title),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.getSize(find.text(t.title)).height, greaterThan(0));
      }
      // Cards in one row share a height.
      final a = tester.getSize(
        find
            .ancestor(of: find.text('Rituals'), matching: find.byType(Ink))
            .first,
      );
      final b = tester.getSize(
        find
            .ancestor(
              of: find.text('Five days of Diwali'),
              matching: find.byType(Ink),
            )
            .first,
      );
      expect(a.height, b.height);
      expect(a.height, greaterThan(60));
    });

    testWidgets('cards expose button semantics', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Rangoli'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.bySemanticsLabel(
          'Rangoli. Colourful floor art to welcome guests. Opens details.',
        ),
        findsOneWidget,
      );
    });

    for (final (name, scale, size) in [
      ('320dp 2x text', 2.0, const Size(320, 568)),
      ('360dp', 1.0, const Size(360, 800)),
      ('840dp', 1.0, const Size(840, 900)),
    ]) {
      testWidgets('lays out at $name incl. sheet', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_host(scale: scale, size: size));
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text('Traditions'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Traditions'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
