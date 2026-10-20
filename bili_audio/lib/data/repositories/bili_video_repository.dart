import '../../core/utils/result.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/video.dart';
import '../../domain/title/title_cleaner.dart';
import '../bili/bili_video_api.dart';
import '../db/app_database.dart' as db;
import 'package:drift/drift.dart' show Value;
import 'repositories.dart';

/// 基于 B 站接口 + drift 的视频仓储 (M2.6)
class BiliVideoRepository implements VideoRepository {
  BiliVideoRepository(this._db, this._api, this._cleaner);

  final db.AppDatabase _db;
  final BiliVideoApi _api;
  final TitleCleaner _cleaner;

  /// `P1` / `p 2` / `1` 这类无信息量的分P标题
  static final _placeholderPart = RegExp(r'^\s*[Pp]?\s*\d+\s*$');

  @override
  Future<Result<List<Track>>> getTracks(String bvid) async {
    final videoResult = await _api.getVideoInfo(bvid);
    if (videoResult case Failure(:final error)) return Result.failure(error);
    var video = videoResult.valueOrNull!;

    // tags 仅用于清洗兜底, 失败不阻塞
    final tags = (await _api.getVideoTags(bvid)).valueOrNull ?? const [];
    video = video.copyWith(tags: tags);

    final total = video.pages.length;
    final tracks = <Track>[];
    for (final page in video.pages) {
      final usePart = total > 1 && !_placeholderPart.hasMatch(page.title);
      final rawTitle = usePart ? page.title : video.title;
      final cleaned = _cleaner.clean(
        rawTitle,
        video: video,
        pageIndex: page.pageIndex,
      );

      await _db.tracksDao.upsertTrack(db.TracksCompanion.insert(
        bvid: bvid,
        cid: page.cid,
        title: rawTitle,
        cleanedName: Value(cleaned.name),
        artist: Value(cleaned.artist),
        duration: page.duration.inSeconds,
        cover: Value(video.cover),
        uploader: Value(video.uploader),
        pageIndex: Value(page.pageIndex),
        totalPages: Value(total),
      ));

      // 回读数据库, 让用户编辑过的歌名/歌手生效
      final row = (await _db.tracksDao.getTrack(bvid, page.cid))!;
      tracks.add(_toEntity(row));
    }
    return Result.success(tracks);
  }

  static Track _toEntity(db.Track row) => Track(
        bvid: row.bvid,
        cid: row.cid,
        title: row.title,
        cleanedName: row.cleanedName,
        artist: row.artist,
        duration: Duration(seconds: row.duration),
        cover: row.cover,
        uploader: row.uploader,
        pageIndex: row.pageIndex,
        totalPages: row.totalPages,
      );
}

/// 便于外部在只有 [Video] 时构造 Track (Fake 仓储复用)
List<Track> tracksFromVideo(Video video) => [
      for (final p in video.pages)
        Track(
          bvid: video.bvid,
          cid: p.cid,
          title: video.pages.length > 1 ? p.title : video.title,
          duration: p.duration,
          cover: video.cover,
          uploader: video.uploader,
          pageIndex: p.pageIndex,
          totalPages: video.pages.length,
        ),
    ];
