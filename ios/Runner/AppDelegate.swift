import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerArChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  /// Flutter <-> native AR contract (Dart side: lib/features/ar/data).
  /// ARKit is not integrated yet, so availability is "unavailable".
  /// The AR developer should move this into Runner/Ar/ArChannel.swift
  /// (added to the Xcode target) when implementing ARKit.
  private func registerArChannel(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "festival_app/ar", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "checkAvailability": result("unavailable")
        default: result(FlutterMethodNotImplemented)
        }
      }
  }
}
