/// Result of asking the native layer whether AR can run on this device.
/// Names are the wire values returned by the `checkAvailability` channel call.
enum ArAvailability {
  supported,

  /// Hardware/OS cannot run AR (ARCore/ARKit unsupported).
  unsupportedDevice,

  /// Android only: Google Play Services for AR missing or needs an update.
  servicesNeedInstall,

  cameraPermissionDenied,

  /// Native side missing, not implemented, or failed.
  unavailable;

  static ArAvailability parse(Object? wire) => ArAvailability.values.firstWhere(
    (e) => e.name == wire,
    orElse: () => ArAvailability.unavailable,
  );
}
