import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/karnataka_districts.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/external_links.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_providers.dart';

import '../../helpers.dart';

/// Records what would be opened.
class FakeLinks implements ExternalLinks {
  FakeLinks({this.succeeds = true});

  final bool succeeds;
  final List<String> directions = [];
  final List<String> searches = [];

  @override
  Future<bool> openDirections(String destination) async {
    directions.add(destination);
    return succeeds;
  }

  @override
  Future<bool> openYouTubeSearch(String query) async {
    searches.add(query);
    return succeeds;
  }
}

Future<void> _open(WidgetTester tester, FakeLinks links, String path) async {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    testApp(overrides: [externalLinksProvider.overrideWithValue(links)]),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first))
      .push<void>(path)
      .ignore();
  await tester.pumpAndSettle();
}

void main() {
  group('map links', () {
    test('Apple Maps routes from the current location', () {
      final uri = MapLinks.appleMaps('Hampi, Karnataka');
      expect(uri.host, 'maps.apple.com');
      expect(uri.queryParameters, {'daddr': 'Hampi, Karnataka', 'dirflg': 'd'});
      expect(uri.toString(), contains('Hampi%2C+Karnataka'));
    });

    test('Google Maps uses the directions API link', () {
      final uri = MapLinks.googleMaps("St Mary's Island, Udupi, Karnataka");
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(
        uri.queryParameters['destination'],
        "St Mary's Island, Udupi, Karnataka",
      );
    });

    test('YouTube search link', () {
      final uri = MapLinks.youTubeSearch('Dollu Kunitha');
      expect(uri.host, 'www.youtube.com');
      expect(uri.queryParameters['search_query'], 'Dollu Kunitha');
    });

    test('every district has places to visit, with a Karnataka address', () {
      for (final d in karnatakaDistricts) {
        expect(d.visit, isNotEmpty, reason: d.id);
        for (final place in d.visit) {
          expect(d.mapQuery(place), endsWith('${d.name}, Karnataka'));
        }
      }
    });
  });

  testWidgets('district page opens directions to a place', (tester) async {
    final links = FakeLinks();
    await _open(tester, links, RajyotsavaRoutes.district('vijayanagara'));
    expect(find.text('Places to visit'), findsOneWidget);
    await tester.tap(find.byTooltip('Directions to Hampi'));
    await tester.pump();
    expect(links.directions, ['Hampi, Vijayanagara, Karnataka']);
  });

  testWidgets('Discover place has Get directions', (tester) async {
    final links = FakeLinks();
    await _open(tester, links, RajyotsavaRoutes.discoverItem('jog_falls'));
    await tester.tap(find.text('Get directions'));
    await tester.pump();
    expect(links.directions, ['Jog Falls, Shivamogga, Karnataka']);
  });

  testWidgets('food items have no directions button', (tester) async {
    await _open(
      tester,
      FakeLinks(),
      RajyotsavaRoutes.discoverItem('mysore_pak'),
    );
    expect(find.text('Get directions'), findsNothing);
  });

  testWidgets('says so when no maps app can open', (tester) async {
    await _open(
      tester,
      FakeLinks(succeeds: false),
      RajyotsavaRoutes.district('mysuru'),
    );
    await tester.tap(find.byTooltip('Directions to Mysuru Palace'));
    await tester.pump();
    expect(find.text('Could not open a maps app.'), findsOneWidget);
  });
}
