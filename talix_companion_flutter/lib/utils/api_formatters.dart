// ============================================================
// API 响应字段格式化器
//
// 后端返回的字段 (尤其录音/转写/账单域) 大量使用
// - 毫秒/秒时间戳 → "今天 21:22" / "5月6日 09:22"
// - 秒数 duration → "25分钟" / "1小时30分"
// - 整数 status → 文件状态字符串
//
// 这些格式化逻辑集中在工具层,避免散落在各 fromJson 工厂。
// ============================================================

import 'package:flutter/foundation.dart';

/// 把后端时间戳 (毫秒) 格式化为 UI 友好的日期字符串
///
/// 规则:
/// - 今天 → "今天 HH:mm"
/// - 昨天 → "昨天 HH:mm"
/// - 今年 → "M月D日 HH:mm"
/// - 更早 → "yyyy/M/d HH:mm"
String formatChatDate(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(that).inDays;

  final hm = '${_p2(dt.hour)}:${_p2(dt.minute)}';
  final month = dt.month;
  final day = dt.day;
  final year = dt.year;
  if (diff == 0) return '今天 $hm';
  if (diff == 1) return '昨天 $hm';
  if (dt.year == now.year) return '$month月$day日 $hm';
  return '$year/$month/$day $hm';
}

/// 把后端时间戳 (毫秒) 格式化为回收站视图的删除时间字符串
/// "5月6日 09:22"
String formatRecycleDate(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${dt.month}月${dt.day}日 ${_p2(dt.hour)}:${_p2(dt.minute)}';
}

/// 把秒数格式化为 "25分钟" / "1小时30分" / "56秒"
String formatDuration(int? seconds) {
  if (seconds == null || seconds <= 0) return '';
  if (seconds < 60) return '$seconds秒';
  if (seconds < 3600) {
    final m = seconds ~/ 60;
    return '$m分钟';
  }
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (m == 0) return '$h小时';
  return '$h小时$m分';
}

/// 把秒数格式化为转写时间文本 "00:05" / "01:23:45"
String formatTimecode(int? seconds) {
  if (seconds == null || seconds < 0) return '00:00';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h == 0) return '${_p2(m)}:${_p2(s)}';
  return '${_p2(h)}:${_p2(m)}:${_p2(s)}';
}

/// 文件状态 (后端 status int) → UI 字符串
///
/// 后端约定 (推断自 CSV 注释,实际以接口联调为准):
/// 0 = waiting, 1 = completed, 2 = transcribing, 3 = failed, 4 = pending
String mapFileStatusToInternal(dynamic raw) {
  final code = (raw is num) ? raw.toInt() : (int.tryParse('$raw') ?? -1);
  switch (code) {
    case 0:
      return 'waiting';
    case 1:
      return 'completed';
    case 2:
      return 'transcribing';
    case 3:
      return 'failed';
    case 4:
      return 'pending';
    default:
      if (kDebugMode) {
        debugPrint('[fileStatus] unknown code: $raw');
      }
      return 'pending';
  }
}

/// 文件状态 (UI 内部值) → 用户可见的中文状态文本
///
/// 完成态返回空串 (不显示状态文本,直接显示 duration)
String mapFileStatusToText(String? fileStatus) {
  switch (fileStatus) {
    case 'completed':
      return ''; // 完成态:不显示状态文本
    case 'transcribing':
      return '正在转写';
    case 'waiting':
      return '等待同步至手机';
    case 'pending':
      return '转写未生成';
    case 'failed':
      return '转写失败';
    default:
      return '';
  }
}

/// 安全把 dynamic 转为 int
int asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// 安全把 dynamic 转为 String (空值返回 '')
String asString(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

/// 安全把 dynamic 转为 bool
bool asBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return fallback;
}

String _p2(int n) => n.toString().padLeft(2, '0');
