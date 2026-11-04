import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/app/feature_registry.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_availability.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_platform.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/deepavali/deepavali_routes.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/rajyotsava/rajyotsava_routes.dart';

import '../helpers.dart';

class _FakeAr implements ArPlatform {
  @override
  Future<ArAvailability> checkAvailability() async =>
      ArAvailability.unavailable;

  @override
  Future<ArAvailability> prepare() async => ArAvailability.unavailable;

  @override
  Future<void> openSettings() async {}
}

/// On a phone with Android's back/home buttons (or the gesture bar), nothing
/// tappable may end up underneath them, nor under the app's floating bar, once
/// a screen is scrolled to the end.
void main() {
  reduceMotionForAllTests();

  /// Height of a classic 3-button navigation bar.
  const navBar = 48.0;
  const phone = Size(360, 640);

  final tabs = [
    for (final m in featureModules)
      if (m.tab != null) m.tab!.label,
  ];
  final paths = [
    for (final m in featureModules)
      for (final r in m.routes.whereType<GoRoute>())
        if (r.path != '/' && !r.path.contains(':')) r.path,
    // Screens that take an id.
    DeepavaliRoutes.destinationPath('varanasi'),
    RajyotsavaRoutes.district('bagalkote'),
  ];

  void androidPhone(WidgetTester tester, {double textScale = 1}) {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: navBar);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: navBar);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(overrides: [arPlatformProvider.overrideWithValue(_FakeAr())]),
    );
    await tester.pumpAndSettle();
  }

  /// Scrolls every vertical scroll view to its end.
  Future<void> scrollToEnd(WidgetTester tester) async {
    for (var pass = 0; pass < 3; pass++) {
      for (final e in find.byType(Scrollable).evaluate()) {
        final position = (e as StatefulElement).state is ScrollableState
            ? ((e).state as ScrollableState).position
            : Scrollable.of(e).position;
        if (position.axis == Axis.vertical && position.hasContentDimensions) {
          position.jumpTo(position.maxScrollExtent);
        }
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  /// Buttons, cards, text and images that are on screen right now.
  List<String> buttonsBelow(WidgetTester tester, double limit) {
    final found = <String>[];
    final tappable = find.byWidgetPredicate(
      (w) =>
          w is ButtonStyleButton ||
          w is IconButton ||
          w is FloatingActionButton ||
          w is InkWell ||
          w is Text ||
          w is Image,
    );
    for (final e in tappable.evaluate()) {
      final box = e.renderObject;
      if (box is! RenderBox || !box.hasSize || !box.attached) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final onScreen = rect.top < phone.height && rect.bottom > 0;
      if (onScreen && rect.bottom > limit + 0.5) {
        found.add(
          '${e.widget.runtimeType} at ${rect.top.round()}-'
          '${rect.bottom.round()} (limit ${limit.round()})',
        );
      }
    }
    return found;
  }

  for (final scale in [1.0, 2.0]) {
    for (final tab in tabs) {
      testWidgets('tab "$tab": end of content clears the Android buttons '
          'and the bar, text x$scale', (tester) async {
        androidPhone(tester, textScale: scale);
        await pumpApp(tester);
        await tester.tap(find.byKey(ValueKey('tab-$tab')));
        await tester.pumpAndSettle();
        await scrollToEnd(tester);

        // The floating bar sits above the Android buttons...
        final tabButtons = [
          for (final t in tabs) find.byKey(ValueKey('tab-$t')),
        ];
        final barTop = tabButtons
            .map((f) => tester.getTopLeft(f).dy)
            .reduce((a, b) => a < b ? a : b);
        for (final f in tabButtons) {
          expect(
            tester.getBottomLeft(f).dy,
            lessThanOrEqualTo(phone.height - navBar),
            reason: 'the floating bar is under the Android buttons',
          );
        }

        // ...and the last content button ends above the bar.
        final tabRenderObjects = {
          for (final f in tabButtons) tester.element(f).renderObject,
        };
        final offenders = <String>[];
        final tappable = find.byWidgetPredicate(
          (w) =>
              w is ButtonStyleButton ||
              w is IconButton ||
              w is InkWell ||
              w is FloatingActionButton ||
              w is Text ||
              w is Image,
        );
        for (final e in tappable.evaluate()) {
          final box = e.renderObject;
          if (box is! RenderBox || !box.hasSize) continue;
          var inBar = false;
          e.visitAncestorElements((a) {
            if (tabRenderObjects.contains(a.renderObject)) inBar = true;
            return !inBar;
          });
          if (inBar) continue;
          final rect = box.localToGlobal(Offset.zero) & box.size;
          // Tab buttons contain their own InkWell-less GestureDetector; the
          // bar background itself is not a button.
          if (rect.top >= barTop - 1 && rect.bottom <= phone.height) continue;
          if (rect.top < phone.height && rect.bottom > barTop + 0.5) {
            offenders.add(
              '${e.widget.runtimeType} ${rect.top.round()}-'
              '${rect.bottom.round()} vs bar top ${barTop.round()}',
            );
          }
        }
        expect(offenders, isEmpty, reason: offenders.join('\n'));
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in [1.0, 2.0]) {
    for (final path in paths) {
      testWidgets('screen $path: end of content clears the Android buttons, '
          'text x$scale', (tester) async {
        androidPhone(tester, textScale: scale);
        await pumpApp(tester);
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .push<void>(path)
            .ignore();
        await tester.pumpAndSettle();
        await scrollToEnd(tester);
        final offenders = buttonsBelow(tester, phone.height - navBar);
        expect(offenders, isEmpty, reason: offenders.join('\n'));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
