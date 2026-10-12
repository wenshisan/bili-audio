import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

// ============================================================
// 设备平台类型 (上报给后端的 deviceType 字段)
//
// 与后端接口约定 (登录/注册/短信/邮箱验证/忘记密码等所有 auth 接口共用):
//   1 = PC 端    (Windows / macOS / Linux 桌面应用)
//   2 = iOS 端
//   3 = Android 端
//   4 = Web 端   (Flutter Web)
//
// 检测顺序: Web → iOS → Android → PC (兜底)
// 桌面平台 (Windows / macOS / Linux) 一律按 PC=1 上报;
// 其它未知平台 (Fuchsia 等) 也走 PC=1 兜底,避免漏报。
// ============================================================
class DeviceType {
  DeviceType._();

  /// PC 端 (Windows / macOS / Linux 桌面应用)
  static const int pc = 1;

  /// iOS 端
  static const int ios = 2;

  /// Android 端
  static const int android = 3;

  /// Web 端 (Flutter Web)
  static const int web = 4;

  /// 当前运行平台的 deviceType
  ///
  /// 用法:在调用登录/注册/短信/邮箱验证等接口时,作为 deviceType 参数传入。
  /// 静默调用,无副作用,可在 hot-reload 期间安全调用。
  static int get current {
    if (kIsWeb) return web;
    if (Platform.isIOS) return ios;
    if (Platform.isAndroid) return android;
    return pc; // Windows / macOS / Linux / 未知平台 → PC 兜底
  }

  /// deviceType → 中文标签 (用于 UI 展示)
  static String labelOf(int type) {
    switch (type) {
      case pc:
        return 'PC 端';
      case ios:
        return 'iOS 端';
      case android:
        return 'Android 端';
      case web:
        return 'Web 端';
      default:
        return '未知 ($type)';
    }
  }
}
