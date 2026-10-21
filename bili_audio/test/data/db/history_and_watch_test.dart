import 'package:bili_audio/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    for (final (bvid, cid) in [('BV1', 1), ('BV2', 2)]) {
      await db.tracksDao.ensureTrack(TracksCompanion.insert(
        bvid: bvid,
        cid: cid,
        title: 't$cid',
        duration: 200,
      ));
    }
  });

  tearDown(() => db.close());

  test('ensureTrack 不覆盖已存在的曲目', () async {
    await db.tracksDao.updateTrackByUser(
        bvid: 'BV1', cid: 1, cleanedName: '我的', artist: null);
    await db.tracksDao.ensureTrack(TracksCompanion.insert(
        bvid: 'BV1', cid: 1, title: 'other', duration: 1));
    final t = await db.tracksDao.getTrack('BV1', 1);
    expect(t!.title, 't1');
    expect(t.cleanedName, '我的');
  });

  test('历史: 记录、更新完成度、倒序、删除', () async {
    final a = await db.historyDao.start('BV1', 1, source: 'search');
    final b = await db.historyDao.start('BV2', 2);
    await db.historyDao.updateProgress(
        a, const Duration(seconds: 100), const Duration(seconds: 200));

    var list = await db.historyDao.watchRecent().first;
    expect(list.map((e) => e.track.bvid), ['BV2', 'BV1']);
    expect(list[1].history.completion, 0.5);
    expect(list[1].history.positionMs, 100000);

    await db.historyDao.remove(b);
    list = await db.historyDao.watchRecent().first;
    expect(list.single.track.bvid, 'BV1');

    await db.historyDao.clear();
    expect(await db.historyDao.watchRecent().first, isEmpty);
  });

  test('歌单列表带曲目数, 变化时推送', () async {
    final id = await db.playlistsDao
        .createPlaylist(PlaylistsCompanion.insert(name: 'A'));
    final stream = db.playlistsDao.watchPlaylistsWithCount();
    expect((await stream.first).single.count, 0);

    await db.playlistsDao.addTrackToPlaylist(playlistId: id, bvid: 'BV1', cid: 1);
    await db.playlistsDao.addTrackToPlaylist(playlistId: id, bvid: 'BV2', cid: 2);
    expect((await stream.first).single.count, 2);
    expect(
      (await db.playlistsDao.watchPlaylistTracks(id).first).map((t) => t.bvid),
      ['BV1', 'BV2'],
    );
  });
}
