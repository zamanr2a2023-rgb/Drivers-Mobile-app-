import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Must run before any GoogleMap view is created (e.g. dashboard after OTP login).
    GMSServices.provideAPIKey(resolvedGoogleMapsApiKey())
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// Reads `GMSApiKey` from Info.plist / Secrets.xcconfig.
  private func resolvedGoogleMapsApiKey() -> String {
    let raw = (Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if !raw.isEmpty && !raw.hasPrefix("$(") && raw != "YOUR_IOS_RESTRICTED_KEY" {
      return raw
    }
    return "AIzaSyC7BXis0DYkbNBdzeXQV6VWPPcSj6aL-PM"
  }
}
