import 'package:flutter/services.dart';

import '../domain/ar_availability.dart';
import '../domain/ar_platform.dart';

/// Channel name shared with native code; keep in sync with
/// `ArChannel.kt` (Android) and `AppDelegate.swift` (iOS).
const arChannelName = 'festival_app/ar';

class MethodChannelArPlatform implements ArPlatform {
  MethodChannelArPlatform([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(arChannelName);

  final MethodChannel _channel;

  @override
  Future<ArAvailability> checkAvailability() async {
    try {
      return ArAvailability.parse(
        await _channel.invokeMethod<String>('checkAvailability'),
      );
    } on MissingPluginException {
      return ArAvailability.unavailable;
    } on PlatformException {
      return ArAvailability.unavailable;
    }
  }
}
