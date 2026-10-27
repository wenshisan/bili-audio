import Flutter
import UIKit
import WebKit

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
    let channel = FlutterMethodChannel(
      name: "bili_audio/install",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "openUrl",
            let urlString = call.arguments as? String,
            let url = URL(string: urlString)
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in
        if opened {
          result(nil)
        } else {
          result(FlutterError(code: "launch", message: "无法打开安装地址", details: nil))
        }
      }
    }
    let cookies = FlutterMethodChannel(
      name: "bili_audio/login_cookies",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    cookies.setMethodCallHandler { call, result in
      let store = WKWebsiteDataStore.default().httpCookieStore
      switch call.method {
      case "read":
        store.getAllCookies { list in
          let pairs = list.compactMap { cookie -> String? in
            guard Self.bilibiliCookie(cookie.domain) else { return nil }
            return "\(cookie.name)=\(cookie.value)"
          }
          result(pairs.joined(separator: "; "))
        }
      case "clear":
        store.getAllCookies { list in
          if list.isEmpty {
            result(nil)
            return
          }
          let group = DispatchGroup()
          for cookie in list {
            group.enter()
            store.delete(cookie) { group.leave() }
          }
          group.notify(queue: .main) { result(nil) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// 只取哔哩哔哩域名上的 Cookie，HttpOnly 的 SESSDATA 也能读到。
  private static func bilibiliCookie(_ domain: String) -> Bool {
    var host = domain.lowercased()
    if host.hasPrefix(".") {
      host = String(host.dropFirst())
    }
    return host == "bilibili.com" || host.hasSuffix(".bilibili.com")
      || host == "bilibili.cn" || host.hasSuffix(".bilibili.cn")
  }
}
