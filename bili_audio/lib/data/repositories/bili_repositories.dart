import 'dart:math' show max, min;

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
import '../era/era_catalog.dart';
import '../era/era_titles.dart';
import 'repositories.dart';
import 'stream_url_manager.dart';

export 'bili_video_repository.dart';

/// 基于 B 站接口的搜索仓储 (M2.6)
class BiliSearchRepository implements SearchRepository {
  BiliSearchRepository(
    this._api,
    this._cleaner, {
    this.pageList,
    this.ranking,
    this.eraCatalog,
  });

  final BiliSearchApi _api;
  final TitleCleaner _cleaner;

  /// 年代曲目来源。有的话先拿歌名，再在 B 站找可播放的视频。
  final EraCatalog? eraCatalog;

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
    final result = await _api.searchVideo(
      keyword: keyword,
      page: page,
      tids: const [],
    );
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
  Future<Result<DiscoverCharts>> dailyPopular({
    void Function(DiscoverCharts charts)? onCharts,
  }) async {
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
    final zoneLists = <MusicZone, List<SearchResult>>{
      for (final zone in MusicZone.values) zone: [...?bundle.zones[zone]],
    };
    _fillZonesByTitle(zoneLists, bundle.heat);
    final preview = _previewCharts(bundle.heat, bundle.rating, zoneLists);
    if (preview.heat.isNotEmpty ||
        preview.rating.isNotEmpty ||
        preview.zones.values.any((list) => list.isNotEmpty)) {
      onCharts?.call(preview);
    }
    final found = await Future.wait([
      _searchSongs(heatKeyword),
      for (final zone in MusicZone.values) _searchSongs(zoneKeyword[zone]!),
    ]);
    final extraHeat = found.first;
    for (var i = 0; i < MusicZone.values.length; i++) {
      final zone = MusicZone.values[i];
      zoneLists[zone] = _appendNew(zoneLists[zone] ?? const [], found[i + 1]);
    }
    final heat = _appendNew(bundle.heat, extraHeat);
    final rating = _appendNew(bundle.rating, extraHeat);
    final expanded = await _expandChart([
      ...heat,
      ...rating,
      for (final list in zoneLists.values) ...list,
    ]);
    List<SearchHit> take(List<SearchResult> source) => [
      for (final item in source) ...?expanded[item.bvid],
    ];
    final charts = DiscoverCharts(
      heat: take(heat),
      rating: take(rating),
      zones: {
        for (final entry in _zoneTabs.entries)
          entry.value: take(zoneLists[entry.key] ?? const []),
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

  /// 年代搜索词。播放量排序后，再按标题确认是不是这一年代。
  static const eraKeyword = <DiscoverTab, String>{
    DiscoverTab.y2020: '2020年代流行歌曲',
    DiscoverTab.y2010: '2010年代流行歌曲',
    DiscoverTab.y2000: '2000年代经典歌曲',
    DiscoverTab.y1990: '90年代经典歌曲',
    DiscoverTab.y1980: '80年代经典老歌',
    DiscoverTab.y1970: '70年代经典老歌',
  };

  static const eraPageSize = 30;

  /// 超长合集最多拆几部，避免一页结果都去拉分 P。
  static const eraExpansions = 3;

  static const minEraDuration = 60;

  /// 给一首歌找 B 站视频时，最多看几条搜索结果。
  static const eraLookupSize = 8;

  /// 标题点名的年代。70、80、90 这种跨年代合集会返回多个。
  static Set<DiscoverTab> erasMentioned(String title) =>
      erasMentionedInTitle(title);

  static const _zoneTabs = <MusicZone, DiscoverTab>{
    MusicZone.original: DiscoverTab.original,
    MusicZone.cover: DiscoverTab.cover,
    MusicZone.mv: DiscoverTab.mv,
    MusicZone.live: DiscoverTab.live,
    MusicZone.perform: DiscoverTab.perform,
    MusicZone.vocaloid: DiscoverTab.vocaloid,
    MusicZone.ai: DiscoverTab.ai,
  };

  /// 热度榜后面再按播放量补歌曲。不限分区。
  static const heatKeyword = '歌曲';

  /// 排行榜每个子分区再按播放量补歌曲。不限分区。
  static const zoneKeyword = <MusicZone, String>{
    MusicZone.original: '原创音乐',
    MusicZone.cover: '翻唱',
    MusicZone.mv: '音乐MV',
    MusicZone.live: '音乐现场',
    MusicZone.perform: '演奏',
    MusicZone.vocaloid: 'VOCALOID',
    MusicZone.ai: 'AI音乐',
  };

  /// 榜单标题里出现这些词时归入分类，不要求稿件在音乐区。靠前的规则优先。
  static const zoneTitleHint = <(MusicZone, String)>[
    (MusicZone.ai, 'AI音乐'),
    (MusicZone.ai, 'AIMV'),
    (MusicZone.ai, 'AI MV'),
    (MusicZone.ai, 'AI歌曲'),
    (MusicZone.vocaloid, 'VOCALOID'),
    (MusicZone.vocaloid, '初音'),
    (MusicZone.vocaloid, '洛天依'),
    (MusicZone.live, '音乐现场'),
    (MusicZone.perform, '演奏'),
    (MusicZone.original, '原创音乐'),
    (MusicZone.cover, '翻唱'),
    (MusicZone.mv, 'MV'),
  ];

  void _fillZonesByTitle(
    Map<MusicZone, List<SearchResult>> zoneLists,
    List<SearchResult> heat,
  ) {
    final placed = <String>{
      for (final list in zoneLists.values) ...list.map((item) => item.bvid),
    };
    for (final item in heat) {
      if (!placed.add(item.bvid)) continue;
      final zone = _zoneFromTitle(item.cleanTitle);
      if (zone == null) continue;
      zoneLists[zone] = [...?zoneLists[zone], item];
    }
  }

  List<SearchHit> _playable(List<SearchResult> source) => [
    for (final item in source)
      if (item.duration >= minEraDuration &&
          item.duration <= maxDuration &&
          item.filtered != true)
        _hit(item),
  ];

  DiscoverCharts _previewCharts(
    List<SearchResult> heat,
    List<SearchResult> rating,
    Map<MusicZone, List<SearchResult>> zoneLists,
  ) => DiscoverCharts(
    heat: _playable(heat),
    rating: _playable(rating),
    zones: {
      for (final entry in _zoneTabs.entries)
        entry.value: _playable(zoneLists[entry.key] ?? const []),
    },
  );

  MusicZone? _zoneFromTitle(String title) {
    final lower = title.toLowerCase();
    for (final (zone, hint) in zoneTitleHint) {
      if (lower.contains(hint.toLowerCase())) return zone;
    }
    return null;
  }

  static const zoneSearchSize = 50;

  /// 每个关键词连续翻这么多页，避免榜单只有几十条。
  static const zoneSearchPages = 6;

  List<SearchResult> _appendNew(
    List<SearchResult> base,
    List<SearchResult> extra,
  ) {
    final seen = <String>{for (final item in base) item.bvid};
    return [
      ...base,
      for (final item in extra)
        if (seen.add(item.bvid)) item,
    ];
  }

  Future<List<SearchResult>> _searchSongs(String keyword) async {
    final out = <SearchResult>[];
    final seen = <String>{};
    try {
      for (var page = 1; page <= zoneSearchPages; page++) {
        final result = await _api.searchVideo(
          keyword: keyword,
          page: page,
          pageSize: zoneSearchSize,
          tids: const [],
          order: 'click',
        );
        final fetched = result.valueOrNull;
        if (fetched == null) break;
        for (final item in fetched.items) {
          if (item.duration < minEraDuration || item.duration > maxDuration) {
            continue;
          }
          if (seen.add(item.bvid)) out.add(item);
        }
        if (!fetched.hasMore) break;
      }
    } catch (e, st) {
      AppLogger.e(
        'chart search "$keyword" failed',
        tag: 'search',
        error: e,
        stackTrace: st,
      );
    }
    AppLogger.i('chart search "$keyword" songs=${out.length}', tag: 'search');
    return out;
  }

  @override
  Future<Result<SearchHitPage>> eraChart(
    DiscoverTab tab, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async {
    final catalog = eraCatalog;
    if (catalog != null) {
      final listed = await catalog.page(tab, page: page);
      final data = listed.valueOrNull;
      if (data != null && (data.tracks.isNotEmpty || page > 1)) {
        final items = await _resolveEraTracks(data.tracks, onItems: onItems);
        AppLogger.i(
          'era catalog ${tab.name} page=${data.page} '
          'songs=${data.tracks.length} shown=${items.length} '
          'hasMore=${data.hasMore}',
          tag: 'search',
        );
        return Result.success((
          items: items,
          page: data.page,
          total: data.total,
          hasMore: data.hasMore,
        ));
      }
      if (page > 1) {
        return Result.success((
          items: const [],
          page: page,
          total: 0,
          hasMore: false,
        ));
      }
      AppLogger.w(
        'era catalog miss ${tab.name}, use bili search: ${listed.errorOrNull}',
        tag: 'search',
      );
    }
    return _eraChartFromBili(tab, page: page, onItems: onItems);
  }

  Future<Result<SearchHitPage>> _eraChartFromBili(
    DiscoverTab tab, {
    required int page,
    void Function(List<SearchHit> items)? onItems,
  }) async {
    final keyword = eraKeyword[tab];
    if (keyword == null) {
      return Result.success((
        items: const [],
        page: page,
        total: 0,
        hasMore: false,
      ));
    }
    final result = await _api.searchVideo(
      keyword: keyword,
      page: page,
      pageSize: eraPageSize,
      order: 'click',
      tids: const [],
    );
    if (result.isFailure) {
      AppLogger.e(
        'era "$keyword" page=$page failed',
        tag: 'search',
        error: result.errorOrNull,
      );
      return Result.failure(result.errorOrNull!);
    }
    final fetched = result.valueOrNull;
    if (fetched == null) {
      return const Result.failure(AppError.unknown(message: 'era chart empty'));
    }
    final seen = <String>{};
    final items = <SearchHit>[];
    var expansions = 0;
    void publish() {
      if (items.isEmpty) return;
      onItems?.call(List<SearchHit>.of(items));
    }

    for (final item in fetched.items) {
      if (!seen.add(item.bvid)) continue;
      final mentioned = erasMentioned(item.cleanTitle);
      if (mentioned.length != 1 || !mentioned.contains(tab)) continue;
      if (item.duration <= maxDuration) {
        if (item.duration >= minEraDuration) {
          items.add(_hit(item));
          publish();
        }
        continue;
      }
      if (expansions >= eraExpansions) continue;
      expansions++;
      final expanded = await _expand(item);
      for (final hit in expanded) {
        if (hit.result.duration < minEraDuration) continue;
        items.add(hit);
        publish();
      }
    }
    AppLogger.i(
      'era "$keyword" page=${fetched.page} raw=${fetched.items.length} '
      'shown=${items.length} expanded=$expansions hasMore=${fetched.hasMore}',
      tag: 'search',
    );
    return Result.success((
      items: items,
      page: fetched.page,
      total: fetched.total,
      hasMore: fetched.hasMore,
    ));
  }

  Future<List<SearchHit>> _resolveEraTracks(
    List<EraTrack> tracks, {
    void Function(List<SearchHit> items)? onItems,
  }) async {
    if (tracks.isEmpty) return const [];
    final out = List<SearchHit?>.filled(tracks.length, null);
    var next = 0;

    void publish() {
      final ready = onItems;
      if (ready == null) return;
      final seen = <String>{};
      final visible = <SearchHit>[
        for (final hit in out)
          if (hit != null &&
              seen.add(
                '${hit.result.bvid}:${hit.result.cid ?? hit.result.pageIndex ?? 0}',
              ))
            hit,
      ];
      if (visible.isEmpty) return;
      ready(visible);
    }

    Future<void> worker() async {
      while (true) {
        final index = next;
        if (index >= tracks.length) return;
        next++;
        out[index] = await _resolveEraTrack(tracks[index]);
        publish();
      }
    }

    final workers = min(_concurrency, tracks.length);
    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
    final seen = <String>{};
    return [
      for (final hit in out)
        if (hit != null &&
            seen.add(
              '${hit.result.bvid}:${hit.result.cid ?? hit.result.pageIndex ?? 0}',
            ))
          hit,
    ];
  }

  Future<SearchHit?> _resolveEraTrack(EraTrack track) async {
    final name = _songName(track.name);
    if (name.length < 2) return null;
    final keyword = [
      track.artist,
      name,
    ].where((part) => part.isNotEmpty).join(' ');
    final result = await _api.searchVideo(
      keyword: keyword,
      pageSize: eraLookupSize,
      tids: const [],
    );
    final fetched = result.valueOrNull;
    if (fetched == null) {
      AppLogger.d('era miss "$keyword"', tag: 'search');
      return null;
    }
    final shorts = <SearchResult>[];
    SearchResult? collection;
    for (final item in fetched.items) {
      if (!_mentionsSong(item.cleanTitle, name)) continue;
      if (item.duration >= minEraDuration &&
          item.duration <= maxDuration &&
          _durationClose(item.duration, track.duration)) {
        shorts.add(item);
        continue;
      }
      collection ??= item.duration > maxDuration ? item : null;
    }
    if (shorts.isNotEmpty) {
      shorts.sort(
        (a, b) => _durationDelta(
          a.duration,
          track.duration,
        ).compareTo(_durationDelta(b.duration, track.duration)),
      );
      return _hit(shorts.first);
    }
    if (collection == null || pageList == null) {
      AppLogger.d('era miss "$keyword"', tag: 'search');
      return null;
    }
    final parts = [
      for (final hit in await _expand(collection))
        if (_mentionsSong(hit.result.cleanTitle, name) &&
            hit.result.duration >= minEraDuration &&
            _durationClose(hit.result.duration, track.duration))
          hit,
    ];
    if (parts.isEmpty) {
      AppLogger.d('era miss "$keyword"', tag: 'search');
      return null;
    }
    parts.sort(
      (a, b) => _durationDelta(
        a.result.duration,
        track.duration,
      ).compareTo(_durationDelta(b.result.duration, track.duration)),
    );
    return parts.first;
  }

  static String _songName(String name) =>
      name.replaceAll(RegExp(r'\s*[（(][^）)]*[）)]\s*'), ' ').trim();

  static bool _mentionsSong(String title, String name) =>
      title.toLowerCase().contains(name.toLowerCase());

  static bool _durationClose(int seconds, Duration expected) {
    if (expected.inSeconds <= 0) return true;
    final slack = max(20, (expected.inSeconds * 0.2).round());
    return (seconds - expected.inSeconds).abs() <= slack;
  }

  static int _durationDelta(int seconds, Duration expected) =>
      (seconds - expected.inSeconds).abs();

  Future<Map<String, List<SearchHit>>> _expandChart(
    List<SearchResult> items,
  ) async {
    final out = <String, List<SearchHit>>{};
    for (final item in items) {
      if (out.containsKey(item.bvid)) continue;
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
