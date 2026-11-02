import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/config/app_config.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/errors/app_failure.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/responsive/breakpoints.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/widgets/async_value_view.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/widgets/state_views.dart';

Widget host(
  Widget child, {
  Size size = const Size(400, 800),
  double textScale = 1,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: child),
  ),
);

void main() {
  test('AppEnvironment.parse falls back to dev', () {
    expect(AppEnvironment.parse('prod'), AppEnvironment.prod);
    expect(AppEnvironment.parse('nonsense'), AppEnvironment.dev);
  });

  test('WindowSize classifies widths', () {
    expect(WindowSize.fromWidth(360), WindowSize.compact);
    expect(WindowSize.fromWidth(700), WindowSize.medium);
    expect(WindowSize.fromWidth(1000), WindowSize.expanded);
  });

  testWidgets('AsyncValueView renders each state', (tester) async {
    Widget view(AsyncValue<List<int>> v) => host(
      AsyncValueView<List<int>>(
        value: v,
        isEmpty: (d) => d.isEmpty,
        emptyMessage: 'none',
        onRetry: () {},
        data: (d) => Text('count ${d.length}'),
      ),
    );

    await tester.pumpWidget(view(const AsyncLoading()));
    expect(find.byType(LoadingView), findsOneWidget);

    await tester.pumpWidget(view(const AsyncData([1, 2])));
    expect(find.text('count 2'), findsOneWidget);

    await tester.pumpWidget(view(const AsyncData([])));
    expect(find.text('none'), findsOneWidget);

    await tester.pumpWidget(
      view(const AsyncError(NetworkFailure(), StackTrace.empty)),
    );
    expect(find.text(const NetworkFailure().message), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('ErrorView hides non-AppFailure details', (tester) async {
    await tester.pumpWidget(
      host(ErrorView(error: StateError('secret detail'))),
    );
    expect(find.textContaining('secret'), findsNothing);
    expect(find.text(const UnexpectedFailure().message), findsOneWidget);
  });

  for (final size in const [Size(320, 480), Size(480, 320), Size(1200, 800)]) {
    testWidgets('state views do not overflow at $size with 2x text', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          ErrorView(error: const NetworkFailure(), onRetry: () {}),
          size: size,
          textScale: 2,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
