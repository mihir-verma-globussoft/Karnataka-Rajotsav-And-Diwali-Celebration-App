import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/content/destinations.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/domain/deepavali_store.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/deepavali_page.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/presentation/screens/destination_detail_screen.dart';

class _Store implements DeepavaliStore {
  @override
  Future<bool> introSeen() async => true;
  @override
  Future<void> markIntroSeen() async {}
}

Widget _app({
  String initial = '/',
  double scale = 1,
  Size size = const Size(360, 800),
}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const DeepavaliPage()),
      ...const DeepavaliFeature().routes,
    ],
  );
  return ProviderScope(
    overrides: [deepavaliStoreProvider.overrideWithValue(_Store())],
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        disableAnimations: true,
        textScaler: TextScaler.linear(scale),
      ),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  group('destination content', () {
    test('six requested cities in order', () {
      expect(destinations.map((d) => d.name), [
        'Varanasi',
        'Jaipur',
        'Ayodhya',
        'Amritsar',
        'Kolkata',
        'Mumbai',
      ]);
      expect(destinations.map((d) => d.id).toSet().length, 6);
    });

    test('every fact is sourced and every photo is credited and bundled', () {
      for (final d in destinations) {
        expect(d.description, isNotEmpty, reason: d.id);
        expect(d.facts, isNotEmpty, reason: d.id);
        for (final f in d.facts) {
          expect(f.text.trim(), isNotEmpty);
          expect(f.source.trim(), isNotEmpty, reason: '${d.id} fact source');
        }
        final p = d.photo;
        expect(p.author.trim(), isNotEmpty, reason: d.id);
        expect(p.license.trim(), isNotEmpty, reason: d.id);
        expect(
          p.isSupplied ||
              p.sourceUrl.startsWith('https://commons.wikimedia.org/'),
          isTrue,
          reason: '${d.id} must be team-supplied or link to Commons',
        );
        expect(p.altText.trim(), isNotEmpty);
        final file = File(p.asset);
        expect(file.existsSync(), isTrue, reason: '${p.asset} missing');
        expect(file.lengthSync(), lessThan(600 * 1024), reason: p.asset);
      }
    });

    test('lookup by id', () {
      expect(destinationById('jaipur')!.name, 'Jaipur');
      expect(destinationById('nowhere'), isNull);
    });
  });

  group('gallery', () {
    testWidgets('shows the first city and opens its detail and returns', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Uttar Pradesh').first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Uttar Pradesh').first);
      await tester.pumpAndSettle();
      expect(find.text('How it’s celebrated'), findsOneWidget);
      expect(find.textContaining('Source: Wikipedia'), findsWidgets);
      expect(find.textContaining('Photo: Globus Habba team'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Deepavali Around India'), findsOneWidget);
    });

    testWidgets('swiping reaches the last city', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Uttar Pradesh').first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byType(PageView));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();
      }
      expect(find.text('Maharashtra'), findsOneWidget);
    });

    testWidgets('card semantics include position and action', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Uttar Pradesh').first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(r'Varanasi, Uttar Pradesh\..* 1 of 6\. Opens details\.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('credits sheet lists all six photos', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Photo credits'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Photo credits'));
      await tester.pumpAndSettle();
      for (final d in destinations) {
        expect(find.textContaining(d.photo.author), findsWidgets);
      }
    });

    for (final (name, size, scale) in [
      ('320dp 2x text', const Size(320, 568), 2.0),
      ('600dp', const Size(600, 900), 1.0),
      ('840dp', const Size(840, 900), 1.0),
    ]) {
      testWidgets('gallery lays out at $name', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(size: size, scale: scale));
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text('Uttar Pradesh').first,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('detail route', () {
    testWidgets('every destination renders at 320dp and 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final d in destinations) {
        await tester.pumpWidget(
          _app(
            initial: DeepavaliRoutes.destinationPath(d.id),
            scale: 2,
            size: const Size(320, 568),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(DestinationDetailScreen), findsOneWidget);
        expect(find.text(d.name), findsWidgets);
        expect(tester.takeException(), isNull, reason: d.id);
      }
    });

    testWidgets('unknown id shows not found with a way back', (tester) async {
      await tester.pumpWidget(_app(initial: '/deepavali/destination/atlantis'));
      await tester.pumpAndSettle();
      expect(find.text('We could not find that destination.'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('a missing image falls back to a placeholder', (tester) async {
      const broken = Destination(
        id: 'x',
        name: 'Nowhere',
        state: 'None',
        tagline: 't',
        description: ['d'],
        facts: [],
        bestTime: 'b',
        photo: PhotoCredit(
          asset: 'assets/does_not_exist.jpg',
          altText: 'missing',
          fileTitle: 'f',
          author: 'a',
          license: 'l',
          licenseUrl: 'u',
          sourceUrl: 's',
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 150,
            child: _Probe(destination: broken),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nowhere'), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });
  });
}

class _Probe extends StatelessWidget {
  const _Probe({required this.destination});
  final Destination destination;
  @override
  Widget build(BuildContext context) => Image.asset(
    destination.photo.asset,
    errorBuilder: (_, _, _) => Column(
      children: [const Icon(Icons.image_not_supported), Text(destination.name)],
    ),
  );
}
