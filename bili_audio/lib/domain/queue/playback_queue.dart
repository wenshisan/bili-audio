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
/// 随机播放不预先打乱列表: 点下一首时才在本轮未播曲目里选取。
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
  }

  final List<Track> _original;
  List<int> _order;
  int _cursor = 0;
  PlayMode _mode;
  int _seed;
  final List<int> _history = [];

  /// 本轮已经离开过的曲目 (original 下标)。点下一首时不再选中它们。
  Set<int> _played = {};

  /// 「下一首播放」插入的曲目, 最近插入的排在前面。
  final List<int> _pinned = [];

  Track? get current =>
      _cursor < _order.length ? _original[_order[_cursor]] : null;

  /// 顺序模式下是列表中的下一首。
  /// 随机模式下只有「下一首播放」已指定曲目时才有值, 避免在点击之前就决定随机结果。
  Track? get nextTrack {
    if (_isShuffleMode(_mode)) {
      for (final original in _pinned) {
        if (original >= 0 && original < _original.length) {
          return _original[original];
        }
      }
      return null;
    }
    return _hasNext() ? _original[_order[_nextCursor()]] : null;
  }

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
      return _shuffleNext();
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
      if (_isShuffleMode(_mode)) {
        _history.add(_cursor);
        if (_cursor < _order.length) _played.add(_order[_cursor]);
      }
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

    final wasShuffle = _isShuffleMode(_mode);
    final currentTrack = current;
    _mode = newMode;
    final nowShuffle = _isShuffleMode(newMode);

    if (nowShuffle && !wasShuffle) {
      // 进入随机: 列表保持原顺序, 本轮从当前曲重新计
      _seed++;
      _history.clear();
      _played.clear();
    } else if (!nowShuffle && wasShuffle) {
      // 切换到顺序: 定位当前曲在 original 中的位置
      _order = List.generate(_original.length, (i) => i);
      if (currentTrack != null) {
        _cursor = _original.indexOf(currentTrack);
      }
      _history.clear();
      _played.clear();
      _pinned.clear();
    }
  }

  /// 添加到队尾。随机模式下它加入未播曲目, 等下一次点下一首时才可能被选中。
  void append(Track track) {
    _original.add(track);
    _order.add(_original.length - 1);
  }

  /// 插入到下一首。随机模式下这次插入优先于随机选择。
  void insertNext(Track track) {
    _original.add(track);
    final newIndex = _original.length - 1;
    _order.insert(_cursor + 1, newIndex);
    _pinned.insert(0, newIndex);
  }

  /// 移除 [tracks] 中的第 [index] 项。
  void removeAt(int index) {
    if (index < 0 || index >= _original.length) return;

    final removedPos = _order.indexOf(index);
    _original.removeAt(index);

    // 更新order: 移除该索引，并调整大于它的索引
    _order = _order
        .where((i) => i != index)
        .map((i) => i > index ? i - 1 : i)
        .toList();
    _remapAfterRemoval(index);

    // 历史记录中的位置失效，直接清空
    _history.clear();

    // 被移除项在光标之前: 光标前移，保持当前曲不变
    if (removedPos < _cursor) _cursor--;
    if (_cursor >= _order.length) {
      _cursor = max(0, _order.length - 1);
    }
  }

  /// 移除当前播放顺序中的第 [orderedIndex] 项。
  ///
  /// 与 [removeAt] 不同，这里的下标对应用户在队列里看到的位置，
  /// 因此「下一首播放」插进来的曲目、以及重复出现的同一首，都能对上。
  void removeOrderedAt(int orderedIndex) {
    if (orderedIndex < 0 || orderedIndex >= _order.length) return;
    removeAt(_order[orderedIndex]);
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
      _played.clear();
      _pinned.clear();
      return;
    }

    _original.clear();
    _original.add(currentTrack);
    _order = [0];
    _cursor = 0;
    _history.clear();
    _played.clear();
    _pinned.clear();
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
      'played': _played.toList(),
      'pinned': _pinned,
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
    final played = _intList(snapshot['played']);
    final pinned = _intList(snapshot['pinned']);

    if (_isShuffleMode(mode)) {
      // 旧快照里的 order 是预先打乱的结果。恢复时回到原列表顺序,
      // 光标和历史上的位置都换算成 original 下标。
      queue._order = List.generate(tracks.length, (i) => i);
      if (order.isNotEmpty && cursor >= 0 && cursor < order.length) {
        queue._cursor = order[cursor];
      }
      if (queue._cursor >= queue._order.length) queue._cursor = 0;
      for (final pos in history) {
        if (pos >= 0 && pos < order.length) queue._history.add(order[pos]);
      }
    } else {
      queue._order = order;
      queue._cursor = cursor;
      queue._history.addAll(history);
    }

    queue._played.addAll(played.where((i) => i >= 0 && i < tracks.length));
    queue._pinned.addAll(pinned.where((i) => i >= 0 && i < tracks.length));
    return queue;
  }

  static List<int> _intList(Object? value) {
    if (value is! List) return const [];
    return value.map((e) => (e as num).toInt()).toList();
  }

  bool _hasNext() => _cursor + 1 < _order.length;

  int _nextCursor() => _cursor + 1;

  static bool _isShuffleMode(PlayMode mode) =>
      mode == PlayMode.shuffle || mode == PlayMode.smartShuffle;

  /// 点下一首时才选歌。本轮未播过的曲目里均匀随机;
  /// 还有其他选择时, 不选原列表中紧挨着的下一首。
  /// 智能随机再优先换一个歌手。一轮播完后重开, 不立刻重播刚离开的那首。
  Track? _shuffleNext() {
    if (_cursor >= _order.length) return null;
    final leaving = _order[_cursor];

    final pinnedPos = _takePinned();
    if (pinnedPos != null) {
      _history.add(_cursor);
      _played.add(leaving);
      _cursor = pinnedPos;
      return current;
    }

    _played.add(leaving);
    var candidates = _candidatePositions(leaving);
    if (candidates.isEmpty && _order.length > 1) {
      _played
        ..clear()
        ..add(leaving);
      candidates = _candidatePositions(leaving);
    }
    if (candidates.isEmpty) return current;

    _history.add(_cursor);
    _seed++;
    _cursor = candidates[Random(_seed).nextInt(candidates.length)];
    return current;
  }

  int? _takePinned() {
    while (_pinned.isNotEmpty) {
      final original = _pinned.removeAt(0);
      final pos = _order.indexOf(original);
      if (pos >= 0 && pos != _cursor) return pos;
    }
    return null;
  }

  List<int> _candidatePositions(int leaving) {
    final positions = <int>[];
    for (var i = 0; i < _order.length; i++) {
      final original = _order[i];
      if (original == leaving || _played.contains(original)) continue;
      positions.add(i);
    }
    final preferred = _preferOtherArtists(positions);
    if (preferred.length <= 1) return preferred;
    final withoutSuccessor = preferred
        .where((i) => _order[i] != leaving + 1)
        .toList();
    return withoutSuccessor.isEmpty ? preferred : withoutSuccessor;
  }

  List<int> _preferOtherArtists(List<int> positions) {
    if (_mode != PlayMode.smartShuffle || positions.length <= 1) {
      return positions;
    }
    final artist = current?.artist;
    if (artist == null || artist.isEmpty) return positions;
    final others = positions.where((i) {
      return _original[_order[i]].artist != artist;
    }).toList();
    return others.isEmpty ? positions : others;
  }

  void _remapAfterRemoval(int index) {
    _played.remove(index);
    _played = _played.map((i) => i > index ? i - 1 : i).toSet();
    _pinned.removeWhere((i) => i == index);
    for (var i = 0; i < _pinned.length; i++) {
      if (_pinned[i] > index) _pinned[i]--;
    }
  }
}
