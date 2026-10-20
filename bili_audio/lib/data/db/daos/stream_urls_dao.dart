import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'stream_urls_dao.g.dart';

/// StreamUrls DAO (M2.5)
@DriftAccessor(tables: [StreamUrls])
class StreamUrlsDao extends DatabaseAccessor<AppDatabase>
    with _$StreamUrlsDaoMixin {
  StreamUrlsDao(super.db);

  /// 获取流地址
  Future<StreamUrlRow?> getStreamUrl(String bvid, int cid, int quality) {
    return (select(streamUrls)
          ..where((t) =>
              t.bvid.equals(bvid) &
              t.cid.equals(cid) &
              t.quality.equals(quality)))
        .getSingleOrNull();
  }

  /// 插入或更新流地址
  Future<void> upsertStreamUrl(StreamUrlsCompanion entry) {
    return into(streamUrls).insertOnConflictUpdate(entry);
  }

  /// 删除过期流地址
  Future<int> deleteExpired(int nowTimestamp) {
    final now = DateTime.fromMillisecondsSinceEpoch(nowTimestamp * 1000);
    return (delete(streamUrls)..where((t) => t.expiresAt.isSmallerThanValue(now)))
        .go();
  }

  /// 删除指定 bvid 的所有流地址
  Future<int> deleteByBvid(String bvid) {
    return (delete(streamUrls)..where((t) => t.bvid.equals(bvid))).go();
  }
}
