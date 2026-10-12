import 'dart:io';
import 'package:window_manager/window_manager.dart';

import '../utils/app_logger.dart';

/// ============================================================
/// 悬浮窗进程状态 + 主窗口/悬浮窗联动控制器
///
/// 业务规则:
///   - 主窗口 visible (打开)   → 关闭悬浮窗
///   - 主窗口 hidden  (到托盘) → 打开悬浮窗
///
/// 全部入口(托盘菜单 show/hide / 双击托盘 / 标题栏 X 关闭按钮)都统一走
/// [showMainWindow] / [hideMainWindow],确保联动一致。
///
/// 注意: window_manager 的 WindowListener mixin 没有 onWindowShow /
/// onWindowHide 事件,只能通过显式入口联动,所以**禁止**在 lib/ 别处直接
/// 调用 windowManager.show() / windowManager.hide(),否则悬浮窗状态会不同步。
/// ============================================================

bool _isFloatWindowOpen = false;
Process? _floatWindowProcess;

bool get isFloatWindowOpen => _isFloatWindowOpen;

/// 统一入口: 显示主窗口 → 关闭悬浮窗
Future<void> showMainWindow() async {
  await windowManager.show();
  await windowManager.focus();
  await closeFloatWindow();
}

/// 统一入口: 隐藏主窗口到托盘 → 打开悬浮窗
///
/// 性能注意: openFloatWindow() 内部包含磁盘 I/O (File.exists) 和
/// Process.start 启动外部进程,在 Windows 上通常需要 100-500ms。
/// 这里**不 await** openFloatWindow,让调用方(关闭按钮/托盘菜单)立即返回,
/// 避免点击关闭后明显的 UI 迟滞。悬浮窗进程会在后台启动,
/// 完成后通过 _isFloatWindowOpen 标志位同步状态(标志位已在
/// openFloatWindow 入口处立即置位,防止并发调用启动多个进程)。
Future<void> hideMainWindow() async {
  await windowManager.hide();
  // Fire and forget - don't block the caller on process startup
  openFloatWindow();
}

/// 启动悬浮窗进程 (幂等: 已打开则 no-op)
///
/// 标志位 _isFloatWindowOpen 在入口处立即置位(而非等待进程启动完成),
/// 防止 hideMainWindow() 改为 fire-and-forget 后被并发调用导致启动多个进程。
/// 启动失败时在 catch 中重置标志位以允许重试。
Future<void> openFloatWindow() async {
  if (_isFloatWindowOpen) {
    AppLogger.d('open skipped: already open', 'float-win');
    return;
  }
  // 立即置位,防止并发调用启动多个进程
  _isFloatWindowOpen = true;
  try {
    // 以"当前可执行文件所在目录"为基准定位 floating 子目录,避免依赖
    // 进程工作目录 (CWD) — 桌面应用在 flutter run / 双击 exe / VSCode 启动
    // 等不同运行方式下 CWD 并不固定, 相对路径会指向错位置。
    final String baseDir = File(Platform.resolvedExecutable).parent.path;
    final String sep = Platform.pathSeparator;
    final String exePath = Platform.isWindows
        ? '$baseDir${sep}floating${sep}talix_desktop_floating_ball.exe'
        : '$baseDir${sep}floating${sep}talix_desktop_floating_ball';
    AppLogger.d('resolved baseDir = $baseDir', 'float-win');
    AppLogger.d('resolved exePath = $exePath', 'float-win');
    if (await File(exePath).exists()) {
      _floatWindowProcess = await Process.start(exePath, []);
    } else {
      AppLogger.w(
        'External float window executable not found. Starting simulating process...',
        'float-win',
      );
      if (Platform.isWindows) {
        _floatWindowProcess = await Process.start('cmd.exe', ['/c', 'timeout', '/t', '9999']);
      } else {
        _floatWindowProcess = await Process.start('sleep', ['9999']);
      }
    }
    AppLogger.i('Floating window opened successfully.', 'float-win');
  } catch (e) {
    AppLogger.e(
      'Failed to start external floating window program',
      'float-win',
      e,
    );
    // 启动失败时重置标志位与进程引用,允许后续重试
    _isFloatWindowOpen = false;
    _floatWindowProcess = null;
  }
}

/// 关闭悬浮窗进程 (幂等: 已关闭则 no-op)
///
/// 关键: 这里会 **await** 子进程真正退出,而不是仅仅发出 kill 信号就返回。
/// 原因: 托盘"退出程序"入口在 closeFloatWindow() 之后会立即调用 exit(0),
/// 如果不等待子进程,主进程退出时悬浮球可能仍处于"正在关闭"状态,
/// 出现孤儿进程或短暂残留窗口。2s 兜底超时保证即使 kill 失败也不会卡住退出流程。
Future<void> closeFloatWindow() async {
  if (!_isFloatWindowOpen) {
    AppLogger.d('close skipped: already closed', 'float-win');
    return;
  }
  Process? proc;
  if (_floatWindowProcess != null) {
    proc = _floatWindowProcess;
    _floatWindowProcess = null;
  }
  // 先把标志位置为 false,避免重入(例如 showMainWindow 也调 closeFloatWindow)
  _isFloatWindowOpen = false;
  if (proc != null) {
    try {
      proc.kill();
    } catch (e) {
      AppLogger.w('kill() raised: $e — process may already be dead', 'float-win');
    }
    try {
      await proc.exitCode.timeout(const Duration(seconds: 2));
      AppLogger.i('Floating window closed.', 'float-win');
    } catch (_) {
      // 超时: kill 已发出,OS 最终会回收子进程,主流程不阻塞
      AppLogger.w('Floating window close timed out (2s); OS will reap later.', 'float-win');
    }
  }
}

/// 托盘菜单"开启/关闭悬浮窗"按钮: 手动切换 (与窗口 show/hide 无关)
Future<void> toggleFloatWindow() async {
  if (_isFloatWindowOpen) {
    await closeFloatWindow();
  } else {
    await openFloatWindow();
  }
}
