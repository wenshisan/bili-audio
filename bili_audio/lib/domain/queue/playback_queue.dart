import 'dart:math';

import '../entities/audio_track.dart';

/// 播放模式 (M1.6)
enum PlayMode {
  /// 顺序播放
  sequential,

  /// 列表循环
  listLoop,

  /// 单曲循环
  singleLoop,

  /// 随机播放
  shuffle,

  /// 智能随机 (避免同歌手连续)
  smartShuffle,
}

/// 播放队列 (M1.6)
///
/// 管理播放顺序、模式切换、随机逻辑。
/// 支持持久化和恢复。
class PlaybackQueue {
  PlaybackQueue({
    List<Track> tracks = const [],
    PlayMode mode = PlayMode.sequential,
    int? seed,
  })  : _original = List.from(tracks),
        _order = List.generate(tracks.length, (i) => i),
        _mode = mode,
        _seed = seed ?? DateTime.now().millisecondsSinceEpoch {
    if (_isShuffleMode(mode)) {
      _shuffleOrder();
    }
  }

  final List<Track> _original;
  List<int> _order;
  int _cursor = 0;
  PlayMode _mode;
  final int _seed;
  final List<int> _history = [];

  Track? get current => _cursor < _order.length
      ? _original[_order[_cursor]]
      : null;

  Track? get nextTrack => _hasNext()
      ? _original[_order[_nextCursor()]]
      : null;

  PlayMode get mode => _mode;
  int get length => _original.length;
  bool get isEmpty => _original.isEmpty;
  int get cursor => _cursor;
  List<Track> get tracks => List.unmodifiable(_original);

  /// 获取当前播放顺序的轨道列表
  List<Track> get orderedTracks =>
      _order.map((i) => _original[i]).toList();

  /// 下一首
  Track? next() {
    if (isEmpty) return null;

    if (_mode == PlayMode.singleLoop) {
      // 单曲循环: 不移动光标
      return current;
    }

    if (!_hasNext()) {
      if (_mode == PlayMode.listLoop) {
        // 列表循环: 回到开头
        _cursor = 0;
        _history.clear();
      } else {
        // 顺序播放到头: 返回null
        return null;
      }
    } else {
      _history.add(_cursor);
      _cursor = _nextCursor();
    }

    return current;
  }

  /// 上一首
  Track? previous() {
    if (isEmpty) return null;

    if (_mode == PlayMode.singleLoop) {
      // 单曲循环: 不移动光标
      return current;
    }

    // 随机模式: 从历史回退
    if (_isShuffleMode(_mode) && _history.isNotEmpty) {
      _cursor = _history.removeLast();
      return current;
    }

    // 顺序模式: cursor - 1
    if (_cursor > 0) {
      _cursor--;
      return current;
    } else if (_mode == PlayMode.listLoop) {
      _cursor = _order.length - 1;
      return current;
    }

    return null;
  }

  /// 跳到 [tracks] 中第 [index] 首 (用户在列表中点选)
  ///
  /// 随机模式下当前位置记入历史, 便于"上一曲"回退。
  Track? jumpTo(int index) {
    if (index < 0 || index >= _original.length) return null;
    final pos = _order.indexOf(index);
    if (pos != _cursor) {
      if (_isShuffleMode(_mode)) _history.add(_cursor);
      _cursor = pos;
    }
    return current;
  }

  /// 切换播放模式
  void setMode(PlayMode newMode) {
    if (_mode == newMode) return;

    final currentTrack = current;
    _mode = newMode;

    if (_isShuffleMode(newMode)) {
      // 切换到随机: 以当前曲为首重建order
      _shuffleOrder();
      _history.clear();
    } else {
      // 切换到顺序: 定位当前曲在original中的位置
      _order = List.generate(_original.length, (i) => i);
      if (currentTrack != null) {
        _cursor = _original.indexOf(currentTrack);
      }
      _history.clear();
    }
  }

  /// 添加到队尾
  void append(Track track) {
    _original.add(track);
    _order.add(_original.length - 1);
  }

  /// 插入到下一首
  void insertNext(Track track) {
    _original.add(track);
    final newIndex = _original.length - 1;
    _order.insert(_cursor + 1, newIndex);
  }

  /// 移除指定索引
  void removeAt(int index) {
    if (index < 0 || index >= _original.length) return;

    final removedPos = _order.indexOf(index);
    _original.removeAt(index);

    // 更新order: 移除该索引，并调整大于它的索引
    _order = _order
        .where((i) => i != index)
        .map((i) => i > index ? i - 1 : i)
        .toList();

    // 历史记录中的位置失效，直接清空
    _history.clear();

    // 被移除项在光标之前: 光标前移，保持当前曲不变
    if (removedPos < _cursor) _cursor--;
    if (_cursor >= _order.length) {
      _cursor = max(0, _order.length - 1);
    }
  }

  /// 调整顺序 (仅非随机模式可用)
  ///
  /// 随机模式下拒绝并返回 false。
  bool reorder(int from, int to) {
    if (_isShuffleMode(_mode)) return false;
    if (from < 0 || from >= _original.length) return false;
    if (to < 0 || to >= _original.length) return false;

    final currentTrack = current;
    final track = _original.removeAt(from);
    _original.insert(to, track);
    _order = List.generate(_original.length, (i) => i);
    if (currentTrack != null) {
      _cursor = _original.indexOf(currentTrack);
    }
    return true;
  }

  /// 清空队列，保留当前播放
  void clearExceptCurrent() {
    final currentTrack = current;
    if (currentTrack == null) {
      _original.clear();
      _order.clear();
      _cursor = 0;
      _history.clear();
      return;
    }

    _original.clear();
    _original.add(currentTrack);
    _order = [0];
    _cursor = 0;
    _history.clear();
  }

  /// 序列化为快照
  Map<String, dynamic> toSnapshot() {
    return {
      'original': _original.map((t) => t.toJson()).toList(),
      'order': _order,
      'cursor': _cursor,
      'mode': _mode.name,
      'seed': _seed,
      'history': _history,
    };
  }

  /// 从快照恢复
  static PlaybackQueue fromSnapshot(Map<String, dynamic> snapshot) {
    final tracks = (snapshot['original'] as List)
        .map((json) => Track.fromJson(json as Map<String, dynamic>))
        .toList();
    final order = List<int>.from(snapshot['order'] as List);
    final cursor = snapshot['cursor'] as int;
    final mode = PlayMode.values.firstWhere(
      (m) => m.name == snapshot['mode'],
      orElse: () => PlayMode.sequential,
    );
    final seed = snapshot['seed'] as int;
    final history = List<int>.from(snapshot['history'] as List);

    final queue = PlaybackQueue(tracks: tracks, mode: mode, seed: seed);
    queue._order = order;
    queue._cursor = cursor;
    queue._history.addAll(history);
    return queue;
  }

  bool _hasNext() => _cursor + 1 < _order.length;

  int _nextCursor() => _cursor + 1;

  bool _isShuffleMode(PlayMode mode) =>
      mode == PlayMode.shuffle || mode == PlayMode.smartShuffle;

  /// Fisher-Yates 随机打乱
  void _shuffleOrder() {
    final currentTrack = current;
    final random = Random(_seed);

    // 生成新的order
    _order = List.generate(_original.length, (i) => i);

    for (var i = _order.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = _order[i];
      _order[i] = _order[j];
      _order[j] = temp;
    }

    // 将当前曲目移到首位
    if (currentTrack != null) {
      final currentIndex = _original.indexOf(currentTrack);
      final orderIndex = _order.indexOf(currentIndex);
      if (orderIndex != 0) {
        _order[orderIndex] = _order[0];
        _order[0] = currentIndex;
      }
    }

    _cursor = 0;

    // 每轮结束后递增seed，避免下一轮完全重复
    // (在实际播放完一轮后调用，此处预留逻辑)
  }
}
