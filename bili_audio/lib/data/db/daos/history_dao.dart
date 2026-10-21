import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'history_dao.g.dart';

/// 一条播放历史 + 对应曲目
typedef HistoryEntry = ({PlayHistoryData history, Track track});

/// 播放历史 (M6.5)
@DriftAccessor(tables: [PlayHistory, Tracks])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.db);

  /// 开始播放时插入一条记录, 返回 id 供后续更新进度
  ///
  /// 调用方需先确保 tracks 行存在 (外键约束)。
  Future<int> start(String bvid, int cid, {String? source}) =>
      into(playHistory).insert(PlayHistoryCompanion.insert(
        bvid: bvid,
        cid: cid,
        source: Value(source),
      ));

  Future<void> updateProgress(int id, Duration position, Duration duration) {
    final completion = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return (update(playHistory)..where((h) => h.id.equals(id))).write(
      PlayHistoryCompanion(
        positionMs: Value(position.inMilliseconds),
        completion: Value(completion),
      ),
    );
  }

  /// 按时间倒序, 每条附带曲目信息
  Stream<List<HistoryEntry>> watchRecent({int limit = 200}) {
    final query = select(playHistory).join([
      innerJoin(
        tracks,
        tracks.bvid.equalsExp(playHistory.bvid) &
            tracks.cid.equalsExp(playHistory.cid),
      ),
    ])
      // playedAt 精度为秒, 同一秒内按 id 区分先后
      ..orderBy([
        OrderingTerm.desc(playHistory.playedAt),
        OrderingTerm.desc(playHistory.id),
      ])
      ..limit(limit);
    return query.watch().map((rows) => [
          for (final r in rows)
            (history: r.readTable(playHistory), track: r.readTable(tracks)),
        ]);
  }

  Future<int> remove(int id) =>
      (delete(playHistory)..where((h) => h.id.equals(id))).go();

  Future<int> clear() => delete(playHistory).go();
}
