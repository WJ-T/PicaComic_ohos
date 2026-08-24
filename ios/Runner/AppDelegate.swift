import UIKit
import Flutter
import UniformTypeIdentifiers
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "com.github.pacalini.pica_comic.channels") else {
        return
    }
    let messenger = registrar.messenger()

    // 用于获取系统代理配置的 MethodChannel
    let methodChannel = FlutterMethodChannel(name: "com.github.pacalini.pica_comic/proxy", binaryMessenger: messenger)
    methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if let proxySettings = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() as NSDictionary?,
           let dict = proxySettings.object(forKey: kCFNetworkProxiesHTTPProxy) as? NSDictionary,
           let host = dict.object(forKey: kCFNetworkProxiesHTTPProxy) as? String,
           let port = dict.object(forKey: kCFNetworkProxiesHTTPPort) as? Int {
            let proxyConfig = "\(host):\(port)"
            result(proxyConfig)
        } else {
            result("")
        }
    }

    // 用于设置屏幕常亮的 MethodChannel
    let channel2 = FlutterMethodChannel(name: "com.github.pacalini.pica_comic/keepScreenOn", binaryMessenger: messenger)
    channel2.setMethodCallHandler { (call: FlutterMethodCall, result: FlutterResult) in
      if call.method == "set" {
        let screenOn = true // 设置屏幕常亮
        UIApplication.shared.isIdleTimerDisabled = screenOn
      } else {
        let screenOn = false // 设置屏幕不常亮
        UIApplication.shared.isIdleTimerDisabled = screenOn
      }
      result(nil)
    }

    // 用于监听音量键的 MethodChannel
    let volumeChannel = FlutterEventChannel(name: "com.github.pacalini.pica_comic/volume", binaryMessenger: messenger)
    volumeChannel.setStreamHandler(VolumeStreamHandler())

    // 用于选择文件夹的 MethodChannel（file_selector 插件在 iOS 上未实现目录选择）
    let directoryChannel = FlutterMethodChannel(name: "venera/method_channel", binaryMessenger: messenger)
    directoryChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "getDirectoryPath":
        DirectoryPickerHandler.shared.pickDirectory(result: result)
      case "stopAccessingSecurityScopedResource":
        DirectoryPickerHandler.shared.stopAccessing()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// 使用 UIDocumentPickerViewController 选择文件夹，并持有安全作用域资源的访问权限。
class DirectoryPickerHandler: NSObject, UIDocumentPickerDelegate {
  static let shared = DirectoryPickerHandler()

  private var result: FlutterResult?
  private var currentURL: URL?

  func pickDirectory(result: @escaping FlutterResult) {
    guard self.result == nil else {
      result(FlutterError(code: "picker_busy", message: "A directory picker is already active.", details: nil))
      return
    }
    guard let presenter = DirectoryPickerHandler.topViewController() else {
      result(FlutterError(code: "no_view_controller", message: "No view controller available.", details: nil))
      return
    }
    self.result = result
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
    } else {
      picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
    }
    picker.delegate = self
    picker.allowsMultipleSelection = false
    presenter.present(picker, animated: true, completion: nil)
  }

  private static func topViewController() -> UIViewController? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    var root = windows.first(where: { $0.isKeyWindow })?.rootViewController
    while let presented = root?.presentedViewController {
      root = presented
    }
    return root
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {
      finish(nil)
      return
    }
    // 切换到新目录前，释放上一个目录的访问权限
    stopAccessing()
    _ = url.startAccessingSecurityScopedResource()
    currentURL = url
    finish(url.path)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish(nil)
  }

  private func finish(_ value: Any?) {
    result?(value)
    result = nil
  }

  func stopAccessing() {
    if let url = currentURL {
      url.stopAccessingSecurityScopedResource()
    }
    currentURL = nil
  }
}

class VolumeStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}