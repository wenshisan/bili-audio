import '../../core/utils/result.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/title/title_rule.dart';
import '../bili/bili_stream_api.dart';
import '../bili/models/search_result.dart';

/// 搜索结果 + 标题清洗结果, 供 UI 直接展示 (M2.6)
typedef SearchHit = ({SearchResult result, CleanedTitle cleaned});

typedef SearchHitPage = ({
  List<SearchHit> items,
  int page,
  int total,
  bool hasMore,
});

/// 仓储接口 (M2.6): UI 只依赖这些接口, 便于用 Fake 实现提前开发

abstract interface class SearchRepository {
  /// [onItems] 在这一页还没全部展开完时就会收到当前可展示的结果，按原顺序。
  Future<Result<SearchHitPage>> search(
    String keyword, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  });

  /// 音乐区当日热门。发现页在用户还没发起搜索时展示。
  Future<Result<SearchHitPage>> dailyPopular();
}

abstract interface class VideoRepository {
  /// 拉取视频详情, 清洗标题并写入 tracks 表, 返回可播放分P
  ///
  /// `user_edited=true` 的记录保留用户编辑的歌名/歌手。
  Future<Result<List<Track>>> getTracks(String bvid);
}

abstract interface class StreamRepository {
  Future<Result<StreamSelection>> resolve(
    Track track,
    AudioQuality quality, {
    bool loggedIn = false,
  });

  /// CDN 403 等场景强制刷新
  Future<Result<StreamSelection>> refresh(
    Track track,
    AudioQuality quality, {
    bool loggedIn = false,
  });
}
