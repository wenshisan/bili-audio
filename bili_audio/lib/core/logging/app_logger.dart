import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// 日志等级。低于 [AppLogger.minLevel] 的记录会被丢弃。
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

/// 本地日志。
///
/// 控制台走 [debugPrint]；桌面端同时按天写入 [init] 指定的目录
///（`app-YYYYMMDD.log`），并清理 7 天前的文件。未调用 [init] 时只输出到控制台。
///
/// Cookie、SESSDATA 等密钥不要写进 [message]，网络层用
/// [formatQuery] / [summarizeBody] 做脱敏。
class AppLogger {
  AppLogger._();

  static bool enabled = true;
  static LogLevel minLevel = LogLevel.debug;
  static const retentionDays = 7;

  static bool _initialized = false;
  static IOSink? _sink;
  static String? _currentDate;
  static Timer? _cleanupTimer;
  static String? _logDirPath;
  static Future<void> _writeQueue = Future<void>.value();

  /// 准备日志目录。可重复调用。目录创建失败时退化为只打控制台。
  static Future<void> init(Directory directory) async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) return;

    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      debugPrint('[AppLogger] cannot create ${directory.path}: $e');
      return;
    }

    _logDirPath = directory.path;
    i('logging to ${directory.path}', tag: 'log');
    try {
      unawaited(_cleanupOldLogs());
      _cleanupTimer = Timer.periodic(
        const Duration(hours: 6),
        (_) => _cleanupOldLogs(),
      );
    } catch (e) {
      debugPrint('[AppLogger] cleanup setup failed: $e');
    }
  }

  /// 关闭文件句柄。测试结束时调用。
  static Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _logDirPath = null;
    await _writeQueue;
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    _currentDate = null;
    _initialized = false;
  }

  static void d(Object? message, {String tag = 'app'}) =>
      _log(LogLevel.debug, tag, message);

  static void i(Object? message, {String tag = 'app'}) =>
      _log(LogLevel.info, tag, message);

  static void w(Object? message, {String tag = 'app'}) =>
      _log(LogLevel.warn, tag, message);

  static void e(
    Object? message, {
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);

  static void _log(
    LogLevel level,
    String tag,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled || !(level >= minLevel)) return;

    final line = formatLine(DateTime.now(), level, tag, message, error: error);
    if (stackTrace != null) {
      debugPrint('$line\n$stackTrace');
    } else {
      debugPrint(line);
    }
    _writeToFile(line, stackTrace);
  }

  static String formatLine(
    DateTime time,
    LogLevel level,
    String tag,
    Object? message, {
    Object? error,
  }) {
    final buffer = StringBuffer()
      ..write(_formatTimestamp(time))
      ..write(' [')
      ..write(level.label)
      ..write('] ')
      ..write(_normalizeTag(tag))
      ..write(': ')
      ..write(message ?? '');
    if (error != null) {
      buffer
        ..write(' | ')
        ..write(error);
    }
    return buffer.toString();
  }

  static void _writeToFile(String line, StackTrace? stackTrace) {
    final dir = _logDirPath;
    if (dir == null) return;
    _writeQueue = _writeQueue.then((_) async {
      try {
        final now = DateTime.now();
        final dateStr = _formatDate(now);
        if (_sink == null || _currentDate != dateStr) {
          await _sink?.flush();
          await _sink?.close();
          _currentDate = dateStr;
          _sink = File(
            p.join(dir, 'app-$dateStr.log'),
          ).openWrite(mode: FileMode.append);
        }
        _sink!.writeln(line);
        if (stackTrace != null) _sink!.writeln(stackTrace.toString());
        await _sink!.flush();
      } catch (e) {
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

  static Future<void> _cleanupOldLogs() async {
    if (retentionDays <= 0) return;
    final dirPath = _logDirPath;
    if (dirPath == null) return;
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;
      final cutoff = DateTime.now().subtract(
        const Duration(days: retentionDays),
      );
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        final match = RegExp(r'^app-(\d{8})\.log$').firstMatch(name);
        if (match == null) continue;
        final raw = match.group(1)!;
        final fileDate = DateTime.tryParse(
          '${raw.substring(0, 4)}-${raw.substring(4, 6)}-${raw.substring(6, 8)}',
        );
        if (fileDate != null && fileDate.isBefore(cutoff)) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[AppLogger] cleanup failed: $e');
    }
  }
}

/// 查询参数脱敏。登录态相关字段只保留键名。
String formatQuery(Map<String, dynamic> query) {
  if (query.isEmpty) return '';
  return query.entries
      .map((entry) {
        final secret = _secretKeys.contains(entry.key.toLowerCase());
        final value = secret ? '***' : clip('${entry.value}', 80);
        return '${entry.key}=$value';
      })
      .join('&');
}

/// 响应摘要：保留 code / message / 数据结构，不展开 URL 等大字段。
String summarizeBody(Object? data) {
  if (data is List) return 'list(${data.length})';
  if (data is! Map) return clip('${data ?? 'null'}');
  final code = data['code'];
  final message = data['message'];
  return 'code=$code message=${clip('${message ?? ''}')} data=${shapeOf(data['data'])}';
}

/// 描述 JSON 节点的形状，不输出字符串内容。
String shapeOf(Object? data) {
  if (data == null) return 'null';
  if (data is List) return 'list(${data.length})';
  if (data is Map) {
    final keys = data.keys.take(8).join(',');
    final extra = data.length > 8 ? ',…' : '';
    return 'map(${data.length})[$keys$extra]';
  }
  return clip('$data', 80);
}

String clip(String text, [int max = 160]) =>
    text.length <= max ? text : '${text.substring(0, max)}…';

const _secretKeys = {
  'sessdata',
  'bili_jct',
  'dedeuserid',
  'dedeuserid__ckmd5',
  'sid',
  'access_key',
  'csrf',
  'csrf_token',
  'cookie',
};
