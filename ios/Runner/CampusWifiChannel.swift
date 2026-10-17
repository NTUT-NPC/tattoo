import Flutter
import NetworkExtension
import UIKit

final class CampusWifiChannel: NSObject, FlutterPlugin {
  private var isApplyingConfiguration = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "club.ntut.tattoo/campus_wifi",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(CampusWifiChannel(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if Thread.isMainThread {
      handleOnMainThread(call, result: result)
    } else {
      DispatchQueue.main.async {
        self.handleOnMainThread(call, result: result)
      }
    }
  }

  private func handleOnMainThread(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCapabilities":
      #if targetEnvironment(simulator)
      let canProvisionDirectly = false
      #else
      let canProvisionDirectly = true
      #endif
      result([
        "isSupported": true,
        "canProvisionNtut8021xDirect": canProvisionDirectly,
        "canProvisionNtut8021xSuggestion": false,
        "canProvisionNtut8021xCompat": false,
        "canOpenWifiSettings": false,
        "canOpenWifiPanel": false,
        "suggestionPermissionState": "unknown",
      ])
    case "provisionNtut8021x", "saveNtut8021xToSystem":
      applyConfiguration(arguments: call.arguments, result: result)
    case "openWifiSettings", "openWifiPanel":
      // iOS has no public URL that opens the system Wi-Fi settings or panel.
      result(false)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func applyConfiguration(arguments: Any?, result: @escaping FlutterResult) {
    #if targetEnvironment(simulator)
    result(["status": "unsupportedPlatform"])
    #else
    guard let arguments = arguments as? [String: Any],
          let identity = arguments["identity"] as? String,
          let password = arguments["password"] as? String,
          !identity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          (1...253).contains((identity as NSString).length),
          (1...64).contains((password as NSString).length) else {
      result(FlutterError(
        code: "invalid_args",
        message: "A valid identity and password are required for the Wi-Fi configuration.",
        details: nil
      ))
      return
    }

    guard !isApplyingConfiguration else {
      result(FlutterError(
        code: "busy",
        message: "A Wi-Fi configuration request is already in progress.",
        details: nil
      ))
      return
    }

    let eapSettings = NEHotspotEAPSettings()
    eapSettings.supportedEAPTypes = [NSNumber(value: NEHotspotEAPSettings.EAPType.EAPPEAP.rawValue)]
    eapSettings.username = identity
    eapSettings.password = password
    eapSettings.isTLSClientCertificateRequired = false
    // PEAP negotiates its inner EAP method (including GTC) with the server.
    // The public API's inner-authentication selector applies only to TTLS.
    // Leave custom trust anchors unset to use system trust, constrained to NTUT names.
    eapSettings.trustedServerNames = ["ntut.edu.tw", "*.ntut.edu.tw"]

    let configuration = NEHotspotConfiguration(ssid: "NTUT-802.1X", eapSettings: eapSettings)
    // Enterprise configurations must be persistent; iOS manages subsequent auto-join.
    configuration.joinOnce = false
    isApplyingConfiguration = true
    // apply prompts for system consent and updates in place without removing saved credentials.
    NEHotspotConfigurationManager.shared.apply(configuration) { error in
      DispatchQueue.main.async {
        self.isApplyingConfiguration = false
        let status: String
        if let error = error as NSError? {
          if error.domain == NEHotspotConfigurationErrorDomain {
            switch error.code {
            case NEHotspotConfigurationError.userDenied.rawValue:
              status = "cancelled"
            case NEHotspotConfigurationError.alreadyAssociated.rawValue:
              // Association alone does not establish that new credentials were stored.
              status = "alreadyAssociated"
            default:
              status = "failed"
            }
          } else {
            status = "failed"
          }
        } else {
          // Successfully stored is not proof of association or network connectivity.
          status = "configured"
        }
        // Never forward localized errors: they can contain configuration or credential data.
        result(["status": status])
      }
    }
    #endif
  }
}
