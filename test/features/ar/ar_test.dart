import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/widgets/permission_denied_view.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/ar_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/data/method_channel_ar_platform.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_availability.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/ar/domain/ar_platform.dart';

import '../../helpers.dart';

class _Fake implements ArPlatform {
  _Fake(this.value);
  final ArAvailability value;
  @override
  Future<ArAvailability> checkAvailability() async => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel(arChannelName);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('parses native values; unknown becomes unavailable', () {
    expect(ArAvailability.parse('supported'), ArAvailability.supported);
    expect(ArAvailability.parse('weird'), ArAvailability.unavailable);
    expect(ArAvailability.parse(null), ArAvailability.unavailable);
  });

  test('channel returns the native answer', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => 'unsupportedDevice',
    );
    expect(
      await MethodChannelArPlatform().checkAvailability(),
      ArAvailability.unsupportedDevice,
    );
  });

  test('missing native implementation degrades to unavailable', () async {
    expect(
      await MethodChannelArPlatform().checkAvailability(),
      ArAvailability.unavailable,
    );
  });

  test('native failure degrades to unavailable', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'boom'),
    );
    expect(
      await MethodChannelArPlatform().checkAvailability(),
      ArAvailability.unavailable,
    );
  });

  testWidgets('page shows permission-denied state', (tester) async {
    await tester.pumpWidget(
      testApp(
        overrides: [
          arPlatformProvider.overrideWithValue(
            _Fake(ArAvailability.cameraPermissionDenied),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push<void>('/ar')
        .ignore();
    await tester.pumpAndSettle();
    expect(find.byType(PermissionDeniedView), findsOneWidget);
  });
}
