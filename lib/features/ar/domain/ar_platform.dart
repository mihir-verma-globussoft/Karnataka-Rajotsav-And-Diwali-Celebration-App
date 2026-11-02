import 'ar_availability.dart';

/// Flutter-side view of the native AR implementation (ARCore on Android,
/// ARKit on iOS). Presentation depends on this, never on platform channels.
abstract interface class ArPlatform {
  Future<ArAvailability> checkAvailability();
}
