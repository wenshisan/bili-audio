import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'playlists_dao.g.dart';

@DriftAccessor(tables: [Playlists, PlaylistTracks, Tracks])
class PlaylistsDao extends DatabaseAccessor<AppDatabase>
    with _$PlaylistsDaoMixin {
  PlaylistsDao(super.db);

  /// 获取所有歌单
  Future<List<Playlist>> getAllPlaylists() {
    return (select(playlists)
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .get();
  }

  /// 获取单个歌单
  Future<Playlist?> getPlaylist(int id) {
    return (select(playlists)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// 创建歌单
  Future<int> createPlaylist(PlaylistsCompanion playlist) {
    return into(playlists).insert(playlist);
  }

  /// 更新歌单
  Future<bool> updatePlaylist(int id, PlaylistsCompanion playlist) async {
    final count = await (update(playlists)..where((p) => p.id.equals(id)))
        .write(playlist.copyWith(updatedAt: Value(DateTime.now())));
    return count > 0;
  }

  /// 删除歌单
  Future<int> deletePlaylist(int id) {
    return (delete(playlists)..where((p) => p.id.equals(id))).go();
  }

  /// 获取歌单内的所有轨道 (按 position 排序)
  Future<List<Track>> getPlaylistTracks(int playlistId) async {
    final query = select(playlistTracks).join([
      innerJoin(
        tracks,
        tracks.bvid.equalsExp(playlistTracks.bvid) &
            tracks.cid.equalsExp(playlistTracks.cid),
      ),
    ])
      ..where(playlistTracks.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(playlistTracks.position)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(tracks)).toList();
  }

  /// 添加轨道到歌单
  Future<void> addTrackToPlaylist({
    required int playlistId,
    required String bvid,
    required int cid,
  }) async {
    // 获取当前最大 position
    final maxPos = await (selectOnly(playlistTracks)
          ..addColumns([playlistTracks.position.max()])
          ..where(playlistTracks.playlistId.equals(playlistId)))
        .map((row) => row.read(playlistTracks.position.max()))
        .getSingleOrNull();

    final nextPosition = (maxPos ?? -1) + 1;

    await into(playlistTracks).insert(
      PlaylistTracksCompanion.insert(
        playlistId: playlistId,
        bvid: bvid,
        cid: cid,
        position: nextPosition,
      ),
      mode: InsertMode.insertOrIgnore,
    );

    // 更新歌单更新时间
    await (update(playlists)..where((p) => p.id.equals(playlistId)))
        .write(PlaylistsCompanion(updatedAt: Value(DateTime.now())));
  }

  /// 批量添加轨道到歌单
  Future<void> addTracksToPlaylist({
    required int playlistId,
    required List<({String bvid, int cid})> tracks,
  }) async {
    for (final track in tracks) {
      await addTrackToPlaylist(
        playlistId: playlistId,
        bvid: track.bvid,
        cid: track.cid,
      );
    }
  }

  /// 从歌单中移除轨道
  Future<int> removeTrackFromPlaylist({
    required int playlistId,
    required String bvid,
    required int cid,
  }) async {
    final result = await (delete(playlistTracks)
          ..where((pt) =>
              pt.playlistId.equals(playlistId) &
              pt.bvid.equals(bvid) &
              pt.cid.equals(cid)))
        .go();

    // 重新排列 position
    await _reorderPositions(playlistId);

    return result;
  }

  /// 调整歌单内轨道顺序
  Future<void> reorderTracks({
    required int playlistId,
    required List<({String bvid, int cid})> newOrder,
  }) async {
    await transaction(() async {
      for (var i = 0; i < newOrder.length; i++) {
        final track = newOrder[i];
        await (update(playlistTracks)
              ..where((pt) =>
                  pt.playlistId.equals(playlistId) &
                  pt.bvid.equals(track.bvid) &
                  pt.cid.equals(track.cid)))
            .write(PlaylistTracksCompanion(position: Value(i)));
      }
    });

    await (update(playlists)..where((p) => p.id.equals(playlistId)))
        .write(PlaylistsCompanion(updatedAt: Value(DateTime.now())));
  }

  /// 重新排列 position (移除后补齐)
  Future<void> _reorderPositions(int playlistId) async {
    final entries = await (select(playlistTracks)
          ..where((pt) => pt.playlistId.equals(playlistId))
          ..orderBy([(pt) => OrderingTerm.asc(pt.position)]))
        .get();

    await transaction(() async {
      for (var i = 0; i < entries.length; i++) {
        if (entries[i].position != i) {
          await (update(playlistTracks)
                ..where((pt) =>
                    pt.playlistId.equals(entries[i].playlistId) &
                    pt.bvid.equals(entries[i].bvid) &
                    pt.cid.equals(entries[i].cid)))
              .write(PlaylistTracksCompanion(position: Value(i)));
        }
      }
    });
  }

  /// 检查轨道是否在歌单中
  Future<bool> isTrackInPlaylist({
    required int playlistId,
    required String bvid,
    required int cid,
  }) async {
    final count = await (selectOnly(playlistTracks)
          ..addColumns([playlistTracks.playlistId.count()])
          ..where(
            playlistTracks.playlistId.equals(playlistId) &
                playlistTracks.bvid.equals(bvid) &
                playlistTracks.cid.equals(cid),
          ))
        .map((row) => row.read(playlistTracks.playlistId.count()) ?? 0)
        .getSingle();
    return count > 0;
  }

  /// 获取歌单轨道数量
  Future<int> getPlaylistTrackCount(int playlistId) async {
    final count = await (selectOnly(playlistTracks)
          ..addColumns([playlistTracks.playlistId.count()])
          ..where(playlistTracks.playlistId.equals(playlistId)))
        .map((row) => row.read(playlistTracks.playlistId.count()) ?? 0)
        .getSingle();
    return count;
  }
}
