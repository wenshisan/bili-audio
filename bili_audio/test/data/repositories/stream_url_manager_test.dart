import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/bili/bili_stream_api.dart';
import 'package:bili_audio/data/repositories/stream_url_manager.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';
import 'package:bili_audio/domain/entities/stream_url.dart';
import 'package:bili_audio/core/utils/result.dart';

void main() {
  late AppDatabase db;
  late MockStreamApi mockApi;
  late StreamUrlManager manager;
  DateTime now = DateTime(2024, 1, 1);

  setUp(() async {
    db = AppDatabase.memory();
    mockApi = MockStreamApi();
    manager = StreamUrlManager(db, mockApi, clock: () => now);
    // stream_urls 外键引用 tracks
    for (final (bvid, cid) in [('BV1', 1), ('BV2', 2)]) {
      await db.tracksDao.upsertTrack(TracksCompanion.insert(
        bvid: bvid, cid: cid, title: 't', duration: 100));
    }
  });

  tearDown(() async {
    await db.close();
  });

  group('StreamUrlManager', () {
    test('缓存未过期时返回缓存', () async {
      // 插入未过期缓存
      await db.streamUrlsDao.upsertStreamUrl(StreamUrlsCompanion.insert(
        bvid: 'BV1',
        cid: 1,
        quality: 30232,
        url: 'cached_url',
        mime: 'audio/mp4',
        expiresAt: now.add(const Duration(hours: 1)),
      ));

      final result = await manager.getStreamUrl(
        bvid: 'BV1',
        cid: 1,
        quality: AudioQuality.k132,
      );

      expect(result.isSuccess, true);
      expect(result.valueOrNull!.stream.url, 'cached_url');
      expect(mockApi.fetchCount, 0); // 未调用 API
    });

    test('缓存过期时重新拉取', () async {
      // 插入已过期缓存 (< 10min)
      await db.streamUrlsDao.upsertStreamUrl(StreamUrlsCompanion.insert(
        bvid: 'BV1',
        cid: 1,
        quality: 30232,
        url: 'old_url',
        mime: 'audio/mp4',
        expiresAt: now.add(const Duration(minutes: 5)),
      ));

      mockApi.response = (
        stream: StreamUrl(
          bvid: 'BV1',
          cid: 1,
          quality: AudioQuality.k132,
          url: 'new_url',
          expiresAt: now.add(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000,
        ),
        downgradedForGuest: false,
      );

      final result = await manager.getStreamUrl(
        bvid: 'BV1',
        cid: 1,
        quality: AudioQuality.k132,
      );

      expect(result.isSuccess, true);
      expect(result.valueOrNull!.stream.url, 'new_url');
      expect(mockApi.fetchCount, 1);
    });

    test('并发请求合并为一次', () async {
      mockApi.response = (
        stream: StreamUrl(
          bvid: 'BV1',
          cid: 1,
          quality: AudioQuality.k132,
          url: 'url',
          expiresAt: now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        ),
        downgradedForGuest: false,
      );

      final futures = List.generate(
        5,
        (_) => manager.getStreamUrl(
          bvid: 'BV1',
          cid: 1,
          quality: AudioQuality.k132,
        ),
      );

      await Future.wait(futures);

      expect(mockApi.fetchCount, 1);
    });

    test('refresh 忽略缓存', () async {
      await db.streamUrlsDao.upsertStreamUrl(StreamUrlsCompanion.insert(
        bvid: 'BV1',
        cid: 1,
        quality: 30232,
        url: 'cached_url',
        mime: 'audio/mp4',
        expiresAt: now.add(const Duration(hours: 1)),
      ));

      mockApi.response = (
        stream: StreamUrl(
          bvid: 'BV1',
          cid: 1,
          quality: AudioQuality.k132,
          url: 'refreshed_url',
          expiresAt: now.add(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000,
        ),
        downgradedForGuest: false,
      );

      final result = await manager.refresh(
        bvid: 'BV1',
        cid: 1,
        quality: AudioQuality.k132,
      );

      expect(result.isSuccess, true);
      expect(result.valueOrNull!.stream.url, 'refreshed_url');
      expect(mockApi.fetchCount, 1);
    });

    test('cleanExpired 删除过期条目', () async {
      await db.streamUrlsDao.upsertStreamUrl(StreamUrlsCompanion.insert(
        bvid: 'BV1',
        cid: 1,
        quality: 30232,
        url: 'old',
        mime: 'audio/mp4',
        expiresAt: now.subtract(const Duration(hours: 1)),
      ));

      await db.streamUrlsDao.upsertStreamUrl(StreamUrlsCompanion.insert(
        bvid: 'BV2',
        cid: 2,
        quality: 30232,
        url: 'new',
        mime: 'audio/mp4',
        expiresAt: now.add(const Duration(hours: 1)),
      ));

      final deleted = await manager.cleanExpired();

      expect(deleted, 1);
    });
  });
}

class MockStreamApi implements BiliStreamApi {
  int fetchCount = 0;
  StreamSelection? response;

  @override
  Future<Result<StreamSelection>> getStreamUrl({
    required String bvid,
    required int cid,
    required AudioQuality quality,
    bool loggedIn = false,
  }) async {
    fetchCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return Result.success(response!);
  }
}
