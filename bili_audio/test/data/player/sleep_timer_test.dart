import 'dart:io';

import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/data/player/sleep_timer.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('SleepTimer', () {
    test('倒计时到点触发 onFire 并回到关闭状态', () async {
      var fired = 0;
      final timer = SleepTimer(
        onFire: () async => fired++,
        tick: const Duration(milliseconds: 10),
      );
      timer.start(const Duration(milliseconds: 50));
      expect(timer.state, isA<SleepCountdown>());

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(fired, 1);
      expect(timer.state, isA<SleepOff>());
      await timer.dispose();
    });

    test('cancel 后不触发', () async {
      var fired = 0;
      final timer = SleepTimer(
        onFire: () async => fired++,
        tick: const Duration(milliseconds: 10),
      );
      timer.start(const Duration(milliseconds: 30));
      timer.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(fired, 0);
      await timer.dispose();
    });

    test('播完下一首: 第 2 次曲目结束时触发', () async {
      var fired = 0;
      final timer = SleepTimer(onFire: () async => fired++)..startAfterTracks(2);
      expect(timer.onTrackCompleted(), false);
      expect(timer.onTrackCompleted(), true);
      expect(fired, 1);
      expect(timer.onTrackCompleted(), false); // 已关闭
      await timer.dispose();
    });
  });

  test('handler: 播完当前后停在下一首开头, 不自动播放', () async {
    final db = AppDatabase.memory();
    final dir = await Directory.systemTemp.createTemp('sleep_');
    final engine = FakeEngine();
    final handler = BiliAudioHandler(
      engine: engine,
      streams: CountingStreamRepository(),
      downloads: CacheDownloadManager(
        AudioCacheStore(db, dir, limitBytes: () async => 1 << 30),
        Dio(),
      ),
    );

    await handler.setTracks(makeTracks(3));
    handler.sleepTimer.startAfterTracks(1);
    await engine.complete();

    expect(handler.currentTrack!.bvid, 'BV1');
    expect(engine.playing, false);

    await handler.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });
}
