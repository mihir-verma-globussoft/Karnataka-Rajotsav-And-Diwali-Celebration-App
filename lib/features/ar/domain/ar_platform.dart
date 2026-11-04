import 'ar_availability.dart';

/// Flutter-side view of the native AR implementation (ARCore on Android,
/// ARKit on iOS). Presentation depends on this, never on platform channels.
abstract interface class ArPlatform {
  /// Answers without prompting the player for anything.
  Future<ArAvailability> checkAvailability();

  /// Asks for the camera and, on Android, installs Google Play Services for AR
  /// if needed. Call when the player chooses to start, not before.
  Future<ArAvailability> prepare();

  /// Opens this app's page in the system settings, to turn the camera back on.
  Future<void> openSettings();
}
