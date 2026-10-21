import 'dart:io';

import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/audio/caching_stream_audio_source.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/data/player/queue_snapshot_store.dart';
import 'package:bili_audio/domain/entities/app_error.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';
import 'package:bili_audio/domain/queue/playback_queue.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late FakeEngine engine;
  late CountingStreamRepository streams;
  late CacheDownloadManager downloads;
  late QueueSnapshotStore snapshots;
  late BiliAudioHandler handler;

  BiliAudioHandler build() => BiliAudioHandler(
        engine: engine,
        streams: streams,
        downloads: downloads,
        snapshots: snapshots,
      );

  setUp(() async {
    db = AppDatabase.memory();
    dir = await Directory.systemTemp.createTemp('handler_');
    engine = FakeEngine();
    streams = CountingStreamRepository();
    final store = AudioCacheStore(db, dir, limitBytes: () async => 1 << 30);
    downloads = CacheDownloadManager(store, Dio());
    snapshots = QueueSnapshotStore(db, debounce: Duration.zero);
    handler = build();
  });

  tearDown(() async {
    await handler.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  String loadedKey() =>
      (engine.sources.last as CachingStreamAudioSource).cacheKey;

  test('setTracks 从指定位置开始播放并发布 MediaItem', () async {
    await handler.setTracks(makeTracks(5), startIndex: 2);

    expect(loadedKey(), 'BV2_2_30232');
    expect(engine.playing, true);
    expect(handler.mediaItem.value!.title, 'T2');
    expect(handler.queue.value.length, 5);
  });

  test('只加载当前曲, 并预解析下一首流地址', () async {
    await handler.setTracks(makeTracks(3));
    await Future<void>.delayed(Duration.zero);
    expect(engine.sources.length, 1);
    expect(streams.resolved, ['BV1']); // 当前曲地址懒加载, 下一首预解析
  });

  test('下一首已完整缓存时不预解析 (0 网络请求)', () async {
    final key = makeTracks(2)[1].cacheKey(AudioQuality.k132);
    await downloads.store.tmpFile(key).writeAsBytes([1, 2, 3]);
    await downloads.store.finalize(key, 3);

    await handler.setTracks(makeTracks(2));
    await Future<void>.delayed(Duration.zero);
    expect(streams.resolved, isEmpty);
  });

  test('播放结束自动下一首; 顺序模式到末尾暂停并回到开头', () async {
    await handler.setTracks(makeTracks(2));
    await engine.complete();
    expect(loadedKey(), 'BV1_1_30232');

    await engine.complete();
    expect(engine.sources.length, 2);
    expect(engine.playing, false);
    expect(engine.position, Duration.zero);
  });

  test('单曲循环: 结束后重播当前曲; 手动下一首仍前进', () async {
    await handler.setTracks(makeTracks(3));
    handler.setPlayMode(PlayMode.singleLoop);
    await engine.complete();
    expect(engine.sources.length, 1);
    expect(engine.playing, true);

    await handler.skipToNext();
    expect(loadedKey(), 'BV1_1_30232');
    expect(handler.playbackQueue.mode, PlayMode.singleLoop);
  });

  test('上一曲: 播放超过 3 秒时回到开头, 否则切到上一首', () async {
    await handler.setTracks(makeTracks(3), startIndex: 1);
    engine.position = const Duration(seconds: 10);
    await handler.skipToPrevious();
    expect(engine.sources.length, 1);
    expect(engine.position, Duration.zero);

    await handler.skipToPrevious();
    expect(loadedKey(), 'BV0_0_30232');
  });

  test('随机 20 首: "上一曲"按实际播放路径回退', () async {
    await handler.setTracks(makeTracks(20));
    handler.setPlayMode(PlayMode.shuffle);
    final played = [handler.currentTrack];
    for (var i = 0; i < 5; i++) {
      await handler.skipToNext();
      played.add(handler.currentTrack);
    }
    for (var i = played.length - 2; i >= 0; i--) {
      await handler.skipToPrevious();
      expect(handler.currentTrack, played[i]);
    }
  });

  test('删除当前曲时自动加载新的当前曲', () async {
    await handler.setTracks(makeTracks(3));
    await handler.removeAt(0);
    expect(loadedKey(), 'BV1_1_30232');
    expect(handler.queue.value.length, 2);
  });

  test('流地址失败时通过 errors 通知 UI', () async {
    engine.requestOnLoad = true;
    streams.failWith = const AppError.needLogin();
    final errors = <AppError>[];
    handler.errors.listen(errors.add);

    await handler.setTracks(makeTracks(1));
    await Future<void>.delayed(Duration.zero);
    expect(errors.single, isA<NeedLoginError>());
  });

  test('重启后恢复队列、模式与位置, 且不自动播放', () async {
    await handler.setTracks(makeTracks(4), startIndex: 2);
    handler.setPlayMode(PlayMode.listLoop);
    engine.position = const Duration(seconds: 42);
    await handler.pause();
    await snapshots.flush();
    await handler.dispose();

    engine = FakeEngine();
    snapshots = QueueSnapshotStore(db, debounce: Duration.zero);
    handler = build();
    expect(await handler.restore(), true);

    expect(handler.currentTrack!.bvid, 'BV2');
    expect(handler.playbackQueue.mode, PlayMode.listLoop);
    expect(engine.positions.single, const Duration(seconds: 42));
    expect(engine.playing, false);
  });

  test('播放历史: 每首开始播放记录一次, 切歌前写入上一首进度; 恢复不计入', () async {
    final log = <String>[];
    await handler.dispose();
    handler = BiliAudioHandler(
      engine: engine,
      streams: streams,
      downloads: downloads,
      snapshots: snapshots,
      recorder: (t) async {
        log.add('start ${t.bvid}');
        return (p) => log.add('${t.bvid}@${p.inSeconds}');
      },
    );

    await handler.setTracks(makeTracks(2));
    engine.position = const Duration(seconds: 30);
    await handler.skipToNext();

    expect(log.first, 'start BV0');
    expect(log, contains('BV0@30'));
    expect(log.where((e) => e.startsWith('start')), ['start BV0', 'start BV1']);
    expect(log.indexOf('BV0@30'), lessThan(log.indexOf('start BV1')));

    log.clear();
    await handler.restore();
    expect(log.where((e) => e.startsWith('start')), isEmpty);
  });

  test('updateCurrentTrack 刷新通知栏与队列, 不重新加载', () async {
    await handler.setTracks(makeTracks(2));
    handler.updateCurrentTrack(
        handler.currentTrack!.copyWith(cleanedName: '新歌名', artist: '新歌手'));
    expect(handler.mediaItem.value!.title, '新歌名');
    expect(handler.mediaItem.value!.artist, '新歌手');
    expect(handler.queue.value.first.title, '新歌名');
    expect(engine.sources.length, 1);
  });
}
