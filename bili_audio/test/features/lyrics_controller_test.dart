import 'dart:io';

import 'package:bili_audio/app/providers.dart';
import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/lyrics/lyrics_manager.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/domain/lyrics/lrc_parser.dart';
import 'package:bili_audio/domain/lyrics/lyrics_provider.dart';
import 'package:bili_audio/features/lyrics/lyrics_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/player/fakes.dart';

class _Fixed implements LyricsProvider {
  _Fixed(this.score);
  final double score;
  int calls = 0;
  @override
  String get name => 'fixed';
  @override
  int get priority => 0;
  @override
  Future<List<LyricsCandidate>> search(LyricsQuery q) async {
    calls++;
    const lrc = '[00:01.00]第一句\n[00:05.00]第二句';
    return [
      LyricsCandidate(
        lyrics: LrcParser.parse(lrc),
        source: name,
        matchScore: score,
        lrcText: lrc,
      ),
    ];
  }
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late BiliAudioHandler handler;

  setUp(() async {
    db = AppDatabase.memory();
    dir = await Directory.systemTemp.createTemp('lyrics_ctrl_');
    handler = BiliAudioHandler(
      engine: FakeEngine(),
      streams: CountingStreamRepository(),
      downloads: CacheDownloadManager(
        AudioCacheStore(db, dir, limitBytes: () async => 1 << 30),
        Dio(),
      ),
    );
    for (final t in makeTracks(2)) {
      await db.tracksDao.ensureTrack(TracksCompanion.insert(
          bvid: t.bvid, cid: t.cid, title: t.title, duration: 180));
    }
  });

  tearDown(() async {
    await handler.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  ProviderContainer container(LyricsProvider p) {
    final c = ProviderContainer(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      lyricsManagerProvider
          .overrideWithValue(LyricsManager(db, dir, providers: [p])),
    ]);
    addTearDown(c.dispose);
    c.listen(lyricsControllerProvider, (_, _) {});
    return c;
  }

  /// 等待控制器得到非空结果
  Future<LyricsResult?> settle(ProviderContainer c) async {
    for (var i = 0; i < 100; i++) {
      final v = c.read(lyricsControllerProvider);
      if (v is AsyncData<LyricsResult?> && v.value != null) return v.value;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return c.read(lyricsControllerProvider).value;
  }

  test('当前曲变化时自动匹配; 切歌重新查询', () async {
    final p = _Fixed(0.95);
    final c = container(p);
    await handler.setTracks(makeTracks(2));

    final r = await settle(c);
    expect(r, isA<LyricsFound>());
    expect((r as LyricsFound).lyrics.lines.first.text, '第一句');

    await handler.skipToNext();
    for (var i = 0; i < 100 && p.calls < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(p.calls, 2);
  });

  test('偏移调整就地更新且持久化', () async {
    final c = container(_Fixed(0.95));
    await handler.setTracks(makeTracks(1));
    await settle(c);

    await c
        .read(lyricsControllerProvider.notifier)
        .adjustOffset(const Duration(milliseconds: 500));
    final r = c.read(lyricsControllerProvider).value as LyricsFound;
    expect(r.lyrics.offset, const Duration(milliseconds: 500));
    expect((await db.lyricsDao.get('BV0', 0))!.offsetMs, 500);
  });

  test('待确认候选: 手动选择后变为已匹配; 标记无歌词', () async {
    final c = container(_Fixed(0.7));
    await handler.setTracks(makeTracks(1));
    final r = await settle(c);
    expect(r, isA<LyricsUncertain>());

    final ctrl = c.read(lyricsControllerProvider.notifier);
    await ctrl.accept((r as LyricsUncertain).candidates.first);
    expect(c.read(lyricsControllerProvider).value, isA<LyricsFound>());

    await ctrl.markNone();
    expect(
      (c.read(lyricsControllerProvider).value as LyricsNone).markedByUser,
      true,
    );
  });
}
