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

  group('PlaylistsDao', () {
    test('创建和查询歌单', () async {
      final id = await db.playlistsDao.createPlaylist(
        PlaylistsCompanion.insert(
          name: '我的歌单',
          cover: const Value('https://example.com/cover.jpg'),
        ),
      );

      expect(id, greaterThan(0));

      final playlist = await db.playlistsDao.getPlaylist(id);
      expect(playlist, matcher.isNotNull);
      expect(playlist!.name, '我的歌单');
      expect(playlist.cover, 'https://example.com/cover.jpg');
      expect(playlist.isReadonly, false);
    });

    test('更新歌单', () async {
      final id = await db.playlistsDao.createPlaylist(
        PlaylistsCompanion.insert(name: '原始名称'),
      );

      final updated = await db.playlistsDao.updatePlaylist(
        id,
        const PlaylistsCompanion(name: Value('新名称')),
      );

      expect(updated, true);

      final playlist = await db.playlistsDao.getPlaylist(id);
      expect(playlist!.name, '新名称');
    });

    test('删除歌单', () async {
      final id = await db.playlistsDao.createPlaylist(
        PlaylistsCompanion.insert(name: '待删除歌单'),
      );

      await db.playlistsDao.deletePlaylist(id);

      final playlist = await db.playlistsDao.getPlaylist(id);
      expect(playlist, matcher.isNull);
    });

    test('添加轨道到歌单', () async {
      // 先插入轨道
      await db.tracksDao.upsertTrack(
        TracksCompanion.insert(
          bvid: 'BV1',
          cid: 1,
          title: '歌曲1',
          duration: 200,
        ),
      );

      final playlistId = await db.playlistsDao.createPlaylist(
        PlaylistsCompanion.insert(name: '测试歌单'),
      );

      await db.playlistsDao.addTrackToPlaylist(
        playlistId: playlistId,
        bvid: 'BV1',
        cid: 1,
      );

      final tracks = await db.playlistsDao.getPlaylistTracks(playlistId);
      expect(tracks.length, 1);
      expect(tracks.first.bvid, 'BV1');
      expect(tracks.first.cid, 1);
    });

    test('添加多个轨道自动排序', () async {
      await db.tracksDao.upsertTracks([
        TracksCompanion.insert(bvid: 'BV1', cid: 1, title: '歌曲1', duration: 200),
        TracksCompanion.insert(bvid: 'BV2', cid: 2, title: '歌曲2', duration: 210),
        TracksCompanion.insert(bvid: 'BV3', cid: 3, title: '歌曲3', duration: 220),
      ]);

      final playlistId = await db.playlistsDao.createPlaylist(
        PlaylistsCompanion.insert(name: '测试歌单'),
      );

      await db.playlistsDao.addTracksToPlaylist(
        playlistId: playlistId,
        tracks: [
          (bvid: 'BV1', cid: 1),
          (bvid: 'BV2', cid: 2),
          (bvid: 'BV3', cid: 3),
        ],
      );

      final tracks = await db.playlistsDao.getPlaylistTracks(playlistId);
      expect(tracks.length, 3);
      expect(tracks[0].bvid, 'BV1');
      expect(tracks[1].bvid, 'BV2');
      expect(tracks[2].bvid, 'BV3');
    });

    test('移除轨道并重新排序', () async {
      await db.tracksDao.upsertTracks([
        TracksCompanion.insert(bvid: 'BV1', cid: 1, title: '歌曲1', duration: 200),
        TracksCompanion.insert(bvid: 'BV2', cid: 2, title: '歌曲2', duration: 210),
        TracksCompanion.insert(bvid: 'BV3', cid: 3, title: '歌曲3', duration: 220),
      ]);

      final playlistId = await db.playlistsDao.createPlaylist(
        PlaylistsCompanion.insert(name: '测试歌单'),
      );

      await db.playlistsDao.addTracksToPlaylist(
        playlistId: playlistId,
        tracks: [
          (bvid: 'BV1', cid: 1),
          (bvid: 'BV2', cid: 2),
          (bvid: 'BV3', cid: 3),
        ],
      );

      // 移除中间的轨道
      await db.playlistsDao.removeTrackFromPlaylist(
        playlistId: playlistId,
        bvid: 'BV2',
        cid: 2,
      );

      final tracks = await db.playlistsDao.getPlaylistTracks(playlistId);
      expect(tracks.length, 2);
      expect(tracks[0].bvid, 'BV1');
      expect(tracks[1].bvid, 'BV3');
    });

    test('调整轨道顺序', () async {
      await db.tracksDao.upsertTracks([
        TracksCompanion.insert(bvid: 'BV1', cid: 1, title: '歌曲1', duration: 200),
        TracksCompanion.insert(bvid: 'BV2', cid: 2, title: '歌曲2', duration: 210),
        TracksCompanion.insert(bvid: 'BV3', cid: 3, title: '歌曲3', duration: 220),
      ]);

      final playlistId = await db.playlistsDao.createPlaylist(
        PlaylistsCompanion.insert(name: '测试歌单'),
      );

      await db.playlistsDao.addTracksToPlaylist(
        playlistId: playlistId,
        tracks: [
          (bvid: 'BV1', cid: 1),
          (bvid: 'BV2', cid: 2),
          (bvid: 'BV3', cid: 3),
        ],
      );

      // 重新排序: BV3, BV1, BV2
      await db.playlistsDao.reorderTracks(
        playlistId: playlistId,
        newOrder: [
          (bvid: 'BV3', cid: 3),
          (bvid: 'BV1', cid: 1),
          (bvid: 'BV2', cid: 2),
        ],
      );

      final tracks = await db.playlistsDao.getPlaylistTracks(playlistId);
      expect(tracks[0].bvid, 'BV3');
      expect(tracks[1].bvid, 'BV1');
      expect(tracks[2].bvid, 'BV2');
    });

    test('检查轨道是否在歌单中', () async {
      await db.tracksDao.upsertTrack(
        TracksCompanion.insert(bvid: 'BV1', cid: 1, title: '歌曲1', duration: 200),
      );

      final playlistId = await db.playlistsDao.createPlaylist(
        PlaylistsCompanion.insert(name: '测试歌单'),
      );

      await db.playlistsDao.addTrackToPlaylist(
        playlistId: playlistId,
        bvid: 'BV1',
        cid: 1,
      );

      final exists = await db.playlistsDao.isTrackInPlaylist(
        playlistId: playlistId,
        bvid: 'BV1',
        cid: 1,
      );
      expect(exists, true);

      final notExists = await db.playlistsDao.isTrackInPlaylist(
        playlistId: playlistId,
        bvid: 'BV999',
        cid: 999,
      );
      expect(notExists, false);
    });

    test('获取歌单轨道数量', () async {
      await db.tracksDao.upsertTracks([
        TracksCompanion.insert(bvid: 'BV1', cid: 1, title: '歌曲1', duration: 200),
        TracksCompanion.insert(bvid: 'BV2', cid: 2, title: '歌曲2', duration: 210),
      ]);

      final playlistId = await db.playlistsDao.createPlaylist(
        PlaylistsCompanion.insert(name: '测试歌单'),
      );

      await db.playlistsDao.addTracksToPlaylist(
        playlistId: playlistId,
        tracks: [
          (bvid: 'BV1', cid: 1),
          (bvid: 'BV2', cid: 2),
        ],
      );

      final count = await db.playlistsDao.getPlaylistTrackCount(playlistId);
      expect(count, 2);
    });

    test('级联删除: 删除歌单时删除关联轨道', () async {
      await db.tracksDao.upsertTrack(
        TracksCompanion.insert(bvid: 'BV1', cid: 1, title: '歌曲1', duration: 200),
      );

      final playlistId = await db.playlistsDao.createPlaylist(
        PlaylistsCompanion.insert(name: '测试歌单'),
      );

      await db.playlistsDao.addTrackToPlaylist(
        playlistId: playlistId,
        bvid: 'BV1',
        cid: 1,
      );

      await db.playlistsDao.deletePlaylist(playlistId);

      final tracks = await db.playlistsDao.getPlaylistTracks(playlistId);
      expect(tracks.length, 0);
    });
  });
}
