import '../../core/utils/result.dart';
import '../../domain/entities/app_error.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/stream_url.dart';
import '../../domain/title/title_rule.dart';
import '../bili/bili_stream_api.dart';
import '../bili/models/search_result.dart';
import 'repositories.dart';

/// 内置演示数据 (M2.6): 供 M6 UI 在接口就绪前开发, 不发任何网络请求
const _demo = [
  ('BV1fake00001', '周杰伦 - 七里香【Hi-Res】', '七里香', '周杰伦', 299),
  ('BV1fake00002', '【陈奕迅】十年 (Live)', '十年', '陈奕迅', 205),
  ('BV1fake00003', '《夜曲》钢琴版', '夜曲', null, 226),
  ('BV1fake00004', '纯音乐 | 雨的印记', '雨的印记', null, 248),
  ('BV1fake00005', '超长录播合集', '超长录播合集', null, 3600),
];

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  @override
  Future<Result<SearchHitPage>> search(
    String keyword, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async {
    await Future<void>.delayed(latency);
    final hits = <SearchHit>[
      for (final (bvid, title, name, artist, sec) in _demo)
        if (keyword.trim().isEmpty || title.contains(keyword.trim()))
          (
            result: SearchResult(
              bvid: bvid,
              title: title,
              cleanTitle: title,
              duration: sec,
              cover: '',
              author: 'Fake UP',
              play: 1000,
              filtered: sec > 900,
            ),
            cleaned: CleanedTitle(name: name, artist: artist),
          ),
    ];
    final shown = page == 1 ? hits : <SearchHit>[];
    if (shown.isNotEmpty) onItems?.call(shown);
    return Result.success((
      items: shown,
      page: page,
      total: hits.length,
      hasMore: false,
    ));
  }

  @override
  Future<Result<DiscoverCharts>> dailyPopular({
    void Function(DiscoverCharts charts)? onCharts,
  }) async {
    final page = await search('');
    if (page.isFailure) return Result.failure(page.errorOrNull!);
    final playable = [
      for (final hit in page.valueOrNull!.items)
        if (hit.result.filtered != true && hit.result.duration <= 900) hit,
    ];
    final charts = DiscoverCharts(
      heat: playable,
      rating: playable.reversed.toList(),
      zones: {
        for (final tab in DiscoverTab.ranking)
          if (tab != DiscoverTab.heat && tab != DiscoverTab.rating)
            tab: playable,
      },
    );
    onCharts?.call(charts);
    return Result.success(charts);
  }

  @override
  Future<Result<SearchHitPage>> eraChart(
    DiscoverTab tab, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async {
    final charts = await dailyPopular();
    if (charts.isFailure) return Result.failure(charts.errorOrNull!);
    final items = charts.valueOrNull?.heat ?? const <SearchHit>[];
    if (items.isNotEmpty) onItems?.call(items);
    return Result.success((
      items: items,
      page: page,
      total: items.length,
      hasMore: false,
    ));
  }
}

class FakeVideoRepository implements VideoRepository {
  @override
  Future<Result<List<Track>>> getTracks(String bvid) async {
    for (final (id, title, name, artist, sec) in _demo) {
      if (id != bvid) continue;
      if (sec > 900) return const Result.failure(AppError.notFound());
      return Result.success([
        Track(
          bvid: id,
          cid: id.hashCode.abs(),
          title: title,
          cleanedName: name,
          artist: artist,
          duration: Duration(seconds: sec),
          uploader: 'Fake UP',
          pageIndex: 1,
          totalPages: 1,
        ),
      ]);
    }
    return const Result.failure(AppError.notFound());
  }
}

class FakeStreamRepository implements StreamRepository {
  /// 公开测试音源, 仅用于开发演示
  FakeStreamRepository({
    this.url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  });

  final String url;

  @override
  Future<Result<StreamSelection>> resolve(
    Track track,
    AudioQuality quality, {
    bool loggedIn = false,
  }) async => Result.success((
    stream: StreamUrl(
      bvid: track.bvid,
      cid: track.cid,
      quality: quality,
      url: url,
      expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7200,
    ),
    downgradedForGuest: false,
  ));

  @override
  Future<Result<StreamSelection>> refresh(
    Track track,
    AudioQuality quality, {
    bool loggedIn = false,
  }) => resolve(track, quality, loggedIn: loggedIn);
}
