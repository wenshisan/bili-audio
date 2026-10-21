import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/storage/path_manager.dart';

/// 单实例通道: 当第二个实例启动并检测到已有实例运行时, 原生层会向本实例
/// 发送 "showMainWindow" 调用
const MethodChannel _singleInstanceChannel =
    MethodChannel('bili_audio/single_instance');

Future<void> _initSingleInstanceChannel() async {
  _singleInstanceChannel.setMethodCallHandler((call) async {
    if (call.method == 'showMainWindow') {
      await windowManager.show();
      await windowManager.focus();
    }
  });
}

Future<void> _updateTrayMenu() async {
  final Menu menu = Menu(
    items: [
      MenuItem(
        key: 'show',
        label: '显示主窗口',
        onClick: (menuItem) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuItem(
        key: 'hide',
        label: '隐藏到托盘',
        onClick: (menuItem) async {
          await windowManager.hide();
        },
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit',
        label: '退出',
        onClick: (menuItem) async {
          await trayManager.destroy();
          exit(0);
        },
      ),
    ],
  );
  await trayManager.setContextMenu(menu);
}

class _TrayHandler with TrayListener {
  DateTime _lastClickTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void onTrayIconMouseDown() {
    final now = DateTime.now();
    final diff = now.difference(_lastClickTime).inMilliseconds;
    _lastClickTime = now;
    if (diff < 300) {
      windowManager.show();
      windowManager.focus();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }
}

Future<void> initSystemTray() async {
  try {
    // TODO: 当前沿用 talix 图标, 待替换为本应用图标
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
    );
    await trayManager.setToolTip('哔哩哔哩音频播放器');
    await _updateTrayMenu();
    trayManager.addListener(_TrayHandler());
  } catch (e) {
    debugPrint('System Tray initialization failed: $e');
  }
}

void main() {
  BindingBase.debugZoneErrorsAreFatal = true;
  WidgetsFlutterBinding.ensureInitialized();
  final rootZone = Zone.current;

  runZonedGuarded(() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exceptionAsString()}\n${details.stack}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[PlatformError] $error\n$stack');
      rootZone.run(() => _showBootError(error, stack));
      return true;
    };

    _runApp(rootZone).catchError((Object e, StackTrace st) {
      debugPrint('[FATAL boot] $e\n$st');
      rootZone.run(() => _showBootError(e, st));
    });
  }, (error, stack) {
    debugPrint('[FATAL zone error] $error\n$stack');
    rootZone.run(() => _showBootError(error, stack));
  });
}

void _showBootError(Object error, StackTrace? stack) {
  try {
    runApp(_BootErrorScreen(error: error, stack: stack));
  } catch (_) {
    debugPrint('[FATAL] unable to show error screen: $error');
  }
}

Future<void> _runApp(Zone rootZone) async {
  debugPrint('[boot] main() entered, kIsWeb=$kIsWeb');

  // 注册单实例通道
  await _initSingleInstanceChannel();

  // 初始化路径管理
  await PathManager.init();

  // 桌面端窗口设置
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    debugPrint('[boot] initializing window_manager…');
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(1440, 900),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: '哔哩哔哩音频播放器',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    debugPrint('[boot] window shown');

    // 初始化系统托盘
    await initSystemTray();
    debugPrint('[boot] tray initialized');
  }

  // 数据库 / 网络 / 播放器等全局依赖 (M6)
  final overrides = await bootstrap();
  debugPrint('[boot] dependencies ready');

  rootZone.run(() {
    runApp(
      ProviderScope(
        overrides: overrides,
        child: const BiliAudioApp(),
      ),
    );
  });
  debugPrint('[boot] runApp returned');
}

/// 启动期致命错误显示页
class _BootErrorScreen extends StatelessWidget {
  const _BootErrorScreen({required this.error, this.stack});

  final Object error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 28),
                    SizedBox(width: 12),
                    Text(
                      '启动失败 / Startup Failed',
                      style: TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '错误信息:',
                  style: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  error.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
                if (stack != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '堆栈:',
                    style: TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        stack.toString(),
                        style: const TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
