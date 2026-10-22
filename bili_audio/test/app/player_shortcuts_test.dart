import 'dart:io';

import 'package:bili_audio/app/adaptive/player_shortcuts.dart';
import 'package:bili_audio/app/platform/window_frame.dart';
import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/player/fakes.dart';

void main() {
  test('窗口矩形落在屏幕内才恢复', () {
    const screen = Rect.fromLTWH(0, 0, 1920, 1080);
    expect(
      WindowFrame.restore(x: 100, y: 80, w: 1280, h: 800, screens: const [screen]),
      const Rect.fromLTWH(100, 80, 1280, 800),
    );
    expect(
      WindowFrame.restore(x: 4000, y: 80, w: 1280, h: 800, screens: const [screen]),
      isNull,
    );
    expect(
      WindowFrame.restore(x: 0, y: 0, w: 200, h: 200, screens: const []),
      isNull,
    );
  });

  test('seekBy 不超过曲目时长，空格切换播放', () async {
    final db = AppDatabase.memory();
    final dir = Directory.systemTemp.createTempSync('keys_');
    addTearDown(() async {
      dir.deleteSync(recursive: true);
      await db.close();
    });
    final engine = FakeEngine();
    final handler = BiliAudioHandler(
      engine: engine,
      streams: CountingStreamRepository(),
      downloads: CacheDownloadManager(
        AudioCacheStore(db, dir, limitBytes: () async => 1 << 30),
        Dio(),
      ),
    );
    addTearDown(handler.dispose);
    await handler.setTracks(makeTracks(1));
    engine.playing = true;
    engine.position = const Duration(seconds: 1);
    seekBy(handler, const Duration(seconds: 5));
    expect(engine.position, const Duration(seconds: 6));
    seekBy(handler, const Duration(seconds: -100));
    expect(engine.position, Duration.zero);

    expect(engine.playing, isTrue);
    togglePlay(handler);
    await Future<void>.delayed(Duration.zero);
    expect(engine.playing, isFalse);
    togglePlay(handler);
    await Future<void>.delayed(Duration.zero);
    expect(engine.playing, isTrue);
  });
}
