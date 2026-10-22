import 'dart:io';

import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/data/player/media_library.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late BiliAudioHandler handler;

  setUp(() {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('browse_');
    handler = BiliAudioHandler(
      engine: FakeEngine(),
      streams: CountingStreamRepository(),
      downloads: CacheDownloadManager(
        AudioCacheStore(db, dir, limitBytes: () async => 1 << 30),
        Dio(),
      ),
    );
    handler.browseLibrary = MediaLibrary(db, () => handler.playbackQueue.orderedTracks);
  });

  tearDown(() async {
    await handler.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('根节点只有正在播放、歌单和最近播放', () async {
    final root = await handler.getChildren(MediaLibrary.root);
    expect(root.map((item) => item.id), [
      MediaLibrary.nowPlaying,
      MediaLibrary.playlists,
      MediaLibrary.recent,
    ]);
    expect(root.every((item) => item.playable == false), isTrue);
  });

  test('点播歌单后当前曲是歌单第一首', () async {
    await db.tracksDao.ensureTrack(
      TracksCompanion.insert(bvid: 'BV1', cid: 7, title: '晴天', duration: 200),
    );
    final id = await db.playlistsDao.createPlaylist(
      PlaylistsCompanion.insert(name: '通勤', source: const Value('local')),
    );
    await db.playlistsDao.addTrackToPlaylist(playlistId: id, bvid: 'BV1', cid: 7);

    final children = await handler.getChildren('playlist:$id');
    expect(children.single.title, '晴天');
    expect(children.single.playable, isTrue);

    await handler.playFromMediaId('playlist:$id');
    expect(handler.currentTrack?.bvid, 'BV1');
    expect(handler.currentTrack?.cid, 7);
  });
}
