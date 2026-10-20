import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/repositories/bili_video_repository.dart';
import 'package:bili_audio/data/bili/bili_video_api.dart';
import 'package:bili_audio/domain/entities/video.dart';
import 'package:bili_audio/domain/title/title_cleaner.dart';
import 'package:bili_audio/domain/title/title_rule.dart';
import 'package:bili_audio/core/utils/result.dart';

void main() {
  late AppDatabase db;
  late BiliVideoRepository repo;
  late MockVideoApi api;
  late MockCleaner cleaner;

  setUp(() async {
    db = AppDatabase.memory();
    api = MockVideoApi();
    cleaner = MockCleaner();
    repo = BiliVideoRepository(db, api, cleaner);
  });

  tearDown(() async {
    await db.close();
  });

  group('BiliVideoRepository', () {
    test('getTracks 单P使用视频标题', () async {
      api.video = Video(
        bvid: 'BV1',
        title: '周杰伦 - 七里香',
        uploader: 'UP主',
        uploaderMid: 123,
        cover: 'cover',
        pages: [
          VideoPage(cid: 1, title: 'P1', duration: const Duration(seconds: 270), pageIndex: 1),
        ],
      );

      cleaner.result = CleanedTitle(name: '七里香', artist: '周杰伦');

      final result = await repo.getTracks('BV1');

      expect(result.isSuccess, true);
      final tracks = result.valueOrNull!;

      expect(tracks.length, 1);
      expect(tracks[0].title, '周杰伦 - 七里香'); // 视频标题
      expect(tracks[0].cleanedName, '七里香');
      expect(tracks[0].artist, '周杰伦');

      expect(cleaner.lastRawTitle, '周杰伦 - 七里香'); // 传给 cleaner 的是视频标题
    });

    test('getTracks 多P且分P标题有效时使用分P标题', () async {
      api.video = Video(
        bvid: 'BV1',
        title: '合集',
        uploader: 'UP主',
        uploaderMid: 123,
        cover: 'cover',
        pages: [
          VideoPage(cid: 1, title: '歌曲1', duration: const Duration(seconds: 200), pageIndex: 1),
          VideoPage(cid: 2, title: '歌曲2', duration: const Duration(seconds: 300), pageIndex: 2),
        ],
      );

      cleaner.result = CleanedTitle(name: 'cleaned', artist: 'artist');

      final result = await repo.getTracks('BV1');

      expect(result.isSuccess, true);
      final tracks = result.valueOrNull!;

      expect(tracks.length, 2);
      expect(tracks[0].title, '歌曲1');
      expect(tracks[1].title, '歌曲2');
    });

    test('getTracks 多P但分P标题是占位符时用视频标题', () async {
      api.video = Video(
        bvid: 'BV1',
        title: '周杰伦 - 七里香',
        uploader: 'UP主',
        uploaderMid: 123,
        cover: 'cover',
        pages: [
          VideoPage(cid: 1, title: 'P1', duration: const Duration(seconds: 270), pageIndex: 1),
          VideoPage(cid: 2, title: '2', duration: const Duration(seconds: 280), pageIndex: 2),
        ],
      );

      cleaner.result = CleanedTitle(name: '七里香', artist: '周杰伦');

      final result = await repo.getTracks('BV1');

      expect(result.isSuccess, true);
      final tracks = result.valueOrNull!;

      expect(tracks[0].title, '周杰伦 - 七里香');
      expect(tracks[1].title, '周杰伦 - 七里香');
    });

    test('getTracks 保留用户编辑的歌名/歌手', () async {
      api.video = Video(
        bvid: 'BV1',
        title: 'Title',
        uploader: 'UP',
        uploaderMid: 1,
        cover: 'c',
        pages: [
          VideoPage(cid: 10, title: 'P1', duration: const Duration(seconds: 100), pageIndex: 1),
        ],
      );
      cleaner.result = CleanedTitle(name: 'Auto', artist: 'AutoArtist');
      await repo.getTracks('BV1');
      await db.tracksDao.updateTrackByUser(
        bvid: 'BV1',
        cid: 10,
        cleanedName: '我的歌名',
        artist: '我的歌手',
      );

      final tracks = (await repo.getTracks('BV1')).valueOrNull!;

      expect(tracks[0].cleanedName, '我的歌名');
      expect(tracks[0].artist, '我的歌手');
    });

    test('getTracks 写入数据库并回读', () async {
      api.video = Video(
        bvid: 'BV1',
        title: 'Title',
        uploader: 'UP',
        uploaderMid: 1,
        cover: 'c',
        pages: [
          VideoPage(cid: 10, title: 'P1', duration: const Duration(seconds: 100), pageIndex: 1),
        ],
      );

      cleaner.result = CleanedTitle(name: 'Name', artist: 'Artist');

      await repo.getTracks('BV1');

      // 验证已写入数据库
      final dbTrack = await db.tracksDao.getTrack('BV1', 10);
      expect(dbTrack, isNotNull);
      expect(dbTrack!.cleanedName, 'Name');
      expect(dbTrack.artist, 'Artist');
    });
  });
}

class MockVideoApi implements BiliVideoApi {
  Video? video;

  @override
  Future<Result<Video>> getVideoInfo(String bvid) async {
    return Result.success(video!);
  }

  @override
  Future<Result<List<String>>> getVideoTags(String bvid) async {
    return const Result.success([]);
  }
}

class MockCleaner implements TitleCleaner {
  CleanedTitle? result;
  String? lastRawTitle;

  @override
  CleanedTitle clean(
    String rawTitle, {
    Video? video,
    int? pageIndex,
    Set<String> disabledRuleIds = const {},
  }) {
    lastRawTitle = rawTitle;
    return result!;
  }

  @override
  TitleRuleConfig get config => throw UnimplementedError();
}
