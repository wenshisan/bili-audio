import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/result.dart';
import '../../data/repositories/repositories.dart';

/// 搜索页状态 (M6.1)
class SearchState {
  const SearchState({
    this.keyword = '',
    this.chart = DiscoverTab.heat,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loading = false,
    this.error,
  });

  final String keyword;
  final DiscoverTab chart;
  final List<SearchHit> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final Object? error;

  SearchState copyWith({
    String? keyword,
    DiscoverTab? chart,
    List<SearchHit>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    Object? Function()? error,
  }) => SearchState(
    keyword: keyword ?? this.keyword,
    chart: chart ?? this.chart,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    error: error != null ? error() : this.error,
  );
}

class SearchController extends Notifier<SearchState> {
  static const debounce = Duration(milliseconds: 500);

  /// 一整页都被时长过滤掉时，最多再自动翻这么多页
  static const _maxEmptyFollows = 2;

  Timer? _timer;
  int _generation = 0;
  int _eraGeneration = 0;
  int _emptyFollows = 0;
  bool _dailyInFlight = false;
  DiscoverCharts? _charts;
  final _eras = <DiscoverTab, List<SearchHit>>{};
  final _eraPage = <DiscoverTab, int>{};
  final _eraMore = <DiscoverTab, bool>{};
  DiscoverTab _rankingTab = DiscoverTab.heat;
  DiscoverTab _eraTab = DiscoverTab.y2020;

  @override
  SearchState build() {
    ref.onDispose(() => _timer?.cancel());
    // 第一帧就是加载态。真正的请求由页面在帧后再发起。
    return const SearchState(loading: true);
  }

  /// 输入变化: 防抖 500ms 后搜索
  void onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(debounce, () => search(text));
  }

  /// 立即搜索 (回车 / 点击历史)
  Future<void> search(String text) async {
    _timer?.cancel();
    final keyword = text.trim();
    if (keyword.isEmpty) {
      _generation++;
      AppLogger.d('cleared', tag: 'search');
      state = SearchState(chart: state.chart);
      await loadDaily(force: true);
      return;
    }
    if (keyword == state.keyword && state.items.isNotEmpty) {
      AppLogger.d('skip duplicate "$keyword"', tag: 'search');
      return;
    }
    _emptyFollows = 0;
    state = SearchState(keyword: keyword, chart: state.chart, loading: true);
    unawaited(ref.read(searchHistoryProvider.notifier).add(keyword));
    await _load(1);
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    _emptyFollows = 0;
    if (state.keyword.isEmpty) {
      if (state.chart.group != DiscoverGroup.era) return;
      await _loadEra(state.chart, dailyGen: _generation, page: state.page + 1);
      return;
    }
    state = state.copyWith(loading: true, error: () => null);
    await _load(state.page + 1);
  }

  Future<void> retry() async {
    if (state.keyword.isEmpty) {
      if (state.chart.group == DiscoverGroup.era && state.items.isNotEmpty) {
        _emptyFollows = 0;
        await _loadEra(
          state.chart,
          dailyGen: _generation,
          page: state.page + 1,
        );
        return;
      }
      _generation++;
      state = SearchState(chart: state.chart);
      await loadDaily(force: true);
      return;
    }
    state = state.copyWith(loading: true, error: () => null);
    await _load(state.page + 1);
  }

  /// 这一档上次选中的 tab。切换排行榜和年代时用。
  DiscoverTab preferred(DiscoverGroup group) => switch (group) {
    DiscoverGroup.ranking => _rankingTab,
    DiscoverGroup.era => _eraTab,
  };

  /// 切换推荐 tab。排行榜已在内存里时不再请求；年代第一次点开才搜索。
  Future<void> selectChart(DiscoverTab tab) async {
    if (state.keyword.isNotEmpty || tab == state.chart) return;
    _remember(tab);
    if (tab.group == DiscoverGroup.ranking) {
      final charts = _charts;
      if (charts == null) {
        state = state.copyWith(chart: tab, items: const []);
        return;
      }
      state = SearchState(chart: tab, items: charts.of(tab));
      return;
    }
    final cached = _eras[tab];
    if (cached != null) {
      state = SearchState(
        chart: tab,
        items: cached,
        page: _eraPage[tab] ?? 1,
        hasMore: _eraMore[tab] ?? false,
      );
      return;
    }
    await _loadEra(tab, dailyGen: _generation);
  }

  void _remember(DiscoverTab tab) {
    switch (tab.group) {
      case DiscoverGroup.ranking:
        _rankingTab = tab;
      case DiscoverGroup.era:
        _eraTab = tab;
    }
  }

  /// 未搜索时加载音乐区推荐。已有推荐或正在搜索时不覆盖。
  ///
  /// [force] 用于清空搜索后重新拉榜。进行中的请求会被世代号丢掉。
  Future<void> loadDaily({bool force = false}) async {
    _timer?.cancel();
    if (state.keyword.isNotEmpty) return;
    if (_dailyInFlight && !force) return;
    final cached = _charts;
    if (!force && cached != null && state.error == null) {
      final tab = state.chart;
      if (tab.group == DiscoverGroup.era) {
        final era = _eras[tab];
        if (era != null) {
          state = SearchState(
            chart: tab,
            items: era,
            page: _eraPage[tab] ?? 1,
            hasMore: _eraMore[tab] ?? false,
          );
          return;
        }
        await _loadEra(tab, dailyGen: _generation);
        return;
      }
      state = SearchState(chart: tab, items: cached.of(tab));
      return;
    }
    _dailyInFlight = true;
    _emptyFollows = 0;
    if (force) {
      _eras.clear();
      _eraPage.clear();
      _eraMore.clear();
    }
    final gen = ++_generation;
    final chart = state.chart;
    state = SearchState(loading: true, chart: chart);
    AppLogger.d('load daily gen=$gen chart=$chart', tag: 'search');
    final Result<DiscoverCharts> result;
    try {
      result = await ref.read(searchRepositoryProvider).dailyPopular();
    } catch (e, st) {
      if (gen == _generation) _dailyInFlight = false;
      if (!ref.mounted || gen != _generation) return;
      AppLogger.e('daily failed', tag: 'search', error: e, stackTrace: st);
      _charts = null;
      if (state.chart.group == DiscoverGroup.era && state.keyword.isEmpty) {
        await _loadEra(state.chart, dailyGen: gen);
        return;
      }
      state = SearchState(loading: false, chart: state.chart, error: e);
      return;
    }
    if (gen == _generation) _dailyInFlight = false;
    if (!ref.mounted || gen != _generation || state.keyword.isNotEmpty) {
      AppLogger.d('stale daily dropped gen=$gen', tag: 'search');
      return;
    }
    final data = result.valueOrNull;
    if (data == null) {
      AppLogger.w('daily failed error=${result.errorOrNull}', tag: 'search');
      _charts = null;
      if (state.chart.group == DiscoverGroup.era) {
        await _loadEra(state.chart, dailyGen: gen);
        return;
      }
      state = SearchState(
        loading: false,
        chart: state.chart,
        error: result.errorOrNull,
      );
      return;
    }
    _charts = data;
    final tab = state.chart;
    if (tab.group == DiscoverGroup.era) {
      final era = _eras[tab];
      if (era != null) {
        state = SearchState(
          chart: tab,
          items: era,
          page: _eraPage[tab] ?? 1,
          hasMore: _eraMore[tab] ?? false,
        );
        return;
      }
      await _loadEra(tab, dailyGen: gen);
      return;
    }
    state = SearchState(chart: tab, items: data.of(tab));
  }

  Future<void> _loadEra(
    DiscoverTab tab, {
    required int dailyGen,
    int page = 1,
  }) async {
    final gen = ++_eraGeneration;
    final previous = page <= 1
        ? const <SearchHit>[]
        : List<SearchHit>.of(_eras[tab] ?? const []);
    if (page <= 1) {
      _emptyFollows = 0;
      state = SearchState(loading: true, chart: tab);
    } else {
      state = state.copyWith(loading: true, error: () => null);
    }
    final Result<SearchHitPage> result;
    try {
      result = await ref
          .read(searchRepositoryProvider)
          .eraChart(tab, page: page);
    } catch (e, st) {
      if (!_eraCurrent(tab, gen, dailyGen)) return;
      AppLogger.e('era failed', tag: 'search', error: e, stackTrace: st);
      state = page <= 1
          ? SearchState(loading: false, chart: tab, error: e)
          : state.copyWith(loading: false, error: () => e);
      return;
    }
    if (!_eraCurrent(tab, gen, dailyGen)) return;
    final data = result.valueOrNull;
    if (data == null) {
      state = page <= 1
          ? SearchState(
              loading: false,
              chart: tab,
              error: result.errorOrNull,
            )
          : state.copyWith(loading: false, error: () => result.errorOrNull);
      return;
    }
    final merged = _mergeEra(previous, data.items);
    final follow =
        merged.length == previous.length &&
        data.hasMore &&
        _emptyFollows < _maxEmptyFollows;
    _eras[tab] = merged;
    _eraPage[tab] = data.page;
    _eraMore[tab] = data.hasMore;
    if (state.keyword.isNotEmpty || state.chart != tab) return;
    state = SearchState(
      chart: tab,
      items: merged,
      page: data.page,
      hasMore: data.hasMore,
      loading: follow,
    );
    if (!follow) {
      _emptyFollows = 0;
      return;
    }
    _emptyFollows++;
    AppLogger.d(
      'empty era page, follow $_emptyFollows/$_maxEmptyFollows',
      tag: 'search',
    );
    await _loadEra(tab, dailyGen: dailyGen, page: data.page + 1);
  }

  List<SearchHit> _mergeEra(List<SearchHit> previous, List<SearchHit> incoming) {
    final seen = <String>{for (final hit in previous) _eraKey(hit)};
    return [
      ...previous,
      for (final hit in incoming)
        if (seen.add(_eraKey(hit))) hit,
    ];
  }

  String _eraKey(SearchHit hit) =>
      '${hit.result.bvid}:${hit.result.cid ?? hit.result.pageIndex ?? 0}';

  bool _eraCurrent(DiscoverTab tab, int gen, int dailyGen) {
    if (!ref.mounted || gen != _eraGeneration || dailyGen != _generation) {
      return false;
    }
    return state.keyword.isEmpty && state.chart == tab;
  }

  Future<void> _load(int page) async {
    final gen = ++_generation;
    final keyword = state.keyword;
    final loaded = state.items;
    AppLogger.d('load "$keyword" page=$page gen=$gen', tag: 'search');
    final result = await ref
        .read(searchRepositoryProvider)
        .search(
          keyword,
          page: page,
          onItems: (items) {
            if (!ref.mounted || gen != _generation) return;
            AppLogger.d(
              'partial "$keyword" page=$page shown=${items.length}',
              tag: 'search',
            );
            state = state.copyWith(
              items: [...loaded, ...items],
              loading: true,
              error: () => null,
            );
          },
        );
    if (!ref.mounted || gen != _generation) {
      AppLogger.d('stale result dropped page=$page gen=$gen', tag: 'search');
      return; // 已有更新的搜索, 丢弃过期结果
    }
    final data = result.valueOrNull;
    if (data == null) {
      _emptyFollows = 0;
      AppLogger.w(
        'load failed "$keyword" page=$page error=${result.errorOrNull}',
        tag: 'search',
      );
      state = state.copyWith(loading: false, error: () => result.errorOrNull);
      return;
    }
    final follow =
        data.items.isEmpty && data.hasMore && _emptyFollows < _maxEmptyFollows;
    state = state.copyWith(
      items: [...loaded, ...data.items],
      page: data.page,
      hasMore: data.hasMore,
      loading: follow,
      error: () => null,
    );
    if (!follow) {
      _emptyFollows = 0;
      return;
    }
    _emptyFollows++;
    AppLogger.d(
      'empty page, follow $_emptyFollows/$_maxEmptyFollows',
      tag: 'search',
    );
    await _load(data.page + 1);
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);

/// 搜索历史: 最近在前, 最多 20 条, 存 settings 表
class SearchHistory extends AsyncNotifier<List<String>> {
  static const _key = 'search_history';
  static const maxItems = 20;

  @override
  Future<List<String>> build() async {
    final raw = await ref.read(databaseProvider).settingsDao.get(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(String keyword) async {
    final current = await future;
    await _save(
      [keyword, ...current.where((k) => k != keyword)].take(maxItems).toList(),
    );
  }

  Future<void> remove(String keyword) async =>
      _save((await future).where((k) => k != keyword).toList());

  Future<void> clear() => _save(const []);

  Future<void> _save(List<String> list) async {
    state = AsyncData(list);
    await ref.read(databaseProvider).settingsDao.set(_key, jsonEncode(list));
  }
}

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistory, List<String>>(SearchHistory.new);
