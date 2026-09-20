import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let entitlementChannelName = "com.frainzzel.photocut/entitlement"
  private static let freeFinalPdfConsumedKey = "photo_cut.entitlement.free_final_pdf_consumed"
  private static let lifetimeUnlockedKey = "photo_cut.entitlement.lifetime_unlocked"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let entitlementChannel = FlutterMethodChannel(
      name: AppDelegate.entitlementChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    entitlementChannel.setMethodCallHandler { call, result in
      let defaults = UserDefaults.standard

      switch call.method {
      case "read":
        result([
          "freeFinalPdfConsumed": defaults.bool(
            forKey: AppDelegate.freeFinalPdfConsumedKey
          ),
          "lifetimeUnlocked": defaults.bool(
            forKey: AppDelegate.lifetimeUnlockedKey
          ),
        ])

      case "write":
        guard
          let arguments = call.arguments as? [String: Any],
          let freeFinalPdfConsumed = arguments["freeFinalPdfConsumed"] as? Bool,
          let lifetimeUnlocked = arguments["lifetimeUnlocked"] as? Bool
        else {
          result(
            FlutterError(
              code: "invalid_entitlement_state",
              message: "Both entitlement booleans are required.",
              details: nil
            )
          )
          return
        }

        defaults.set(
          freeFinalPdfConsumed,
          forKey: AppDelegate.freeFinalPdfConsumedKey
        )
        defaults.set(
          lifetimeUnlocked,
          forKey: AppDelegate.lifetimeUnlockedKey
        )
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
