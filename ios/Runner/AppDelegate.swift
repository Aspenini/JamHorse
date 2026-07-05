import Flutter
import UIKit
import AVKit

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

    let mediaChannel = FlutterMethodChannel(
      name: "com.aspenini.jamhorse/media",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    mediaChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getCapabilities":
        let carPlay = Bundle.main.object(
          forInfoDictionaryKey: "JamHorseCarPlayEnabled"
        ) as? Bool ?? false
        result([
          "airPlay": true,
          "equalizer": false,
          "automotive": carPlay,
          "desktopMediaKeys": false,
        ])
      case "showOutputPicker":
        self.showOutputPicker(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func showOutputPicker(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard
        let scene = UIApplication.shared.connectedScenes
          .compactMap({ $0 as? UIWindowScene })
          .first(where: { $0.activationState == .foregroundActive }),
        let window = scene.windows.first(where: { $0.isKeyWindow }),
        let root = window.rootViewController
      else {
        result(
          FlutterError(
            code: "NO_WINDOW",
            message: "No active window is available.",
            details: nil
          )
        )
        return
      }

      let picker = AVRoutePickerView(frame: CGRect(x: -60, y: -60, width: 44, height: 44))
      root.view.addSubview(picker)
      guard let button = picker.subviews.compactMap({ $0 as? UIButton }).first else {
        picker.removeFromSuperview()
        result(
          FlutterError(
            code: "NO_PICKER",
            message: "The AirPlay route picker is unavailable.",
            details: nil
          )
        )
        return
      }
      button.sendActions(for: .touchUpInside)
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        picker.removeFromSuperview()
      }
      result(nil)
    }
  }
}
