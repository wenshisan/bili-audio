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

  /// 音乐区推荐。发现页在用户还没发起搜索时按 tab 展示。
  ///
  /// 热度、评价和排行榜分区来自同一次拉榜。年代要再调 [eraChart]。
  Future<Result<DiscoverCharts>> dailyPopular();

  /// 音乐区里某一年代的歌曲。
  ///
  /// 曲目来自年代歌单，播放地址在 B 站按歌名和歌手查找。
  /// [page] 从 1 开始，[SearchHitPage.hasMore] 表示歌单还有下一页。
  Future<Result<SearchHitPage>> eraChart(DiscoverTab tab, {int page = 1});
}

/// 发现页上的两档推荐。
enum DiscoverGroup {
  /// 音乐区排行，以及排行里的子分区。
  ranking,

  /// 按歌曲年代搜索。
  era,
}

/// 发现页推荐分类。
enum DiscoverTab {
  /// 音乐区排行，按近期播放热度。
  heat(DiscoverGroup.ranking),

  /// 同一批热门里，投币、收藏相对播放量更高的。
  rating(DiscoverGroup.ranking),

  /// 排行榜里的原创音乐。
  original(DiscoverGroup.ranking),

  /// 排行榜里的翻唱。
  cover(DiscoverGroup.ranking),

  /// 排行榜里的 MV。
  mv(DiscoverGroup.ranking),

  /// 排行榜里的音乐现场。
  live(DiscoverGroup.ranking),

  /// 排行榜里的演奏。
  perform(DiscoverGroup.ranking),

  /// 排行榜里的 VOCALOID。
  vocaloid(DiscoverGroup.ranking),

  /// 排行榜里的 AI 音乐。
  ai(DiscoverGroup.ranking),

  /// 2020 年代的流行歌曲。
  y2020(DiscoverGroup.era),

  /// 2010 年代的流行歌曲。
  y2010(DiscoverGroup.era),

  /// 2000 年代的经典歌曲。
  y2000(DiscoverGroup.era),

  /// 90 年代的经典歌曲。
  y1990(DiscoverGroup.era),

  /// 80 年代的经典歌曲。
  y1980(DiscoverGroup.era),

  /// 70 年代的经典歌曲。
  y1970(DiscoverGroup.era);

  const DiscoverTab(this.group);

  final DiscoverGroup group;

  static const ranking = <DiscoverTab>[
    heat,
    rating,
    original,
    cover,
    mv,
    live,
    perform,
    vocaloid,
    ai,
  ];

  static const eras = <DiscoverTab>[y2020, y2010, y2000, y1990, y1980, y1970];
}

/// 一次拉榜得到的热度、评价和排行榜分区。曲目都已经按 15 分钟规则展开。
///
/// 年代不在这里，见 [SearchRepository.eraChart]。
class DiscoverCharts {
  const DiscoverCharts({
    this.heat = const [],
    this.rating = const [],
    this.zones = const {},
  });

  final List<SearchHit> heat;
  final List<SearchHit> rating;
  final Map<DiscoverTab, List<SearchHit>> zones;

  List<SearchHit> of(DiscoverTab tab) => switch (tab) {
    DiscoverTab.heat => heat,
    DiscoverTab.rating => rating,
    _ => zones[tab] ?? const [],
  };
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
