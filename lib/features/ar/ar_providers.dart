import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/method_channel_ar_platform.dart';
import 'domain/ar_availability.dart';
import 'domain/ar_platform.dart';

/// Override in tests with a fake [ArPlatform].
final arPlatformProvider = Provider<ArPlatform>(
  (ref) => MethodChannelArPlatform(),
);

final arAvailabilityProvider = FutureProvider.autoDispose<ArAvailability>(
  (ref) => ref.watch(arPlatformProvider).checkAvailability(),
);
