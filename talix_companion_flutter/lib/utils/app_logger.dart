// ============================================================
// AppLogger: 全局统一日志工具
//
// 目标:
//   1. 替代散落在代码里的 [debugPrint],统一日志格式(时间 + 等级 + tag + 消息)。
//   2. 支持全局开关 [kAppLoggingEnabled]: 设为 false 时,所有日志调用立刻短路,
//      不再消耗任何格式化 / 写文件开销。**发布生产前只需把这一行改成 false。**
//   3. 支持日志等级阈值 [kAppLogLevel]: 低于该等级的日志会被丢弃。
//   4. 桌面端(Windows / macOS / Linux)将日志按天写入用户数据目录,便于
//      现场问题定位:
//        - Windows: %APPDATA%\Talix\logs\app-YYYYMMDD.log
//        - macOS:   ~/Library/Application Support/Talix/logs/app-YYYYMMDD.log
//        - Linux:   $XDG_DATA_HOME/talix/logs/app-YYYYMMDD.log
//                  (无 XDG_DATA_HOME 时回退到 ~/.local/share/talix/logs/)
//   5. 自动清理 7 天前的旧日志文件,避免长期累积占盘。
//   6. 写文件走异步队列,不影响主线程 / UI 响应。
//   7. 同时仍然调用 [debugPrint] 把日志输出到 IDE / `flutter run` 控制台,
//      方便开发期直接看到。
//
// 初始化:
//   - 必须在 main() 中 WidgetsFlutterBinding.ensureInitialized() 之后
//     调用 [AppLogger.init] 完成目录准备 + 启动清理任务。
//   - 不调用 init 也能用,只是不会写文件;静默退化为只输出到 debugPrint。
//
// 用法:
//     AppLogger.d('login start: email=$email', 'auth');
//     AppLogger.i('switched to ${active.name}', 'ApiClient');
//     AppLogger.w('exe not found, fallback to stub', 'float-win');
//     AppLogger.e('login failed', 'auth', e, stackTrace);
//     AppLogger.d('no-tag message'); // tag 省略,默认 'app'
// ============================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 全局日志开关常量
///
/// **唯一需要修改的开关** — 设为 `false` 时,所有 [AppLogger] 调用立即返回,
/// 不会触发任何字符串拼接或文件写入,运行时开销接近 0。
///
/// 默认值: `true`(开发期开启,便于排查;发布前手动置为 `false` 即可全局静默)。
const bool kAppLoggingEnabled = true;

/// 全局日志等级阈值 — 低于该等级的日志会被丢弃
///
/// 例如设为 [LogLevel.info] 时,debug 级日志被吞掉;warn / error 仍然输出。
/// 默认 [LogLevel.debug]: 全部输出。
const LogLevel kAppLogLevel = LogLevel.debug;

/// 历史日志保留天数(0 表示不清理)
const int kAppLogRetentionDays = 7;

/// 日志等级
enum LogLevel {
  debug(0, 'D'),
  info(1, 'I'),
  warn(2, 'W'),
  error(3, 'E');

  const LogLevel(this.priority, this.label);
  final int priority;
  final String label;

  bool operator >=(LogLevel other) => priority >= other.priority;
}

/// 全局日志工具
///
/// 静态 API,无需持有实例。线程安全(内部使用串行队列)。
class AppLogger {
  AppLogger._();

  static bool _initialized = false;
  static IOSink? _sink;
  static String? _currentDate;
  static Timer? _cleanupTimer;
  static String? _logDirPath;

  // 异步写文件队列:保证写入顺序、避免主线程阻塞
  static Future<void> _writeQueue = Future.value();

  /// 初始化:准备日志目录、清理过期文件、启动后台清理定时器
  ///
  /// **非阻塞设计** — 内部全部 IO 都包在 try/catch 中,即便目录创建失败、
  /// 权限不足、磁盘满、清理任务抛错等任何情况,init 都会快速返回,
  /// 不会拖慢 main() 启动。
  ///
  /// 可重复调用(幂等)。
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 仅桌面端写文件;移动端 / Web 暂不落盘
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return;
    }

    // 解析日志目录 — 单步隔离
    String dirPath;
    try {
      dirPath = _resolveLogDir();
    } catch (e) {
      debugPrint('[AppLogger] _resolveLogDir failed: $e — file logging disabled');
      return;
    }
    if (dirPath.isEmpty) {
      debugPrint('[AppLogger] empty log dir — file logging disabled');
      return;
    }
    _logDirPath = dirPath;

    // 创建目录 — 单步隔离
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('[AppLogger] cannot create $dirPath: $e — file logging disabled');
      _logDirPath = null;
      return;
    }

    // 启动时清理一次过期日志 + 周期清理 — 单步隔离,失败也无所谓
    try {
      unawaited(_cleanupOldLogs());
    } catch (e) {
      debugPrint('[AppLogger] startup cleanup failed: $e');
    }
    try {
      _cleanupTimer = Timer.periodic(
        const Duration(hours: 6),
        (_) => _cleanupOldLogs(),
      );
    } catch (e) {
      debugPrint('[AppLogger] cleanup timer failed: $e');
    }
  }

  /// 关闭文件句柄(测试 / 退出场景)
  static Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    await _writeQueue;
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    _currentDate = null;
    _initialized = false;
  }

  // ============== 公共 API ==============

  static void d(Object? message, [String tag = 'app']) =>
      _log(LogLevel.debug, tag, message);

  static void i(Object? message, [String tag = 'app']) =>
      _log(LogLevel.info, tag, message);

  static void w(Object? message, [String tag = 'app']) =>
      _log(LogLevel.warn, tag, message);

  /// 错误日志:支持附加 [error] 与 [stackTrace],方便后续排查
  static void e(
    Object? message, [
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  ]) =>
      _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);

  // ============== 内部 ==============

  static void _log(
    LogLevel level,
    String tag,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // 1) 全局开关 — 最早短路,避免字符串拼接开销
    if (!kAppLoggingEnabled) return;
    // 2) 等级阈值
    if (!(level >= kAppLogLevel)) return;

    final ts = _formatTimestamp(DateTime.now());
    final line = StringBuffer()
      ..write('$ts ')
      ..write('[${level.label}] ')
      ..write(_normalizeTag(tag))
      ..write(': ')
      ..write(message ?? '');
    if (error != null) {
      line
        ..write(' | error=')
        ..write(error);
    }

    final lineStr = line.toString();

    // 控制台 / IDE 输出 — 通过 debugPrint,与旧行为兼容
    if (stackTrace != null) {
      debugPrint('$lineStr\n$stackTrace');
    } else {
      debugPrint(lineStr);
    }

    // 文件输出 (异步,不阻塞调用方)
    _writeToFile(lineStr, stackTrace);
  }

  static void _writeToFile(String line, StackTrace? stackTrace) {
    if (_logDirPath == null) return;
    final dir = _logDirPath!;

    _writeQueue = _writeQueue.then((_) async {
      try {
        final now = DateTime.now();
        final dateStr = _formatDate(now);

        // 跨天 → 切换文件
        if (_sink == null || _currentDate != dateStr) {
          await _sink?.flush();
          await _sink?.close();
          _currentDate = dateStr;
          _sink = File('$dir${Platform.pathSeparator}app-$dateStr.log')
              .openWrite(mode: FileMode.append);
        }

        _sink!.writeln(line);
        if (stackTrace != null) {
          _sink!.writeln(stackTrace.toString());
        }
        // 每行 flush 一次,确保崩溃时日志不丢;日志量小,IO 不是瓶颈
        await _sink!.flush();
      } catch (e) {
        // 文件写失败不能影响主流程
        debugPrint('[AppLogger] file write failed: $e');
      }
    });
  }

  static String _normalizeTag(String tag) {
    if (tag.isEmpty) return 'app';
    return tag.length > 24 ? tag.substring(0, 24) : tag;
  }

  static String _formatTimestamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}'
        '.${three(t.millisecond)}';
  }

  static String _formatDate(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}';
  }

  static String _resolveLogDir() {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      final base = (appData != null && appData.isNotEmpty)
          ? appData
          : '${Platform.environment['USERPROFILE'] ?? '.'}\\AppData\\Roaming';
      return '$base\\Talix\\logs';
    }
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '.';
      return '$home/Library/Application Support/Talix/logs';
    }
    // Linux
    final xdg = Platform.environment['XDG_DATA_HOME'];
    final base = (xdg != null && xdg.isNotEmpty)
        ? xdg
        : '${Platform.environment['HOME'] ?? '.'}/.local/share';
    return '$base/talix/logs';
  }

  static Future<void> _cleanupOldLogs() async {
    if (kAppLogRetentionDays <= 0) return;
    final dirPath = _logDirPath;
    if (dirPath == null) return;

    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;
      final cutoff = DateTime.now().subtract(
        const Duration(days: kAppLogRetentionDays),
      );
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        // 仅清理自己生成的 app-YYYYMMDD.log
        final m = RegExp(r'^app-(\d{8})\.log$').firstMatch(name);
        if (m == null) continue;
        final fileDate = DateTime.tryParse(
          '${m.group(1)!.substring(0, 4)}-'
          '${m.group(1)!.substring(4, 6)}-'
          '${m.group(1)!.substring(6, 8)}',
        );
        if (fileDate != null && fileDate.isBefore(cutoff)) {
          try {
            await entity.delete();
          } catch (_) {
            // 单个文件删除失败不阻塞其他清理
          }
        }
      }
    } catch (e) {
      debugPrint('[AppLogger] cleanup failed: $e');
    }
  }
}
