import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/queue/playback_queue.dart';
import '../db/app_database.dart';

/// 队列快照持久化 (M3.4)
///
/// 写入单行 `queue_snapshot`; [scheduleSave] 500ms 防抖, 避免频繁写库。
class QueueSnapshotStore {
  QueueSnapshotStore(
    this._db, {
    this.debounce = const Duration(milliseconds: 500),
  });

  final AppDatabase _db;
  final Duration debounce;
  Timer? _timer;
  (PlaybackQueue, Duration)? _pending;

  void scheduleSave(PlaybackQueue queue, Duration position) {
    _pending = (queue, position);
    _timer?.cancel();
    _timer = Timer(debounce, flush);
  }

  Future<void> flush() async {
    _timer?.cancel();
    final p = _pending;
    _pending = null;
    if (p != null) await save(p.$1, p.$2);
  }

  Future<void> save(PlaybackQueue queue, Duration position) async {
    final s = queue.toSnapshot();
    await _db
        .into(_db.queueSnapshot)
        .insertOnConflictUpdate(
          QueueSnapshotCompanion.insert(
            id: const Value(1),
            originalQueue: jsonEncode(s['original']),
            currentOrder: jsonEncode(s['order']),
            cursor: s['cursor'] as int,
            mode: s['mode'] as String,
            seed: s['seed'] as int,
            // history 列同时带上本轮已播和下一条指定, 避免给旧库加列。
            history: jsonEncode({
              'cursors': s['history'],
              'played': s['played'],
              'pinned': s['pinned'],
            }),
            positionMs: Value(position.inMilliseconds),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// 读取快照; 不存在或损坏时返回 null
  Future<(PlaybackQueue, Duration)?> load() async {
    final row = await (_db.select(
      _db.queueSnapshot,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) return null;
    try {
      final historyRaw = jsonDecode(row.history);
      final snapshot = <String, dynamic>{
        'original': jsonDecode(row.originalQueue),
        'order': jsonDecode(row.currentOrder),
        'cursor': row.cursor,
        'mode': row.mode,
        'seed': row.seed,
      };
      if (historyRaw is Map) {
        snapshot['history'] = historyRaw['cursors'] ?? const [];
        snapshot['played'] = historyRaw['played'];
        snapshot['pinned'] = historyRaw['pinned'];
      } else {
        snapshot['history'] = historyRaw;
      }
      final queue = PlaybackQueue.fromSnapshot(snapshot);
      return (queue, Duration(milliseconds: row.positionMs));
    } catch (_) {
      return null;
    }
  }

  void dispose() => _timer?.cancel();
}
