import ARKit
import AVFoundation
import Flutter
import UIKit

/// Flutter <-> native AR contract (Dart side: lib/features/ar/data).
/// Channel: festival_app/ar. Answers are the names in ArAvailability.
final class ArChannel {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "festival_app/ar", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "checkAvailability":
        result(ArChannel.availability())
      case "prepare":
        ArChannel.prepare(result)
      case "openSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func availability() -> String {
    guard ARWorldTrackingConfiguration.isSupported else { return "unsupportedDevice" }
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .denied, .restricted:
      return "cameraPermissionDenied"
    default:
      return "supported"
    }
  }

  /// Asks for the camera at the moment the player chooses to start.
  private static func prepare(_ result: @escaping FlutterResult) {
    guard ARWorldTrackingConfiguration.isSupported else {
      result("unsupportedDevice")
      return
    }
    AVCaptureDevice.requestAccess(for: .video) { granted in
      DispatchQueue.main.async {
        result(granted ? "supported" : "cameraPermissionDenied")
      }
    }
  }
}
