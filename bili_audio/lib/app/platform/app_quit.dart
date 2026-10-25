import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

import '../../core/logging/app_logger.dart';
import 'window_frame.dart';

/// 保存窗口位置，去掉托盘图标，然后结束桌面端进程。
///
/// 手机端直接返回。托盘还没建好时仍会退出。
Future<void> quitDesktopApp() async {
  if (kIsWeb) return;
  if (!(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) return;
  try {
    await WindowFrameStore.instance?.persist();
  } catch (error, stack) {
    AppLogger.e(
      'save window before quit failed',
      tag: 'update',
      error: error,
      stackTrace: stack,
    );
  }
  try {
    await trayManager.destroy();
  } catch (error, stack) {
    AppLogger.e(
      'tray destroy before quit failed',
      tag: 'update',
      error: error,
      stackTrace: stack,
    );
  }
  exit(0);
}
