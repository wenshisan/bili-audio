import Cocoa
import FlutterMacOS

/// 程序坞菜单和「点 Dock 图标重新打开窗口」。菜单内容由 Dart 侧推过来。
final class DesktopShellPlugin: NSObject {
  static let shared = DesktopShellPlugin()

  private var channel: FlutterMethodChannel?
  private var items: [[String: Any]] = []

  func attach(messenger: FlutterBinaryMessenger) {
    if channel != nil { return }
    let channel = FlutterMethodChannel(
      name: "bili_audio/desktop_shell",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "setDockMenu" {
        self?.items = Self.readItems(call.arguments)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  func requestShowWindow() {
    channel?.invokeMethod("showWindow", arguments: nil)
  }

  func menu() -> NSMenu {
    let menu = NSMenu()
    menu.autoenablesItems = false
    for (index, item) in items.enumerated() {
      if (item["separator"] as? Bool) == true {
        menu.addItem(.separator())
        continue
      }
      let title = item["label"] as? String ?? ""
      let enabled = (item["enabled"] as? Bool) ?? false
      let entry = NSMenuItem(title: title, action: nil, keyEquivalent: "")
      entry.isEnabled = enabled && item["id"] is String
      if entry.isEnabled {
        entry.action = #selector(onClick(_:))
        entry.target = self
        entry.tag = index
      }
      menu.addItem(entry)
    }
    return menu
  }

  @objc func onClick(_ sender: NSMenuItem) {
    guard items.indices.contains(sender.tag) else { return }
    guard let id = items[sender.tag]["id"] as? String else { return }
    channel?.invokeMethod("onCommand", arguments: id)
  }

  private static func readItems(_ arguments: Any?) -> [[String: Any]] {
    guard let raw = arguments as? [Any] else { return [] }
    return raw.compactMap { entry in
      if let dict = entry as? [String: Any] { return dict }
      guard let dict = entry as? NSDictionary else { return nil }
      var mapped: [String: Any] = [:]
      dict.enumerateKeysAndObjects { key, value, _ in
        if let key = key as? String {
          mapped[key] = value
        }
      }
      return mapped
    }
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag {
      DesktopShellPlugin.shared.requestShowWindow()
    }
    return true
  }

  override func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    DesktopShellPlugin.shared.menu()
  }
}
