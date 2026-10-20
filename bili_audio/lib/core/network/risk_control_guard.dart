import 'package:flutter/foundation.dart';

/// 风控冷却 (M2.7)
///
/// [window] 内累计 [threshold] 次 -412 进入冷却 [cooldown];
/// 冷却期间受保护的请求 (如搜索) 直接失败, 不再打到服务端。
/// 已缓存内容的播放不经过网络, 不受影响。
class RiskControlGuard {
  RiskControlGuard({
    this.threshold = 3,
    this.window = const Duration(minutes: 1),
    this.cooldown = const Duration(seconds: 60),
    DateTime Function()? clock,
    this.onEvent,
  }) : _clock = clock ?? DateTime.now;

  final int threshold;
  final Duration window;
  final Duration cooldown;
  final DateTime Function() _clock;

  /// 风控事件回调 (写本地日志, 便于调整限频)
  final void Function(String message)? onEvent;

  final List<DateTime> _hits = [];
  DateTime? _cooldownUntil;

  bool get inCooldown {
    final until = _cooldownUntil;
    return until != null && _clock().isBefore(until);
  }

  Duration get remaining {
    final until = _cooldownUntil;
    if (until == null) return Duration.zero;
    final d = until.difference(_clock());
    return d.isNegative ? Duration.zero : d;
  }

  /// 记录一次 -412
  void recordHit(String path) {
    final now = _clock();
    _hits
      ..add(now)
      ..removeWhere((t) => now.difference(t) > window);
    onEvent?.call('risk-control hit #${_hits.length} on $path');
    if (_hits.length >= threshold) {
      _cooldownUntil = now.add(cooldown);
      _hits.clear();
      onEvent?.call('enter cooldown ${cooldown.inSeconds}s');
    }
  }

  @visibleForTesting
  void reset() {
    _hits.clear();
    _cooldownUntil = null;
  }
}
