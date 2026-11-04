import 'dart:async';

import 'package:ar_hunt/core/theme/app_tokens.dart';
import 'package:ar_hunt/features/ar/data/method_channel_ar_platform.dart';
import 'package:ar_hunt/features/ar/domain/ar_availability.dart';
import 'package:ar_hunt/features/ar/domain/ar_scene.dart';
import 'package:ar_hunt/features/ar/domain/hunt_models.dart';
import 'package:ar_hunt/features/ar/presentation/widgets/ar_camera_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The real Kotlin and Swift code, nothing faked. On a phone that supports AR
/// this starts a real AR session, so allow the camera if asked:
///
///     flutter test integration_test/native_ar_test.dart -d <device>
///
/// A simulator or emulator without AR only checks the graceful fallback.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native code answers, and never with a missing-code error', (
    tester,
  ) async {
    final availability = await MethodChannelArPlatform().checkAvailability();
    debugPrint('AR availability on this device: ${availability.name}');
    // `unavailable` is what a missing or crashed native side turns into.
    expect(availability, isNot(ArAvailability.unavailable));
  });

  testWidgets('a real AR session starts, reports, draws and stops', (
    tester,
  ) async {
    final platform = MethodChannelArPlatform();
    final availability = await platform.prepare();
    if (availability != ArAvailability.supported) {
      debugPrint('Skipping the AR session: ${availability.name}');
      return;
    }

    ArSceneController? scene;
    final tracking = Completer<ArTracking>();
    final errors = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.ink,
            body: ArCameraView(
              placing: true,
              onScene: (created) {
                scene = created;
                created.events.listen((event) {
                  if (event is ArTrackingChanged && !tracking.isCompleted) {
                    tracking.complete(event.tracking);
                  }
                  if (event is ArFailed) errors.add(event.code);
                });
              },
            ),
          ),
        ),
      ),
    );

    // The view is created by the platform, and takes real time to report.
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (!tracking.isCompleted && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(errors, isEmpty, reason: 'the session must start cleanly');
    expect(scene, isNotNull, reason: 'the native view must be created');
    expect(tracking.isCompleted, isTrue, reason: 'AR must report its state');

    // Every call into native code, with the real models, must not crash it.
    final controller = scene!;
    await controller.setOrigin(
      const ArOrigin(position: Vec3(0, 0, -1), yaw: 0.5),
    );
    await controller.setItems(const [
      ArSceneItem(id: 'd', kind: HuntItemKind.diya, x: 0, y: 0, z: 0.5),
      ArSceneItem(id: 'f', kind: HuntItemKind.flag, x: 0.5, y: 0, z: 0.5),
    ]);
    await tester.pump(const Duration(seconds: 2));
    await controller.tap(100, 200);
    await tester.pump(const Duration(milliseconds: 500));
    await controller.celebrate('d');
    await tester.pump(const Duration(seconds: 1));
    await controller.setItems(const []);
    await controller.setOrigin(null);
    await tester.pump(const Duration(milliseconds: 500));
    expect(errors, isEmpty);

    await controller.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
