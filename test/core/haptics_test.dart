import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rajotsav_and_diwali_celebration_app/core/haptics/app_haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each haptic asks the platform for the right feedback', () async {
    final calls = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate')
            calls.add(call.arguments);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    const haptics = SystemHaptics();
    await haptics.tap();
    await haptics.selection();
    await haptics.success();
    await haptics.warning();
    await haptics.error();
    await haptics.heavy();

    expect(calls, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
      null,
      'HapticFeedbackType.heavyImpact',
    ]);
  });

  test('silent haptics do nothing and never throw', () async {
    const haptics = SilentHaptics();
    await haptics.tap();
    await haptics.error();
  });
}
