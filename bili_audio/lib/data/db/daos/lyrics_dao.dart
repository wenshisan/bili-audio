import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'lyrics_dao.g.dart';

/// 歌词缓存索引 (M5.3)
@DriftAccessor(tables: [LyricsCache])
class LyricsDao extends DatabaseAccessor<AppDatabase> with _$LyricsDaoMixin {
  LyricsDao(super.db);

  Future<LyricsCacheData?> get(String bvid, int cid) => (select(lyricsCache)
        ..where((l) => l.bvid.equals(bvid) & l.cid.equals(cid)))
      .getSingleOrNull();

  /// 记录匹配结果; 保留已有的用户偏移量
  Future<void> saveMatch({
    required String bvid,
    required int cid,
    required String lrcPath,
    required String source,
    double? score,
  }) async {
    final existing = await get(bvid, cid);
    await into(lyricsCache).insertOnConflictUpdate(LyricsCacheCompanion.insert(
      bvid: bvid,
      cid: cid,
      lrcPath: Value(lrcPath),
      source: Value(source),
      matchScore: Value(score),
      offsetMs: Value(existing?.offsetMs ?? 0),
      noLyrics: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 标记为无歌词, 下次不再搜索
  Future<void> markNoLyrics(String bvid, int cid) =>
      into(lyricsCache).insertOnConflictUpdate(LyricsCacheCompanion.insert(
        bvid: bvid,
        cid: cid,
        lrcPath: const Value(null),
        noLyrics: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

  /// 调整偏移量 (累加), 返回新值
  Future<int> adjustOffset(String bvid, int cid, Duration delta) async {
    final existing = await get(bvid, cid);
    final next = (existing?.offsetMs ?? 0) + delta.inMilliseconds;
    await into(lyricsCache).insertOnConflictUpdate(LyricsCacheCompanion.insert(
      bvid: bvid,
      cid: cid,
      lrcPath: Value(existing?.lrcPath),
      source: Value(existing?.source),
      matchScore: Value(existing?.matchScore),
      noLyrics: Value(existing?.noLyrics ?? false),
      offsetMs: Value(next),
      updatedAt: Value(DateTime.now()),
    ));
    return next;
  }

  /// 清除缓存 (编辑歌名后重新匹配)
  Future<int> clear(String bvid, int cid) => (delete(lyricsCache)
        ..where((l) => l.bvid.equals(bvid) & l.cid.equals(cid)))
      .go();
}
