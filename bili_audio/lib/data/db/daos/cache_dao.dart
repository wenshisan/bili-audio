import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'cache_dao.g.dart';

@DriftAccessor(tables: [CacheIndex])
class CacheDao extends DatabaseAccessor<AppDatabase> with _$CacheDaoMixin {
  CacheDao(super.db);

  /// 获取缓存条目
  Future<CacheIndexData?> getCacheEntry(String cacheKey) {
    return (select(cacheIndex)..where((c) => c.cacheKey.equals(cacheKey)))
        .getSingleOrNull();
  }

  /// 插入或更新缓存条目
  Future<void> upsertCacheEntry(CacheIndexCompanion entry) async {
    await into(cacheIndex).insertOnConflictUpdate(entry);
  }

  /// 更新下载进度
  Future<void> updateDownloadProgress({
    required String cacheKey,
    required int downloadedBytes,
    required bool complete,
  }) async {
    await (update(cacheIndex)..where((c) => c.cacheKey.equals(cacheKey)))
        .write(CacheIndexCompanion(
      downloadedBytes: Value(downloadedBytes),
      complete: Value(complete),
    ));
  }

  /// 更新最后播放时间
  Future<void> updateLastPlayed(String cacheKey) async {
    await (update(cacheIndex)..where((c) => c.cacheKey.equals(cacheKey)))
        .write(CacheIndexCompanion(lastPlayedAt: Value(DateTime.now())));
  }

  /// 设置 pinned 状态
  Future<void> setPinned(String cacheKey, bool pinned) async {
    await (update(cacheIndex)..where((c) => c.cacheKey.equals(cacheKey)))
        .write(CacheIndexCompanion(pinned: Value(pinned)));
  }

  /// 批量设置 pinned 状态
  Future<void> setPinnedBatch(List<String> cacheKeys, bool pinned) async {
    await transaction(() async {
      for (final key in cacheKeys) {
        await setPinned(key, pinned);
      }
    });
  }

  /// 获取总缓存大小
  Future<int> getTotalCacheSize() async {
    final result = await (selectOnly(cacheIndex)
          ..addColumns([cacheIndex.fileSize.sum()]))
        .map((row) => row.read(cacheIndex.fileSize.sum()) ?? 0)
        .getSingle();
    return result;
  }

  /// 获取所有缓存条目 (用于 LRU 策略)
  Future<List<CacheIndexData>> getAllCacheEntries() {
    return select(cacheIndex).get();
  }

  /// 获取未 pinned 的缓存条目 (按最后播放时间排序)
  Future<List<CacheIndexData>> getUnpinnedEntries() {
    return (select(cacheIndex)
          ..where((c) => c.pinned.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.lastPlayedAt)]))
        .get();
  }

  /// 删除缓存条目
  Future<int> deleteCacheEntry(String cacheKey) {
    return (delete(cacheIndex)..where((c) => c.cacheKey.equals(cacheKey))).go();
  }

  /// 批量删除缓存条目
  Future<void> deleteCacheEntries(List<String> cacheKeys) async {
    await transaction(() async {
      for (final key in cacheKeys) {
        await deleteCacheEntry(key);
      }
    });
  }

  /// 清空所有未 pinned 的缓存
  Future<int> clearUnpinnedCache() {
    return (delete(cacheIndex)..where((c) => c.pinned.equals(false))).go();
  }

  /// 获取完整缓存条目数量
  Future<int> getCompleteCacheCount() async {
    final result = await (selectOnly(cacheIndex)
          ..addColumns([cacheIndex.cacheKey.count()])
          ..where(cacheIndex.complete.equals(true)))
        .map((row) => row.read(cacheIndex.cacheKey.count()) ?? 0)
        .getSingle();
    return result;
  }
}
