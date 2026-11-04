import 'package:flutter/services.dart';

import '../domain/ar_availability.dart';
import '../domain/ar_platform.dart';

/// Channel name shared with native code; keep in sync with
/// `ArChannel.kt` (Android) and `ArChannel.swift` (iOS).
const arChannelName = 'festival_app/ar';

class MethodChannelArPlatform implements ArPlatform {
  MethodChannelArPlatform([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(arChannelName);

  final MethodChannel _channel;

  @override
  Future<ArAvailability> checkAvailability() => _ask('checkAvailability');

  @override
  Future<ArAvailability> prepare() => _ask('prepare');

  @override
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      // Nothing to open; the permission screen still explains what to do.
    } on PlatformException {
      // As above.
    }
  }

  Future<ArAvailability> _ask(String method) async {
    try {
      return ArAvailability.parse(await _channel.invokeMethod<String>(method));
    } on MissingPluginException {
      return ArAvailability.unavailable;
    } on PlatformException {
      return ArAvailability.unavailable;
    }
  }
}
