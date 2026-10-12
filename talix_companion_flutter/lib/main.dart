import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'desktop/float_window_controller.dart'
    show
        isFloatWindowOpen,
        showMainWindow,
        hideMainWindow,
        closeFloatWindow,
        toggleFloatWindow;
import 'main_frame.dart' show MainFrame;
import 'screens/login_screen.dart';
import 'services/api/api_client.dart';
import 'services/server_config_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';
import 'utils/app_logger.dart';
import 'utils/root_navigator.dart';
import 'utils/session_expiry.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/device_model.dart';
import 'widgets/window_title_bar.dart';

/// 单实例通道: 当第二个实例启动并检测到已有实例运行时, 原生层会向本实例
/// 发送 "showMainWindow" 调用, 这里统一走 [showMainWindow] 以显示主面板并
/// 关闭悬浮窗, 与托盘菜单的"显示主面板"行为保持一致。
const MethodChannel _singleInstanceChannel =
    MethodChannel('talix/single_instance');

Future<void> _initSingleInstanceChannel() async {
  _singleInstanceChannel.setMethodCallHandler((call) async {
    if (call.method == 'showMainWindow') {
      await showMainWindow();
    }
  });
}

Future<void> _updateTrayMenu() async {
  final Menu menu = Menu(
    items: [
      MenuItem(
        key: 'show',
        label: '显示主面板 (Show)',
        onClick: (menuItem) async {
          await showMainWindow();
        },
      ),
      MenuItem(
        key: 'hide',
        label: '隐藏至后台 (Hide)',
        // Fire-and-forget: hideMainWindow() 内部 hide + 后台启动悬浮窗进程,
        // 不阻塞菜单点击回调。
        onClick: (menuItem) {
          hideMainWindow();
        },
      ),
      // MenuItem.separator(),
      // MenuItem(
      //   key: 'float',
      //   label: isFloatWindowOpen ? '关闭悬浮窗 (Close Float)' : '开启悬浮窗 (Open Float)',
      //   onClick: (menuItem) async {
      //     await toggleFloatWindow();
      //     await _updateTrayMenu();
      //   },
      // ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit',
        label: '退出程序 (Exit)',
        onClick: (menuItem) async {
          await closeFloatWindow();
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
      showMainWindow();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }
}

Future<void> initSystemTray() async {
  try {
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
    );
    await trayManager.setToolTip('Talix AI Note Companion');
    await _updateTrayMenu();
    trayManager.addListener(_TrayHandler());
  } catch (e) {
    AppLogger.w('System Tray initialization failed: $e', 'tray');
  }
}

void main() {
  // **重要**:
  // 1) BindingBase.debugZoneErrorsAreFatal = true 必须在 ensureInitialized
  //    之前设置,这样 zone 不匹配会立即 crash 而不是只打个 warning
  //    (避免"warning 一直打,但实际渲染坏掉"的情况)
  // 2) WidgetsFlutterBinding.ensureInitialized() 必须在 root zone 调用,
  //    不能放在 runZonedGuarded 内部 — 因为:
  //      - runZonedGuarded 的 onError 回调运行在父 zone(根 zone)
  //      - PlatformDispatcher.instance.onError 也运行在根 zone
  //    标准 Flutter 范式:binding 在根 zone 初始化,业务代码用 zone 隔离
  // 3) **同时**所有调 _showBootError -> runApp 的地方都必须在 root zone:
  //      - _runApp().catchError 回调运行在 _runApp 所在的 zone(自定义 zone)
  //      - 如果在自定义 zone 调 runApp,会触发 zone mismatch(binding 在根 zone)
  //    修复:在根 zone 捕获 Zone.current 引用,所有 _showBootError 调都用
  //    `rootZone.run(...)` 桥接回根 zone。
  BindingBase.debugZoneErrorsAreFatal = true;
  WidgetsFlutterBinding.ensureInitialized();
  final rootZone = Zone.current;

  // 把整个 main 放到 runZonedGuarded 里,确保任何未捕获的异步异常都不会
  // 让进程以"空白窗口"的形式死掉 — 会在屏幕上显示错误。
  runZonedGuarded(() {
    // Flutter 框架层错误(构建期、布局期)也走这里,确保不静默吞掉
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exceptionAsString()}\n${details.stack}');
    };
    // 平台层未捕获错误(Dart isolate / 异步)
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[PlatformError] $error\n$stack');
      // 也在屏幕显示 — 必须在 root zone 调,否则 runApp 会 zone mismatch
      rootZone.run(() => _showBootError(error, stack));
      return true;
    };

    _runApp(rootZone).catchError((e, st) {
      debugPrint('[FATAL boot] $e\n$st');
      // 必须在 root zone 调 (catchError 回调运行在自定义 zone)
      rootZone.run(() => _showBootError(e, st));
    });
  }, (error, stack) {
    debugPrint('[FATAL zone error] $error\n$stack');
    // onError 回调本就运行在父 zone (root zone),但为了清晰也走 rootZone.run
    rootZone.run(() => _showBootError(error, stack));
  });
}

/// 把启动期致命错误显示在屏幕上(因为 .exe 双击运行时看不到控制台输出)
void _showBootError(Object error, StackTrace? stack) {
  try {
    runApp(_BootErrorScreen(error: error, stack: stack));
  } catch (_) {
    // 实在不行就 debugPrint
    debugPrint('[FATAL] unable to show error screen: $error');
  }
}

Future<void> _runApp(Zone rootZone) async {
  // 启动早期探针:一旦没看到这一行,说明进程卡在更早的初始化(几乎不可能)
  debugPrint('[boot] main() entered, kIsWeb=$kIsWeb');

  // 注册单实例通道: 接收第二个实例发来的"显示主面板"请求 (仅在本实例为
  // 已运行实例时才会收到, 此时 window_manager 早已就绪)。
  await _initSingleInstanceChannel();

  // 初始化全局日志(创建日志目录、启动过期清理定时器)。
  // **非阻塞**:init 内部已全 try/catch,但仍用 unawaited 包一层防止任何
  // 意外情况阻塞 main() 走到 runApp — 即便日志完全坏掉,UI 也要能起来。
  unawaited(AppLogger.init());

  // 针对 Windows & macOS 桌面端，窗口尺寸与样式严格对齐 Figma 设计 (node-id 1218-2072)
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
    debugPrint('[boot] initializing window_manager…');
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1440, 900), // 与设计图主画板尺寸 1:1
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent, // 透明背景,用于实现 8px 圆角 + 阴影
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // 隐藏系统原生标题栏,使用自定义标题栏
      title: 'Talix AI Note Companion',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // 启动时主窗口可见 → 关闭 (任何状态) 悬浮窗,保持初始一致
      await windowManager.show();
      await windowManager.focus();
      await closeFloatWindow();
    });
    debugPrint('[boot] window shown');

    // 桌面端初始化系统托盘
    await initSystemTray();
    debugPrint('[boot] tray initialized');
  }

  // 1) 加载服务器环境配置 (assets/config/servers.json + SharedPreferences 恢复)
  //    必须在 ApiClient 与 AuthViewModel 之前完成, 否则 AppEnv.* 抛 StateError
  await ServerConfigService.instance.initialize();
  debugPrint('[boot] server config loaded');

  // 2) 提前触发一次 ApiClient 单例, 让 Dio + 拦截器(注入 tenant/Private-Key/Authorization)就绪,
  //    同时挂上对 ServerConfigService 的监听 (切换服务器时同步 baseUrl + 清 token)
  // ignore: unused_local_variable
  final _ = ApiClient.instance.dio;
  debugPrint('[boot] ApiClient ready, calling runApp()');

  // 3) 全局登录态 + 会话失效处理:
  //    AuthViewModel 提前构造 (而非在 Provider 里 create), 这样才能把同一个实例
  //    交给 installSessionExpiryHandler — 任何接口返回未登录/登录过期时,
  //    由它清态并强制跳回 LoginScreen。注册要在 bootstrap() 之前, 否则启动时
  //    getUserProfile 的 401 会因回调未挂上而被忽略。
  final authViewModel = AuthViewModel();
  installSessionExpiryHandler(authViewModel);
  unawaited(authViewModel.bootstrap());

  // **重要**: runApp() 必须在 root zone 调用, 因为 WidgetsFlutterBinding 是在 root zone
  // 初始化的。_runApp() 自身是经由 runZonedGuarded 调用的, 默认在自定义 zone;
  // 用 rootZone.run() 桥接到根 zone, 避免 zone mismatch.
  rootZone.run(() {
    runApp(
      MultiProvider(
        providers: [
          // 注入 ServerConfigService 单例, 供 UI 读取当前活动 profile
          ChangeNotifierProvider<ServerConfigService>.value(
            value: ServerConfigService.instance,
          ),
          ChangeNotifierProvider(create: (_) => DeviceModel()),
          // 用 .value 注入上面提前构造的实例, 保证 installSessionExpiryHandler
          // 持有的就是 UI 树里的同一个 AuthViewModel
          ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
        ],
        child: const TalixApp(),
      ),
    );
  });
  debugPrint('[boot] runApp returned');
}

class TalixApp extends StatelessWidget {
  const TalixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talix Companion',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      // 主色取自 Figma「Talix AI Device UI」设计稿, 详见 theme/app_colors.dart。
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: AppTypography.fontFamily,
        // 统一选择类控件的选中色, 避免各画面再单独传 activeColor。
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.surface
                : AppColors.surface,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.neutralFill,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.transparent,
          ),
          checkColor: const WidgetStatePropertyAll(AppColors.textOnPrimary),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.borderUnselected,
          ),
        ),
      ),
      // 启动时由 AuthGate 监听 AuthViewModel.isLoggedIn,
      //   未登录 → LoginScreen (已实现)
      //   已登录 → MainFrame  (已实现)
      // 后续退出登录时由 AuthGate 自动重定向回 LoginScreen
      home: const AuthGate(),
      // 在桌面端通过 builder 套一层窗口外壳,实现 8px 圆角 + 阴影 + 自定义标题栏
      builder: (context, child) {
        if (kIsWeb || !(Platform.isWindows || Platform.isMacOS)) {
          return child ?? const SizedBox.shrink();
        }
        return _DesktopWindowShell(child: child);
      },
    );
  }
}

/// AuthGate: 登录态路由分发
///
/// 监听全局 AuthViewModel.isLoggedIn 切换:
///   - 未登录 → LoginScreen
///   - 已登录 → MainFrame
///   - 退出登录 (AuthViewModel.logout) → 自动回退到 LoginScreen
///
/// 启动时由 main() 中 `..bootstrap()` 触发一次,异步从本地 TokenStorage 恢复登录态。
///
/// 实现方式:StatefulWidget + addListener, 不依赖 Consumer<AuthViewModel> 的隐式订阅。
/// 原因:Consumer 在某些 Provider 树布局下(尤其是 MaterialApp.builder 再裹一层
/// _DesktopWindowShell)会偶发不响应 notifyListeners, 这里改成显式 addListener +
/// setState 强制 rebuild, 行为更可预测, 不会因为 Consumer 漏订阅导致卡死。
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthViewModel? _auth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthViewModel>();
    if (_auth != auth) {
      // 同一棵 Provider 树里 context.read 始终返回同一实例,
      // 但 didChangeDependencies 会在祖先 rebuild 时再触发,
      // 用 == (ChangeNotifier 默认 Object 引用比较) 即可判等
      _auth?.removeListener(_onAuthChanged);
      _auth = auth;
      _auth!.addListener(_onAuthChanged);
      debugPrint('[auth] AuthGate: subscribed to AuthViewModel isLoggedIn=${auth.isLoggedIn}');
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    debugPrint('[auth] AuthGate._onAuthChanged fired: isLoggedIn=${_auth?.isLoggedIn}');
    if (mounted) {
      setState(() {
        // setState 内不必做事, build 本身会重新读取 _auth.isLoggedIn
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth ?? context.read<AuthViewModel>();
    final showLogin = !auth.isLoggedIn;
    debugPrint('[auth] AuthGate.build: isLoggedIn=${auth.isLoggedIn} → ${showLogin ? "LoginScreen" : "MainFrame"}');
    return showLogin ? const LoginScreen() : const MainFrame();
  }
}

/// Desktop window shell that gives the entire app:
/// - 8px rounded corners (matching the Figma frame 1218:4180)
/// - Drop shadow 0 4 4 rgba(0,0,0,0.25) (matching the Figma effect)
/// - Custom window title bar at the top
class _DesktopWindowShell extends StatelessWidget {
  const _DesktopWindowShell({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // 填满整个窗口,不再留 margin。窗口背景已在 main() 中设为 transparent,
    // Windows 操作系统会为透明窗口自动绘制 DropShadow,与设计图 0 4 4 rgba(0,0,0,0.25) 一致。
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const WindowTitleBar(),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

/// 启动期致命错误显示页 — 避免 .exe 双击运行时看不到控制台输出
///
/// 不依赖任何 Provider / 自定义 widget,只用 Material 内建组件,
/// 保证即便主 widget 树初始化失败也能渲染出来。
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
                  '错误信息 / Error message:',
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
                    '堆栈 / Stack trace:',
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
