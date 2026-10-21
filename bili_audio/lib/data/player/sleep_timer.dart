import 'dart:async';

/// 定时停止状态 (M3.6)
sealed class SleepState {
  const SleepState();
}

class SleepOff extends SleepState {
  const SleepOff();
}

/// 倒计时中
class SleepCountdown extends SleepState {
  const SleepCountdown(this.remaining);
  final Duration remaining;
}

/// 播完 [tracksLeft] 首后停止 (1 = 播完当前)
class SleepAfterTracks extends SleepState {
  const SleepAfterTracks(this.tracksLeft);
  final int tracksLeft;
}

/// 定时停止 (M3.6): 15/30/60 分钟、播完当前/下一首
class SleepTimer {
  SleepTimer({
    required this.onFire,
    this.tick = const Duration(seconds: 1),
  });

  /// 时间到时调用 (暂停播放并通知 UI)
  final Future<void> Function() onFire;
  final Duration tick;

  final _state = StreamController<SleepState>.broadcast();
  SleepState _current = const SleepOff();
  Timer? _timer;
  DateTime? _deadline;

  SleepState get state => _current;
  Stream<SleepState> get stream => _state.stream;

  void start(Duration duration) {
    cancel();
    _deadline = DateTime.now().add(duration);
    _set(SleepCountdown(duration));
    _timer = Timer.periodic(tick, (_) => _onTick());
    // 时长小于 tick 时也能准时触发
    if (duration < tick) {
      _timer?.cancel();
      _timer = Timer(duration, _onTick);
    }
  }

  void startAfterTracks(int count) {
    cancel();
    _set(SleepAfterTracks(count));
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _deadline = null;
    _set(const SleepOff());
  }

  /// 由播放器在每首曲目自然结束时调用; 返回 true 表示应停止而非继续
  bool onTrackCompleted() {
    final s = _current;
    if (s is! SleepAfterTracks) return false;
    if (s.tracksLeft > 1) {
      _set(SleepAfterTracks(s.tracksLeft - 1));
      return false;
    }
    _set(const SleepOff());
    unawaited(onFire());
    return true;
  }

  void _onTick() {
    final deadline = _deadline;
    if (deadline == null) return;
    final left = deadline.difference(DateTime.now());
    if (left <= Duration.zero) {
      cancel();
      unawaited(onFire());
    } else {
      _set(SleepCountdown(left));
    }
  }

  void _set(SleepState s) {
    _current = s;
    if (!_state.isClosed) _state.add(s);
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _state.close();
  }
}
