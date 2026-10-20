import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'tracks_dao.g.dart';

@DriftAccessor(tables: [Tracks])
class TracksDao extends DatabaseAccessor<AppDatabase> with _$TracksDaoMixin {
  TracksDao(super.db);

  /// 根据 bvid 和 cid 查询轨道
  Future<Track?> getTrack(String bvid, int cid) {
    return (select(tracks)
          ..where((t) => t.bvid.equals(bvid) & t.cid.equals(cid)))
        .getSingleOrNull();
  }

  /// 批量查询轨道
  Future<List<Track>> getTracks(List<({String bvid, int cid})> keys) async {
    if (keys.isEmpty) return [];

    final results = <Track>[];
    for (final key in keys) {
      final track = await getTrack(key.bvid, key.cid);
      if (track != null) results.add(track);
    }
    return results;
  }

  /// 插入或更新轨道 (user_edited=true 的记录不覆盖清洗结果)
  Future<void> upsertTrack(TracksCompanion track) async {
    final existing = await getTrack(
      track.bvid.value,
      track.cid.value,
    );

    if (existing != null && existing.userEdited) {
      // 用户已编辑，只更新非清洗字段
      await (update(tracks)
            ..where((t) =>
                t.bvid.equals(track.bvid.value) &
                t.cid.equals(track.cid.value)))
          .write(TracksCompanion(
        duration: track.duration,
        cover: track.cover,
        uploader: track.uploader,
        pageIndex: track.pageIndex,
        totalPages: track.totalPages,
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      // 新记录或未编辑，完整插入/更新
      await into(tracks).insertOnConflictUpdate(
        track.copyWith(updatedAt: Value(DateTime.now())),
      );
    }
  }

  /// 批量插入或更新
  Future<void> upsertTracks(List<TracksCompanion> trackList) async {
    for (final track in trackList) {
      await upsertTrack(track);
    }
  }

  /// 更新清洗结果 (仅当 user_edited=false)
  Future<bool> updateCleanedTitle({
    required String bvid,
    required int cid,
    required String? cleanedName,
    required String? artist,
  }) async {
    final existing = await getTrack(bvid, cid);
    if (existing == null || existing.userEdited) {
      return false;
    }

    await (update(tracks)
          ..where((t) => t.bvid.equals(bvid) & t.cid.equals(cid)))
        .write(TracksCompanion(
      cleanedName: Value(cleanedName),
      artist: Value(artist),
      updatedAt: Value(DateTime.now()),
    ));
    return true;
  }

  /// 用户手动编辑歌名/歌手
  Future<void> updateTrackByUser({
    required String bvid,
    required int cid,
    required String? cleanedName,
    required String? artist,
  }) async {
    await (update(tracks)
          ..where((t) => t.bvid.equals(bvid) & t.cid.equals(cid)))
        .write(TracksCompanion(
      cleanedName: Value(cleanedName),
      artist: Value(artist),
      userEdited: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 删除轨道
  Future<int> deleteTrack(String bvid, int cid) {
    return (delete(tracks)
          ..where((t) => t.bvid.equals(bvid) & t.cid.equals(cid)))
        .go();
  }

  /// 搜索轨道 (按清洗后的名称或歌手)
  Future<List<Track>> searchTracks(String query) {
    final pattern = '%$query%';
    return (select(tracks)
          ..where((t) =>
              t.cleanedName.like(pattern) |
              t.artist.like(pattern) |
              t.title.like(pattern))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(50))
        .get();
  }
}
