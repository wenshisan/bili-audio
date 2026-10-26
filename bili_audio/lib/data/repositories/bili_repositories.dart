import 'dart:math' show min;

import '../../core/logging/app_logger.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_error.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/video.dart';
import '../../domain/title/title_cleaner.dart';
import '../bili/bili_ranking_api.dart';
import '../bili/bili_search_api.dart';
import '../bili/bili_stream_api.dart';
import '../bili/models/search_result.dart';
import 'repositories.dart';
import 'stream_url_manager.dart';

export 'bili_video_repository.dart';

/// 基于 B 站接口的搜索仓储 (M2.6)
class BiliSearchRepository implements SearchRepository {
  BiliSearchRepository(this._api, this._cleaner, {this.pageList, this.ranking});

  final BiliSearchApi _api;
  final TitleCleaner _cleaner;

  /// 音乐区排行。未提供时 [dailyPopular] 失败。
  final MusicChartSource? ranking;

  /// 拉取分P。未提供时只按搜索卡片时长丢掉超过 15 分钟的结果。
  final Future<Result<List<VideoPage>>> Function(String bvid)? pageList;

  static const maxDuration = 900;
  static const _concurrency = 4;

  /// `P1` / `p 2` / `1` 这类无信息量的分P标题
  static final _placeholderPart = RegExp(r'^\s*[Pp]?\s*\d+\s*$');

  @override
  Future<Result<SearchHitPage>> search(
    String keyword, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async {
    final result = await _api.searchVideo(keyword: keyword, page: page);
    if (result.isFailure) {
      AppLogger.e(
        'search "$keyword" page=$page failed',
        tag: 'search',
        error: result.errorOrNull,
      );
      return Result.failure(result.errorOrNull!);
    }
    return result.mapAsync((p) async {
      final groups = await _expandAll(p.items, onItems: onItems);
      final items = [for (final group in groups) ...group];
      AppLogger.i(
        'search "$keyword" page=$page raw=${p.items.length} '
        'shown=${items.length} total=${p.total} hasMore=${p.hasMore}',
        tag: 'search',
      );
      return (items: items, page: p.page, total: p.total, hasMore: p.hasMore);
    });
  }

  /// 音乐区排行拆成热度、评价和子分区。多 P 只展开一次，各列表共用结果。
  @override
  Future<Result<DiscoverCharts>> dailyPopular() async {
    final chart = ranking;
    if (chart == null) {
      return const Result.failure(
        AppError.unknown(message: 'music chart unavailable'),
      );
    }
    final result = await chart.dailyMusic();
    if (result.isFailure) {
      AppLogger.e(
        'daily music failed',
        tag: 'search',
        error: result.errorOrNull,
      );
      return Result.failure(result.errorOrNull!);
    }
    final bundle = result.valueOrNull;
    if (bundle == null) {
      return const Result.failure(
        AppError.unknown(message: 'music chart empty'),
      );
    }
    final expanded = await _expandChart(bundle.heat);
    List<SearchHit> take(List<SearchResult> source) => [
      for (final item in source) ...?expanded[item.bvid],
    ];
    final charts = DiscoverCharts(
      heat: take(bundle.heat),
      rating: take(bundle.rating),
      zones: {
        for (final entry in _zoneTabs.entries)
          entry.value: take(bundle.zones[entry.key] ?? const []),
      },
    );
    AppLogger.i(
      'daily music heat=${charts.heat.length} '
      'rating=${charts.rating.length} '
      'zones=${charts.zones.values.fold<int>(0, (n, list) => n + list.length)}',
      tag: 'search',
    );
    return Result.success(charts);
  }

  /// 年代搜索词。播放量排序，只要 10 分钟以内的音乐区视频。
  static const eraKeyword = <DiscoverTab, String>{
    DiscoverTab.y2020: '2020年代 流行歌曲',
    DiscoverTab.y2010: '2010年代 流行歌曲',
    DiscoverTab.y2000: '2000年代 经典歌曲',
    DiscoverTab.y1990: '90年代 经典歌曲',
    DiscoverTab.y1980: '80年代 经典歌曲',
    DiscoverTab.y1970: '70年代 经典歌曲',
  };

  static const eraDurationBand = 1;
  static const eraPageSize = 30;

  static const _zoneTabs = <MusicZone, DiscoverTab>{
    MusicZone.original: DiscoverTab.original,
    MusicZone.cover: DiscoverTab.cover,
    MusicZone.mv: DiscoverTab.mv,
    MusicZone.live: DiscoverTab.live,
    MusicZone.perform: DiscoverTab.perform,
    MusicZone.vocaloid: DiscoverTab.vocaloid,
    MusicZone.ai: DiscoverTab.ai,
  };

  @override
  Future<Result<List<SearchHit>>> eraChart(DiscoverTab tab) async {
    final keyword = eraKeyword[tab];
    if (keyword == null) return const Result.success([]);
    final result = await _api.searchVideo(
      keyword: keyword,
      pageSize: eraPageSize,
      order: 'click',
      duration: eraDurationBand,
    );
    if (result.isFailure) {
      AppLogger.e(
        'era "$keyword" failed',
        tag: 'search',
        error: result.errorOrNull,
      );
      return Result.failure(result.errorOrNull!);
    }
    final page = result.valueOrNull;
    if (page == null) {
      return const Result.failure(AppError.unknown(message: 'era chart empty'));
    }
    final seen = <String>{};
    final items = <SearchHit>[
      for (final item in page.items)
        if (item.duration <= maxDuration && seen.add(item.bvid)) _hit(item),
    ];
    AppLogger.i(
      'era "$keyword" raw=${page.items.length} shown=${items.length}',
      tag: 'search',
    );
    return Result.success(items);
  }

  Future<Map<String, List<SearchHit>>> _expandChart(
    List<SearchResult> items,
  ) async {
    final out = <String, List<SearchHit>>{};
    for (final item in items) {
      if ((item.totalPages ?? 1) > 1 && pageList != null) {
        out[item.bvid] = await _expand(item);
        continue;
      }
      if (item.duration > maxDuration) {
        AppLogger.d(
          'drop daily ${item.bvid} duration=${item.duration}s',
          tag: 'search',
        );
        out[item.bvid] = const [];
        continue;
      }
      out[item.bvid] = [_hit(item)];
    }
    return out;
  }

  /// 时长不超过 15 分钟的卡片先交出去。分P返回后按原位置替换，不必等整页结束。
  Future<List<List<SearchHit>>> _expandAll(
    List<SearchResult> items, {
    void Function(List<SearchHit> items)? onItems,
  }) async {
    if (items.isEmpty) return const [];
    final out = List<List<SearchHit>?>.filled(items.length, null);
    var cursor = 0;
    var shown = false;

    void publish() {
      final ready = onItems;
      if (ready == null) return;
      final visible = [for (final group in out) ...?group];
      if (visible.isEmpty && !shown) return;
      shown = visible.isNotEmpty;
      ready(visible);
    }

    if (pageList != null) {
      var seeded = false;
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.filtered == true || item.duration > maxDuration) continue;
        out[i] = [_hit(item)];
        seeded = true;
      }
      if (seeded) publish();
    }

    Future<void> worker() async {
      while (true) {
        final index = cursor++;
        if (index >= items.length) return;
        out[index] = await _expand(items[index]);
        publish();
      }
    }

    final workers = min(_concurrency, items.length);
    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
    return [for (final group in out) group!];
  }

  /// 单 P 且超过 15 分钟则丢弃；多 P 则每个不超过 15 分钟的分P单独成一条。
  Future<List<SearchHit>> _expand(SearchResult item) async {
    final load = pageList;
    List<VideoPage>? pages;
    if (load != null) {
      try {
        final loaded = await load(item.bvid);
        pages = loaded.valueOrNull;
        if (pages == null) {
          AppLogger.w(
            'pagelist ${item.bvid} failed: ${loaded.errorOrNull}; '
            'fallback duration=${item.duration}s',
            tag: 'search',
          );
        }
      } catch (e, st) {
        AppLogger.e(
          'pagelist ${item.bvid} threw',
          tag: 'search',
          error: e,
          stackTrace: st,
        );
        pages = null;
      }
    }
    if (pages == null || pages.isEmpty) {
      if (item.duration > maxDuration) {
        AppLogger.d(
          'drop ${item.bvid} duration=${item.duration}s > ${maxDuration}s '
          '(no pages)',
          tag: 'search',
        );
        return const [];
      }
      return [_hit(item)];
    }

    final playable = [
      for (final page in pages)
        if (page.duration.inSeconds <= maxDuration) page,
    ];
    final dropped = pages.length - playable.length;
    if (dropped > 0 || pages.length > 1) {
      AppLogger.d(
        'expand ${item.bvid} pages=${pages.length} kept=${playable.length} '
        'dropped=$dropped',
        tag: 'search',
      );
    }
    if (playable.isEmpty) return const [];

    if (pages.length == 1) {
      final page = playable.single;
      return [
        _hit(
          item.copyWith(
            duration: page.duration.inSeconds,
            cid: page.cid,
            pageIndex: page.pageIndex,
            totalPages: 1,
            filtered: false,
          ),
        ),
      ];
    }

    return [
      for (final page in playable)
        _hit(
          item.copyWith(
            duration: page.duration.inSeconds,
            cid: page.cid,
            pageIndex: page.pageIndex,
            totalPages: pages.length,
            filtered: false,
          ),
          rawTitle: _placeholderPart.hasMatch(page.title)
              ? item.cleanTitle
              : page.title,
        ),
    ];
  }

  SearchHit _hit(SearchResult result, {String? rawTitle}) {
    final title = rawTitle ?? result.cleanTitle;
    final shown = rawTitle == null
        ? result
        : result.copyWith(title: title, cleanTitle: title);
    return (result: shown, cleaned: _cleaner.clean(title));
  }
}

/// 基于 [StreamUrlManager] 的流地址仓储 (M2.6)
class BiliStreamRepository implements StreamRepository {
  BiliStreamRepository(this._manager);

  final StreamUrlManager _manager;

  @override
  Future<Result<StreamSelection>> resolve(
    Track track,
    AudioQuality quality, {
    bool loggedIn = false,
  }) => _manager.getStreamUrl(
    bvid: track.bvid,
    cid: track.cid,
    quality: quality,
    loggedIn: loggedIn,
  );

  @override
  Future<Result<StreamSelection>> refresh(
    Track track,
    AudioQuality quality, {
    bool loggedIn = false,
  }) => _manager.refresh(
    bvid: track.bvid,
    cid: track.cid,
    quality: quality,
    loggedIn: loggedIn,
  );
}
