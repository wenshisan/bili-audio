import 'package:flutter/material.dart';

/// 全局 Navigator 句柄, 用于脱离 widget 树时 (如 forceLogout 后) 强制跳到登录页。
///
/// 背景: Consumer<AuthViewModel> / 显式 addListener 两种方案在 Windows 桌面端
/// + _DesktopWindowShell 包裹下都曾出现过 notifyListeners 触发不到 rebuild
/// 的情况 (用户改密后卡在原页面)。所以这里用 navigatorKey 做兜底:
/// 任何业务只要持有这个 key, 就能 pushAndRemoveUntil 强制切到 LoginScreen。
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');
