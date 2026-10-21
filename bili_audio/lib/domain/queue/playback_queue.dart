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
    int startIndex = 0,
  }) : _original = List.from(tracks),
       _order = List.generate(tracks.length, (i) => i),
       _mode = mode,
       _seed = seed ?? DateTime.now().millisecondsSinceEpoch {
    if (startIndex > 0 && startIndex < _original.length) {
      _cursor = startIndex;
    }
    if (_isShuffleMode(mode)) {
      _shuffleOrder();
    }
  }

  final List<Track> _original;
  List<int> _order;
  int _cursor = 0;
  PlayMode _mode;
  int _seed;
  final List<int> _history = [];

  Track? get current =>
      _cursor < _order.length ? _original[_order[_cursor]] : null;

  Track? get nextTrack => _hasNext() ? _original[_order[_nextCursor()]] : null;

  PlayMode get mode => _mode;
  int get length => _original.length;
  bool get isEmpty => _original.isEmpty;
  int get cursor => _cursor;
  List<Track> get tracks => List.unmodifiable(_original);

  /// 获取当前播放顺序的轨道列表
  List<Track> get orderedTracks => _order.map((i) => _original[i]).toList();

  /// 下一首
  Track? next() {
    if (isEmpty) return null;

    if (_mode == PlayMode.singleLoop) {
      // 单曲循环: 不移动光标
      return current;
    }

    if (_isShuffleMode(_mode)) {
      // 队列仍按原顺序往后排时, 先打乱未播放部分
      _shuffleUpcomingIfOriginalOrder();
    }

    if (!_hasNext()) {
      if (_mode == PlayMode.listLoop) {
        // 列表循环: 回到开头
        _cursor = 0;
        _history.clear();
      } else if (_isShuffleMode(_mode)) {
        // 一轮结束: 换种子重排, 下一首不与本轮最后一首相同
        _startNextRound();
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

  /// 替换当前曲目的元信息 (用户编辑歌名后), 不改变顺序与历史
  void replaceCurrent(Track track) {
    if (_cursor >= _order.length) return;
    _original[_order[_cursor]] = track;
  }

  /// 切换播放模式
  void setMode(PlayMode newMode) {
    if (_mode == newMode) return;

    final currentTrack = current;
    _mode = newMode;

    if (_isShuffleMode(newMode)) {
      // 切换到随机: 换种子, 以当前曲为首重建 order
      _seed++;
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

  /// 添加到队尾。随机模式下若未播放部分仍是原顺序, 打乱它们。
  void append(Track track) {
    _original.add(track);
    _order.add(_original.length - 1);
    if (_isShuffleMode(_mode)) {
      _shuffleUpcomingIfOriginalOrder();
    }
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

  /// 未播放部分仍是「当前曲在原列表中的后继」时打乱, 避免随机模式却顺序切歌。
  ///
  /// 只动光标之后的曲目, 已播放的不重复插入。用户点「下一首播放」插入的曲
  /// 不在这条连续后继上, 因此不会被打乱。
  void _shuffleUpcomingIfOriginalOrder() {
    final start = _cursor + 1;
    if (_order.length - start < 2 || _cursor >= _order.length) return;
    final currentIndex = _order[_cursor];
    for (var i = start; i < _order.length; i++) {
      if (_order[i] != currentIndex + (i - _cursor)) return;
    }
    _seed++;
    final random = Random(_seed);
    for (var i = _order.length - 1; i > start; i--) {
      final j = start + random.nextInt(i - start + 1);
      final temp = _order[i];
      _order[i] = _order[j];
      _order[j] = temp;
    }
    _avoidSequentialSuccessor(random);
  }

  /// 一轮随机耗尽后重排。新一轮第一首不与上一轮最后一首相同。
  void _startNextRound() {
    final last = current;
    _seed++;
    final random = Random(_seed);
    _order = _fisherYates(random);

    if (last != null && _order.length > 1) {
      final lastIndex = _original.indexOf(last);
      if (lastIndex >= 0 && _order[0] == lastIndex) {
        final j = 1 + random.nextInt(_order.length - 1);
        final temp = _order[0];
        _order[0] = _order[j];
        _order[j] = temp;
      }
    }

    _cursor = 0;
    _avoidSequentialSuccessor(random);
    _history.clear();
    if (last != null && _order.length > 1) {
      final back = _order.indexOf(_original.indexOf(last));
      if (back > 0) _history.add(back);
    }
  }

  List<int> _fisherYates(Random random) {
    final order = List.generate(_original.length, (i) => i);
    for (var i = order.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = order[i];
      order[i] = order[j];
      order[j] = temp;
    }
    return order;
  }

  /// Fisher-Yates 随机打乱, 当前曲固定在首位。
  /// 若紧接着的一首刚好是原列表的下一首, 再和后面交换, 避免切歌仍像顺序播放。
  void _shuffleOrder() {
    final currentTrack = current;
    final random = Random(_seed);
    _order = _fisherYates(random);

    if (currentTrack != null) {
      final currentIndex = _original.indexOf(currentTrack);
      final orderIndex = currentIndex < 0 ? -1 : _order.indexOf(currentIndex);
      if (orderIndex > 0) {
        _order[orderIndex] = _order[0];
        _order[0] = currentIndex;
      }
    }

    _cursor = 0;
    _avoidSequentialSuccessor(random);
  }

  void _avoidSequentialSuccessor(Random random) {
    if (_order.length < 3 || _cursor >= _order.length) return;
    final successor = _order[_cursor] + 1;
    final nextPos = _cursor + 1;
    if (successor >= _original.length || _order[nextPos] != successor) return;
    if (nextPos + 1 >= _order.length) return;
    final j = nextPos + 1 + random.nextInt(_order.length - nextPos - 1);
    final temp = _order[nextPos];
    _order[nextPos] = _order[j];
    _order[j] = temp;
  }
}
