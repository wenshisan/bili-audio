import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/logging/app_logger.dart';
import '../../data/db/daos/settings_dao.dart';

/// 全屏时桌面壳去掉圆角。
final desktopWindowRounded = ValueNotifier<bool>(true);

/// 判断保存的窗口矩形能否用。屏幕列表为空时只校验尺寸。
class WindowFrame {
  static Rect? restore({
    required double? x,
    required double? y,
    required double? w,
    required double? h,
    required List<Rect> screens,
  }) {
    if (x == null || y == null || w == null || h == null) return null;
    if (w < 360 || h < 640 || w > 8000 || h > 8000) return null;
    final frame = Rect.fromLTWH(x, y, w, h);
    if (screens.isEmpty) return frame;
    for (final screen in screens) {
      final hit = frame.intersect(screen);
      if (!hit.isEmpty && hit.width >= 80 && hit.height >= 80) return frame;
    }
    return null;
  }
}

class WindowFrameStore with WindowListener {
  WindowFrameStore._(this.dao);

  static WindowFrameStore? instance;

  final SettingsDao dao;
  Timer? _timer;

  static void attach(SettingsDao dao) {
    if (instance != null) return;
    final store = WindowFrameStore._(dao);
    instance = store;
    windowManager.addListener(store);
  }

  Future<void> persist() async {
    try {
      final bounds = await windowManager.getBounds();
      await dao.setBatch({
        'window.x': bounds.left.toString(),
        'window.y': bounds.top.toString(),
        'window.w': bounds.width.toString(),
        'window.h': bounds.height.toString(),
      });
    } catch (e, st) {
      AppLogger.e('save window frame failed', tag: 'window', error: e, stackTrace: st);
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), persist);
  }

  @override
  void onWindowResize() => _schedule();

  @override
  void onWindowMove() => _schedule();

  @override
  void onWindowEnterFullScreen() => desktopWindowRounded.value = false;

  @override
  void onWindowLeaveFullScreen() => desktopWindowRounded.value = true;
}

Future<void> restoreWindowFrame(SettingsDao dao) async {
  try {
    final frame = WindowFrame.restore(
      x: double.tryParse(await dao.get('window.x') ?? ''),
      y: double.tryParse(await dao.get('window.y') ?? ''),
      w: double.tryParse(await dao.get('window.w') ?? ''),
      h: double.tryParse(await dao.get('window.h') ?? ''),
      screens: [
        for (final display in WidgetsBinding.instance.platformDispatcher.displays)
          Rect.fromLTWH(
            0,
            0,
            display.size.width / display.devicePixelRatio,
            display.size.height / display.devicePixelRatio,
          ),
      ],
    );
    if (frame != null) await windowManager.setBounds(frame);
  } catch (e, st) {
    AppLogger.e('restore window frame failed', tag: 'window', error: e, stackTrace: st);
  }
}
