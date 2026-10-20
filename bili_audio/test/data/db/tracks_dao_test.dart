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

  group('TracksDao', () {
    test('插入并查询轨道', () async {
      final track = TracksCompanion.insert(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        title: '【周杰伦】七里香【Hi-Res】',
        duration: 280,
        cleanedName: const Value('七里香'),
        artist: const Value('周杰伦'),
      );

      await db.tracksDao.upsertTrack(track);

      final result = await db.tracksDao.getTrack('BV1xx411c7mD', 12345);
      expect(result, matcher.isNotNull);
      expect(result!.bvid, 'BV1xx411c7mD');
      expect(result.cid, 12345);
      expect(result.title, '【周杰伦】七里香【Hi-Res】');
      expect(result.cleanedName, '七里香');
      expect(result.artist, '周杰伦');
      expect(result.duration, 280);
      expect(result.userEdited, false);
    });

    test('更新清洗结果 (user_edited=false)', () async {
      await db.tracksDao.upsertTrack(
        TracksCompanion.insert(
          bvid: 'BV1xx411c7mD',
          cid: 12345,
          title: '原始标题',
          duration: 280,
        ),
      );

      final updated = await db.tracksDao.updateCleanedTitle(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        cleanedName: '清洗后歌名',
        artist: '歌手',
      );

      expect(updated, true);

      final result = await db.tracksDao.getTrack('BV1xx411c7mD', 12345);
      expect(result!.cleanedName, '清洗后歌名');
      expect(result.artist, '歌手');
    });

    test('不更新已编辑轨道的清洗结果', () async {
      await db.tracksDao.upsertTrack(
        TracksCompanion.insert(
          bvid: 'BV1xx411c7mD',
          cid: 12345,
          title: '原始标题',
          duration: 280,
          cleanedName: const Value('用户编辑的歌名'),
          artist: const Value('用户编辑的歌手'),
          userEdited: const Value(true),
        ),
      );

      final updated = await db.tracksDao.updateCleanedTitle(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        cleanedName: '清洗后歌名',
        artist: '自动歌手',
      );

      expect(updated, false);

      final result = await db.tracksDao.getTrack('BV1xx411c7mD', 12345);
      expect(result!.cleanedName, '用户编辑的歌名');
      expect(result.artist, '用户编辑的歌手');
    });

    test('用户手动编辑标记 user_edited=true', () async {
      await db.tracksDao.upsertTrack(
        TracksCompanion.insert(
          bvid: 'BV1xx411c7mD',
          cid: 12345,
          title: '原始标题',
          duration: 280,
        ),
      );

      await db.tracksDao.updateTrackByUser(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        cleanedName: '我的歌名',
        artist: '我的歌手',
      );

      final result = await db.tracksDao.getTrack('BV1xx411c7mD', 12345);
      expect(result!.cleanedName, '我的歌名');
      expect(result.artist, '我的歌手');
      expect(result.userEdited, true);
    });

    test('upsert 不覆盖 user_edited 的清洗字段', () async {
      await db.tracksDao.upsertTrack(
        TracksCompanion.insert(
          bvid: 'BV1xx411c7mD',
          cid: 12345,
          title: '原始标题',
          duration: 280,
          cleanedName: const Value('用户歌名'),
          artist: const Value('用户歌手'),
          userEdited: const Value(true),
        ),
      );

      // 再次 upsert，带不同的清洗结果
      await db.tracksDao.upsertTrack(
        TracksCompanion.insert(
          bvid: 'BV1xx411c7mD',
          cid: 12345,
          title: '更新的标题',
          duration: 300,
          cleanedName: const Value('新清洗歌名'),
          artist: const Value('新清洗歌手'),
        ),
      );

      final result = await db.tracksDao.getTrack('BV1xx411c7mD', 12345);
      expect(result!.cleanedName, '用户歌名'); // 保持用户编辑的值
      expect(result.artist, '用户歌手');
      expect(result.duration, 300); // 非清洗字段更新
    });

    test('搜索轨道', () async {
      await db.tracksDao.upsertTracks([
        TracksCompanion.insert(
          bvid: 'BV1',
          cid: 1,
          title: '原始标题1',
          duration: 200,
          cleanedName: const Value('七里香'),
          artist: const Value('周杰伦'),
        ),
        TracksCompanion.insert(
          bvid: 'BV2',
          cid: 2,
          title: '原始标题2',
          duration: 250,
          cleanedName: const Value('稻香'),
          artist: const Value('周杰伦'),
        ),
        TracksCompanion.insert(
          bvid: 'BV3',
          cid: 3,
          title: '原始标题3',
          duration: 180,
          cleanedName: const Value('晴天'),
          artist: const Value('周杰伦'),
        ),
      ]);

      final results = await db.tracksDao.searchTracks('周杰伦');
      expect(results.length, 3);

      final results2 = await db.tracksDao.searchTracks('七里香');
      expect(results2.length, 1);
      expect(results2.first.cleanedName, '七里香');
    });

    test('删除轨道', () async {
      await db.tracksDao.upsertTrack(
        TracksCompanion.insert(
          bvid: 'BV1xx411c7mD',
          cid: 12345,
          title: '测试',
          duration: 280,
        ),
      );

      await db.tracksDao.deleteTrack('BV1xx411c7mD', 12345);

      final result = await db.tracksDao.getTrack('BV1xx411c7mD', 12345);
      expect(result, matcher.isNull);
    });
  });
}
