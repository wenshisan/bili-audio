import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:matcher/matcher.dart' as matcher;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('CacheDao', () {
    test('插入并查询缓存条目', () async {
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV1_1_30232',
          filePath: 'audio/BV1_1_30232.m4a',
          fileSize: 5242880,
          complete: const Value(true),
          downloadedBytes: const Value(5242880),
        ),
      );

      final entry = await db.cacheDao.getCacheEntry('BV1_1_30232');
      expect(entry, matcher.isNotNull);
      expect(entry!.cacheKey, 'BV1_1_30232');
      expect(entry.fileSize, 5242880);
      expect(entry.complete, true);
      expect(entry.pinned, false);
    });

    test('更新下载进度', () async {
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV1_1_30232',
          filePath: 'audio/BV1_1_30232.m4a',
          fileSize: 10000000,
        ),
      );

      await db.cacheDao.updateDownloadProgress(
        cacheKey: 'BV1_1_30232',
        downloadedBytes: 5000000,
        complete: false,
      );

      final entry = await db.cacheDao.getCacheEntry('BV1_1_30232');
      expect(entry!.downloadedBytes, 5000000);
      expect(entry.complete, false);

      await db.cacheDao.updateDownloadProgress(
        cacheKey: 'BV1_1_30232',
        downloadedBytes: 10000000,
        complete: true,
      );

      final entry2 = await db.cacheDao.getCacheEntry('BV1_1_30232');
      expect(entry2!.downloadedBytes, 10000000);
      expect(entry2.complete, true);
    });

    test('更新最后播放时间', () async {
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV1_1_30232',
          filePath: 'audio/BV1_1_30232.m4a',
          fileSize: 5000000,
        ),
      );

      final before = await db.cacheDao.getCacheEntry('BV1_1_30232');
      expect(before!.lastPlayedAt, matcher.isNull);

      await db.cacheDao.updateLastPlayed('BV1_1_30232');

      final after = await db.cacheDao.getCacheEntry('BV1_1_30232');
      expect(after!.lastPlayedAt, matcher.isNotNull);
    });

    test('设置 pinned 状态', () async {
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV1_1_30232',
          filePath: 'audio/BV1_1_30232.m4a',
          fileSize: 5000000,
        ),
      );

      await db.cacheDao.setPinned('BV1_1_30232', true);

      final entry = await db.cacheDao.getCacheEntry('BV1_1_30232');
      expect(entry!.pinned, true);
    });

    test('批量设置 pinned', () async {
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV1_1_30232',
          filePath: 'audio/BV1_1_30232.m4a',
          fileSize: 5000000,
        ),
      );
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV2_2_30232',
          filePath: 'audio/BV2_2_30232.m4a',
          fileSize: 6000000,
        ),
      );

      await db.cacheDao.setPinnedBatch(['BV1_1_30232', 'BV2_2_30232'], true);

      final entry1 = await db.cacheDao.getCacheEntry('BV1_1_30232');
      final entry2 = await db.cacheDao.getCacheEntry('BV2_2_30232');
      expect(entry1!.pinned, true);
      expect(entry2!.pinned, true);
    });

    test('获取总缓存大小', () async {
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV1_1_30232',
          filePath: 'audio/BV1_1_30232.m4a',
          fileSize: 5000000,
        ),
      );
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV2_2_30232',
          filePath: 'audio/BV2_2_30232.m4a',
          fileSize: 3000000,
        ),
      );

      final totalSize = await db.cacheDao.getTotalCacheSize();
      expect(totalSize, 8000000);
    });

    test('获取未 pinned 的缓存条目', () async {
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV1_1_30232',
          filePath: 'audio/BV1_1_30232.m4a',
          fileSize: 5000000,
          pinned: const Value(true),
        ),
      );
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV2_2_30232',
          filePath: 'audio/BV2_2_30232.m4a',
          fileSize: 3000000,
        ),
      );

      final unpinned = await db.cacheDao.getUnpinnedEntries();
      expect(unpinned.length, 1);
      expect(unpinned.first.cacheKey, 'BV2_2_30232');
    });

    test('删除缓存条目', () async {
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV1_1_30232',
          filePath: 'audio/BV1_1_30232.m4a',
          fileSize: 5000000,
        ),
      );

      await db.cacheDao.deleteCacheEntry('BV1_1_30232');

      final entry = await db.cacheDao.getCacheEntry('BV1_1_30232');
      expect(entry, matcher.isNull);
    });

    test('清空未 pinned 缓存', () async {
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV1_1_30232',
          filePath: 'audio/BV1_1_30232.m4a',
          fileSize: 5000000,
          pinned: const Value(true),
        ),
      );
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV2_2_30232',
          filePath: 'audio/BV2_2_30232.m4a',
          fileSize: 3000000,
        ),
      );
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV3_3_30232',
          filePath: 'audio/BV3_3_30232.m4a',
          fileSize: 4000000,
        ),
      );

      await db.cacheDao.clearUnpinnedCache();

      final all = await db.cacheDao.getAllCacheEntries();
      expect(all.length, 1);
      expect(all.first.cacheKey, 'BV1_1_30232');
    });

    test('获取完整缓存数量', () async {
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV1_1_30232',
          filePath: 'audio/BV1_1_30232.m4a',
          fileSize: 5000000,
          complete: const Value(true),
        ),
      );
      await db.cacheDao.upsertCacheEntry(
        CacheIndexCompanion.insert(
          cacheKey: 'BV2_2_30232',
          filePath: 'audio/BV2_2_30232.m4a',
          fileSize: 3000000,
          complete: const Value(false),
        ),
      );

      final count = await db.cacheDao.getCompleteCacheCount();
      expect(count, 1);
    });
  });
}
