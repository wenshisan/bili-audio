import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;

import '../../domain/cache/lru_policy.dart';
import '../db/app_database.dart';

/// 音频缓存文件与索引 (M3.2)
///
/// 文件布局: `<dir>/<cacheKey>.audio` (完整) 与 `.audio.tmp` (下载中)。
/// 索引写入 `cache_index`, 路径存相对 [dir] 的文件名, 便于迁移缓存目录。
class AudioCacheStore {
  AudioCacheStore(
    this._db,
    this.dir, {
    required Future<int> Function() limitBytes,
    LruPolicy policy = const LruPolicy(),
    DateTime Function()? clock,
  })  : _limitBytes = limitBytes,
        _policy = policy,
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final Directory dir;
  final Future<int> Function() _limitBytes;
  final LruPolicy _policy;
  final DateTime Function() _clock;

  File completeFile(String key) => File(p.join(dir.path, '$key.audio'));
  File tmpFile(String key) => File(p.join(dir.path, '$key.audio.tmp'));

  /// 完整缓存命中时返回文件; 索引与文件不一致时修正索引
  Future<File?> completed(String key) async {
    final row = await _db.cacheDao.getCacheEntry(key);
    final file = completeFile(key);
    if (row != null && row.complete) {
      if (file.existsSync()) return file;
      await _db.cacheDao.deleteCacheEntry(key);
    }
    return null;
  }

  Future<void> recordPartial(String key, int downloaded, int total) =>
      _db.cacheDao.upsertCacheEntry(CacheIndexCompanion.insert(
        cacheKey: key,
        filePath: p.basename(tmpFile(key).path),
        fileSize: total,
        downloadedBytes: Value(downloaded.clamp(0, total)),
        complete: const Value(false),
      ));

  /// `.tmp` 改名为正式文件并标记完整
  Future<File> finalize(String key, int total) async {
    final file = await tmpFile(key).rename(completeFile(key).path);
    final existing = await _db.cacheDao.getCacheEntry(key);
    await _db.cacheDao.upsertCacheEntry(CacheIndexCompanion.insert(
      cacheKey: key,
      filePath: p.basename(file.path),
      fileSize: total,
      downloadedBytes: Value(total),
      complete: const Value(true),
      lastPlayedAt: Value(_clock()),
      pinned: Value(existing?.pinned ?? false),
    ));
    return file;
  }

  Future<void> touch(String key) => _db.cacheDao.updateLastPlayed(key);

  /// 为写入 [incoming] 字节腾出空间; 跳过 pinned 与 [protectedKeys]
  Future<EvictionResult> ensureSpace(
    int incoming, {
    Set<String> protectedKeys = const {},
  }) async {
    final rows = await _db.cacheDao.getAllCacheEntries();
    final result = _policy.evict(
      entries: [
        for (final r in rows)
          CacheEntry(
            key: r.cacheKey,
            size: r.fileSize,
            lastPlayedAt:
                (r.lastPlayedAt ?? r.cachedAt).millisecondsSinceEpoch ~/ 1000,
            pinned: r.pinned,
          ),
      ],
      limit: await _limitBytes(),
      incomingSize: incoming,
      protectedKeys: protectedKeys,
    );
    for (final e in result.toEvict) {
      for (final f in [completeFile(e.key), tmpFile(e.key)]) {
        if (f.existsSync()) await f.delete();
      }
      await _db.cacheDao.deleteCacheEntry(e.key);
    }
    return result;
  }
}
