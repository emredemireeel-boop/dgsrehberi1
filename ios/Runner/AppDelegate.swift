import Flutter
import UIKit
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // DGS uses contextual iOS ads, without cross-app tracking or an ATT request.
    // Apply this before registering any plugin that can initialize the ads SDK.
    MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
