import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/bundled_rajyotsava_content.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_feature.dart';

import '../../helpers.dart';

void main() {
  final photos = bundledRajyotsavaContent.photos;
  // Lists, not a merged map: an id such as "rajkumar" is both a star and a
  // Discover item, each with its own photo.
  final all = [
    ...photos.stars.entries,
    ...photos.discover.entries,
    ...photos.places.entries,
  ];

  test('every photo exists and has a free-licence credit', () {
    expect(all, isNotEmpty);
    for (final MapEntry(key: key, value: asset) in all) {
      expect(File(asset).existsSync(), isTrue, reason: '$key → $asset');
      final credit = photos.credits[asset];
      expect(credit, isNotNull, reason: asset);
      expect(credit!.author, isNotEmpty, reason: asset);
      expect(credit.license, isNotEmpty, reason: asset);
      expect(
        credit.source,
        startsWith('https://commons.wikimedia.org/'),
        reason: asset,
      );
    }
    expect(photos.credits.keys.toSet(), {for (final e in all) e.value});
  });

  test('photos belong to known stars, Discover items and places', () {
    const content = bundledRajyotsavaContent;
    final stars = {for (final s in content.filmStars) s.id};
    final items = {for (final i in content.discover) i.id};
    final places = {
      for (final MapEntry(key: district, value: list) in content.places.entries)
        for (final p in list) '$district|${p.name}',
    };
    expect(stars.containsAll(photos.stars.keys), isTrue);
    expect(items.containsAll(photos.discover.keys), isTrue);
    expect(places.containsAll(photos.places.keys), isTrue);
  });

  Future<void> open(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push<void>(path)
        .ignore();
    await tester.pumpAndSettle();
  }

  testWidgets('stars show their photos', (tester) async {
    await open(tester, RajyotsavaRoutes.cinema);
    expect(find.bySemanticsLabel('Photo of Dr. Rajkumar'), findsOneWidget);
  });

  testWidgets('a Discover item shows its photo and credit', (tester) async {
    await open(tester, RajyotsavaRoutes.discoverItem('hampi'));
    expect(find.bySemanticsLabel('Photo of Hampi'), findsOneWidget);
    expect(find.textContaining('Photo: '), findsOneWidget);
  });

  testWidgets('photo credits screen lists every photo', (tester) async {
    await open(tester, RajyotsavaRoutes.discover);
    await tester.tap(find.byTooltip('Photo credits'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Photo credits'), findsOneWidget);
    expect(find.textContaining('Wikimedia Commons'), findsWidgets);
  });
}
