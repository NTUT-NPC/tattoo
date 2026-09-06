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

    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "SystemSettingsChannel"
    ) else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "club.ntut.tattoo/system_settings",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "openLanguageSettings" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let url = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(url) else {
        result(FlutterError(
          code: "settings_unavailable",
          message: "Unable to open language settings.",
          details: nil
        ))
        return
      }

      UIApplication.shared.open(url) { opened in
        if opened {
          result(nil)
        } else {
          result(FlutterError(
            code: "settings_unavailable",
            message: "Unable to open language settings.",
            details: nil
          ))
        }
      }
    }
  }
}
