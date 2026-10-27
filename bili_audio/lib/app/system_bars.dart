import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android / iOS 才把内容铺到系统栏下面。桌面和网页保持原样。
bool get platformDrawsBehindSystemBars =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// 状态栏和系统导航栏透明，图标跟界面亮度走。
///
/// 深色界面用浅色图标。iOS 的 [SystemUiOverlayStyle.statusBarBrightness]
/// 和 Android 的图标亮度是反的。
SystemUiOverlayStyle immersiveOverlayStyle(Brightness brightness) {
  final lightIcons = brightness == Brightness.dark;
  final icon = lightIcons ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
    statusBarIconBrightness: icon,
    statusBarBrightness: lightIcons ? Brightness.dark : Brightness.light,
    systemNavigationBarIconBrightness: icon,
  );
}

/// Android 10 起由系统进入边到边。更早的版本要靠这里打开，
/// 否则导航栏仍会挡住内容。
Future<void> enableImmersiveSystemBars() async {
  if (!platformDrawsBehindSystemBars) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
