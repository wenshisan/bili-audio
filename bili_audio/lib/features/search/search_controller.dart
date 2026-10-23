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
  int _emptyFollows = 0;
  bool _dailyInFlight = false;
  DiscoverCharts? _charts;

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
    state = state.copyWith(loading: true, error: () => null);
    await _load(state.page + 1);
  }

  Future<void> retry() async {
    if (state.keyword.isEmpty) {
      _generation++;
      state = SearchState(chart: state.chart);
      await loadDaily(force: true);
      return;
    }
    state = state.copyWith(loading: true, error: () => null);
    await _load(state.page + 1);
  }

  /// 切换推荐 tab。榜已经在内存里时不再请求。
  void selectChart(DiscoverTab tab) {
    if (state.keyword.isNotEmpty || tab == state.chart) return;
    final charts = _charts;
    if (charts == null) {
      state = state.copyWith(chart: tab);
      return;
    }
    state = SearchState(chart: tab, items: charts.of(tab));
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
      state = SearchState(chart: state.chart, items: cached.of(state.chart));
      return;
    }
    _dailyInFlight = true;
    _emptyFollows = 0;
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
      state = SearchState(
        loading: false,
        chart: state.chart,
        error: result.errorOrNull,
      );
      return;
    }
    _charts = data;
    state = SearchState(chart: state.chart, items: data.of(state.chart));
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
