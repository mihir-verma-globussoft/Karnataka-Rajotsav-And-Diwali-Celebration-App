import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/theme/app_tokens.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/bundled_rajyotsava_content.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/data/karnataka_districts.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/location.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/domain/nearby.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_feature.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_providers.dart';

import '../../helpers.dart';

const _mysuruPalace = GeoPoint(12.305, 76.655);
const _chennai = GeoPoint(13.08, 80.27);

class _FakeLocation implements LocationService {
  _FakeLocation(this.result);

  final LocationResult result;
  var calls = 0;
  var openedAppSettings = false;
  var openedLocationSettings = false;

  @override
  Future<LocationResult> currentLocation() async {
    calls++;
    return result;
  }

  @override
  Future<void> openAppSettings() async => openedAppSettings = true;

  @override
  Future<void> openLocationSettings() async => openedLocationSettings = true;
}

Future<void> _openNearby(
  WidgetTester tester,
  LocationService location, {
  bool smallScreen = false,
}) async {
  tester.view.physicalSize = smallScreen
      ? AppTestScreens.smallestPhone
      : const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  if (smallScreen) {
    tester.platformDispatcher.textScaleFactorTestValue = AppTextScale.max;
  }
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    testApp(
      overrides: <Override>[
        locationServiceProvider.overrideWithValue(location),
      ],
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first))
      .push<void>(RajyotsavaRoutes.nearby)
      .ignore();
  await tester.pumpAndSettle();
}

String _message(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('nearby-message'))).data!;

void main() {
  group('distance and ranking', () {
    test('Bengaluru to Mysuru is about 125 km in a straight line', () {
      final km = distanceKm(
        const GeoPoint(12.97, 77.59),
        const GeoPoint(12.30, 76.64),
      );
      expect(km, inInclusiveRange(115, 135));
    });

    test('ranks the nearest district first', () {
      final ranked = rankDistricts(karnatakaDistricts, _mysuruPalace);
      expect(ranked.first.district.id, 'mysuru');
      expect(ranked.first.distanceKm, lessThan(5));
      final km = [for (final r in ranked) r.distanceKm!];
      expect(km, orderedEquals([...km]..sort()));
    });

    test('without a location, districts are sorted by name', () {
      final names = [
        for (final r in rankDistricts(karnatakaDistricts, null))
          r.district.name,
      ];
      expect(names, orderedEquals([...names]..sort()));
    });

    test('search matches name, Kannada name, headquarters and fame', () {
      final mysuru = karnatakaDistricts.firstWhere((d) => d.id == 'mysuru');
      expect(matchesDistrict(mysuru, 'mys'), isTrue);
      expect(matchesDistrict(mysuru, 'ಮೈಸೂರು'), isTrue);
      expect(matchesDistrict(mysuru, 'silk'), isTrue);
      expect(matchesDistrict(mysuru, 'Karwar'), isFalse);
      final karwar = karnatakaDistricts.firstWhere(
        (d) => d.id == 'uttara_kannada',
      );
      expect(matchesDistrict(karwar, 'karwar'), isTrue);
    });
  });

  group('district data', () {
    test('all 31 districts, unique ids, inside Karnataka', () {
      expect(karnatakaDistricts, hasLength(31));
      expect(
        karnatakaDistricts.map((d) => d.id).toSet(),
        hasLength(karnatakaDistricts.length),
      );
      for (final d in karnatakaDistricts) {
        expect(d.latitude, inInclusiveRange(11.5, 18.5), reason: d.id);
        expect(d.longitude, inInclusiveRange(74, 78.6), reason: d.id);
        expect(d.famous, isNotEmpty, reason: d.id);
        expect(d.id, matches(RegExp(r'^[a-z_]+$')));
      }
    });

    test('Discover links point to real items', () {
      const content = bundledRajyotsavaContent;
      for (final d in content.districts) {
        for (final id in d.discoverIds) {
          expect(content.discoverItem(id), isNotNull, reason: '${d.id}→$id');
        }
      }
    });
  });

  group('Near me screen', () {
    testWidgets('does not ask for location until the button is tapped', (
      tester,
    ) async {
      final location = _FakeLocation(const LocationFound(_mysuruPalace));
      await _openNearby(tester, location);
      expect(location.calls, 0);
      expect(find.text('All districts'), findsOneWidget);
      expect(find.text('Bagalkote'), findsOneWidget);
    });

    testWidgets('location found: nearest district first', (tester) async {
      final location = _FakeLocation(const LocationFound(_mysuruPalace));
      await _openNearby(tester, location);
      await tester.tap(find.byKey(const ValueKey('use-my-location')));
      await tester.pumpAndSettle();
      expect(location.calls, 1);
      expect(_message(tester), startsWith('You are near Mysuru'));
      expect(find.text('Nearest districts'), findsOneWidget);
      expect(find.textContaining('Nearest ·'), findsOneWidget);

      await tester.tap(find.text('Mysuru'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Mysuru'), findsOneWidget);
      expect(find.text('Famous for'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Mysore Pak'), 200);
      expect(find.text('Mysore Pak'), findsOneWidget);
    });

    testWidgets('every text on the highlighted nearest card is readable', (
      tester,
    ) async {
      // The nearest card is bright yellow; its text once stayed white and
      // yellow and could hardly be read.
      await _openNearby(
        tester,
        _FakeLocation(const LocationFound(_mysuruPalace)),
      );
      await tester.tap(find.byKey(const ValueKey('use-my-location')));
      await tester.pumpAndSettle();
      final card = find.ancestor(
        of: find.textContaining('Nearest ·'),
        matching: find.byType(Card),
      );
      final background = tester.widget<Card>(card).color!;
      // Text widgets only: the badge's icon sits on its own circle.
      final texts = find.descendant(
        of: find.descendant(of: card, matching: find.byType(Text)),
        matching: find.byType(RichText),
      );
      expect(texts, findsWidgets);
      for (final element in texts.evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        final color = paragraph.text.style!.color!;
        // Text drawn with some transparency, blended onto the card.
        final shown = Color.alphaBlend(color, background);
        expect(
          _contrast(shown, background),
          greaterThanOrEqualTo(4.5),
          reason: '"${paragraph.text.toPlainText()}"',
        );
      }
      final chevron = tester.widget<Icon>(
        find.descendant(of: card, matching: find.byIcon(Icons.chevron_right)),
      );
      expect(_contrast(chevron.color!, background), greaterThanOrEqualTo(3));
    });

    testWidgets('outside Karnataka says so', (tester) async {
      await _openNearby(tester, _FakeLocation(const LocationFound(_chennai)));
      await tester.tap(find.byKey(const ValueKey('use-my-location')));
      await tester.pumpAndSettle();
      expect(_message(tester), contains('outside Karnataka'));
    });

    testWidgets('permission denied keeps the manual list', (tester) async {
      await _openNearby(tester, _FakeLocation(const LocationDenied()));
      await tester.tap(find.byKey(const ValueKey('use-my-location')));
      await tester.pumpAndSettle();
      expect(_message(tester), contains('permission was not given'));
      expect(find.text('All districts'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('permanently denied offers the app settings', (tester) async {
      final location = _FakeLocation(const LocationDeniedForever());
      await _openNearby(tester, location);
      await tester.tap(find.byKey(const ValueKey('use-my-location')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open settings'));
      expect(location.openedAppSettings, isTrue);
    });

    testWidgets('location services off offers location settings', (
      tester,
    ) async {
      final location = _FakeLocation(const LocationServicesOff());
      await _openNearby(tester, location);
      await tester.tap(find.byKey(const ValueKey('use-my-location')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Location settings'));
      expect(location.openedLocationSettings, isTrue);
    });

    testWidgets('search filters districts by hand', (tester) async {
      await _openNearby(tester, _FakeLocation(const LocationDenied()));
      await tester.enterText(
        find.byKey(const ValueKey('district-search')),
        'gokarna',
      );
      await tester.pumpAndSettle();
      expect(find.text('Uttara Kannada'), findsOneWidget);
      expect(find.text('Bagalkote'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('district-search')),
        'zzz',
      );
      await tester.pumpAndSettle();
      expect(find.text('No district matches "zzz".'), findsOneWidget);
    });

    testWidgets('unknown district shows not found', (tester) async {
      await _openNearby(tester, _FakeLocation(const LocationDenied()));
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push<void>(RajyotsavaRoutes.district('atlantis'))
          .ignore();
      await tester.pumpAndSettle();
      expect(find.text('We could not find that district.'), findsOneWidget);
    });

    testWidgets('fits a small phone at 2x text, with a result', (tester) async {
      await _openNearby(
        tester,
        _FakeLocation(const LocationFound(_mysuruPalace)),
        smallScreen: true,
      );
      await tester.tap(find.byKey(const ValueKey('use-my-location')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push<void>(RajyotsavaRoutes.district('dakshina_kannada'))
          .ignore();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
