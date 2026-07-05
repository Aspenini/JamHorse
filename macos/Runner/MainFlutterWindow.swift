import Cocoa
import FlutterMacOS
import AVKit

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let mediaChannel = FlutterMethodChannel(
      name: "com.aspenini.jamhorse/media",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    mediaChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getCapabilities":
        result([
          "airPlay": true,
          "equalizer": false,
          "automotive": false,
          "desktopMediaKeys": true,
        ])
      case "showOutputPicker":
        self?.showOutputPicker(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  private func showOutputPicker(result: @escaping FlutterResult) {
    guard let contentView else {
      result(
        FlutterError(
          code: "NO_WINDOW",
          message: "No active window is available.",
          details: nil
        )
      )
      return
    }
    let picker = AVRoutePickerView(frame: NSRect(x: -60, y: -60, width: 44, height: 44))
    contentView.addSubview(picker)
    if let button = picker.subviews.compactMap({ $0 as? NSButton }).first {
      button.performClick(nil)
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        picker.removeFromSuperview()
      }
      result(nil)
    } else {
      picker.removeFromSuperview()
      result(
        FlutterError(
          code: "NO_PICKER",
          message: "The AirPlay route picker is unavailable.",
          details: nil
        )
      )
    }
  }
}
