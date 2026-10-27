import 'dart:io';

import 'package:bili_audio/app/providers.dart';
import 'package:bili_audio/core/utils/result.dart';
import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/bili/models/search_result.dart';
import 'package:bili_audio/data/db/app_database.dart' hide Track;
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/data/repositories/repositories.dart';
import 'package:bili_audio/domain/entities/app_error.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';
import 'package:bili_audio/domain/title/title_rule.dart';
import 'package:bili_audio/features/player/player_actions.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/player/fakes.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late FakeEngine engine;
  late BiliAudioHandler handler;
  late _VideoRepo videos;

  setUp(() async {
    db = AppDatabase.memory();
    dir = await Directory.systemTemp.createTemp('actions_');
    engine = FakeEngine();
    videos = _VideoRepo();
    handler = BiliAudioHandler(
      engine: engine,
      streams: CountingStreamRepository(),
      downloads: CacheDownloadManager(
        AudioCacheStore(db, dir, limitBytes: () async => 1 << 30),
        Dio(),
      ),
    );
  });

  tearDown(() async {
    await handler.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  PlayerActions actions() {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        videoRepositoryProvider.overrideWithValue(videos),
        audioHandlerProvider.overrideWithValue(handler),
      ],
    );
    addTearDown(container.dispose);
    return container.read(playerActionsProvider);
  }

  test('搜索结果有 cid 时直接开播，并把当前列表放进队列', () async {
    final hits = [
      _hit(bvid: 'BVa', cid: null, name: '没有分P'),
      _hit(bvid: 'BVb', cid: 11, name: '七里香', artist: '周杰伦'),
      _hit(bvid: 'BVc', cid: 22, name: '搁浅', duration: 0),
      _hit(bvid: 'BVd', cid: 33, name: '晴天', pageIndex: 3, totalPages: 8),
    ];

    final result = await actions().playSearchResults(hits, 1);

    expect(result.isSuccess, true);
    expect(videos.requested, ['BVa']);
    expect(handler.currentTrack?.bvid, 'BVb');
    expect(handler.currentTrack?.cid, 11);
    expect(handler.currentTrack?.cleanedName, '七里香');
    expect(handler.currentTrack?.artist, '周杰伦');
    expect(handler.currentTrack?.uploader, 'UP');
    expect(handler.playbackQueue.cursor, 0);
    expect(handler.playbackQueue.tracks.map((t) => t.bvid), ['BVb', 'BVd']);
    expect(handler.playbackQueue.tracks.last.pageIndex, 3);
    expect(engine.playing, true);
  });

  test('没有 cid 的结果整表进队列，补齐时不重头播放', () async {
    videos.delay = const Duration(milliseconds: 20);
    for (final (bvid, cid, name) in [
      ('BVa', 1, '一'),
      ('BVb', 2, '二'),
      ('BVc', 3, '三'),
    ]) {
      videos.tracks[bvid] = [
        Track(
          bvid: bvid,
          cid: cid,
          title: name,
          duration: const Duration(seconds: 180),
        ),
      ];
    }

    final result = await actions().playSearchResults([
      _hit(bvid: 'BVa', cid: null, name: '一'),
      _hit(bvid: 'BVb', cid: null, name: '二'),
      _hit(bvid: 'BVc', cid: null, name: '三'),
    ], 1);

    expect(result.isSuccess, true);
    expect(videos.calls, 3);
    expect(handler.playbackQueue.tracks.map((t) => t.bvid), [
      'BVa',
      'BVb',
      'BVc',
    ]);
    expect(handler.currentTrack?.bvid, 'BVb');
    expect(handler.playbackQueue.cursor, 1);
    expect(engine.sources.length, 1);
    expect(engine.playing, true);
  });

  test('点中的结果没有 cid 时才请求视频详情', () async {
    videos.tracks['BVx'] = [
      const Track(
        bvid: 'BVx',
        cid: 9,
        title: '详情曲',
        duration: Duration(seconds: 10),
      ),
    ];

    final result = await actions().playSearchResults([
      _hit(bvid: 'BVx', cid: null, name: '详情曲'),
    ], 0);

    expect(result.isSuccess, true);
    expect(videos.calls, 1);
    expect(handler.currentTrack?.cid, 9);
  });

  test('播放时沿用用户改过的歌名', () async {
    await db.tracksDao.upsertTrack(
      TracksCompanion.insert(
        bvid: 'BVb',
        cid: 11,
        title: '原始',
        duration: 200,
        cleanedName: const Value('搜索名'),
        artist: const Value('搜索歌手'),
      ),
    );
    await db.tracksDao.updateTrackByUser(
      bvid: 'BVb',
      cid: 11,
      cleanedName: '我的歌名',
      artist: '我的歌手',
    );

    await actions().playSearchResults([
      _hit(bvid: 'BVb', cid: 11, name: '搜索名', artist: '搜索歌手'),
    ], 0);

    expect(handler.currentTrack?.cleanedName, '我的歌名');
    expect(handler.currentTrack?.artist, '我的歌手');
    expect(videos.calls, 0);
  });

  test('下一首播放有 cid 时不请求视频详情', () async {
    await actions().playSearchResults([
      _hit(bvid: 'BVb', cid: 11, name: '七里香'),
    ], 0);
    final result = await actions().enqueueSearchHit(
      _hit(bvid: 'BVd', cid: 33, name: '晴天'),
      next: true,
    );

    expect(result.isSuccess, true);
    expect(videos.calls, 0);
    expect(handler.playbackQueue.tracks.map((t) => t.cid), [11, 33]);
  });

  test('搜索封面的协议相对地址补成 https', () {
    final track = trackFromSearchHit(
      _hit(bvid: 'BVb', cid: 11, name: '七里香', cover: '//i0.hdslb.com/a.jpg'),
    );
    expect(track?.cover, 'https://i0.hdslb.com/a.jpg');
  });
}

SearchHit _hit({
  required String bvid,
  required int? cid,
  required String name,
  String? artist = '歌手',
  int duration = 180,
  int? pageIndex,
  int? totalPages,
  String cover = 'https://example.com/c.jpg',
}) => (
  result: SearchResult(
    bvid: bvid,
    title: name,
    cleanTitle: name,
    duration: duration,
    cover: cover,
    author: 'UP',
    play: 10,
    cid: cid,
    pageIndex: pageIndex,
    totalPages: totalPages,
  ),
  cleaned: CleanedTitle(name: name, artist: artist),
);

class _VideoRepo implements VideoRepository {
  final tracks = <String, List<Track>>{};
  final requested = <String>[];
  var calls = 0;
  Duration delay = Duration.zero;

  @override
  Future<Result<List<Track>>> getTracks(String bvid) async {
    calls++;
    requested.add(bvid);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final list = tracks[bvid];
    if (list == null) return const Result.failure(AppError.notFound());
    return Result.success(list);
  }
}
