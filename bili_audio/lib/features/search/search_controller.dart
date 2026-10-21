import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repositories/repositories.dart';

/// 搜索页状态 (M6.1)
class SearchState {
  const SearchState({
    this.keyword = '',
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loading = false,
    this.error,
  });

  final String keyword;
  final List<SearchHit> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final Object? error;

  SearchState copyWith({
    String? keyword,
    List<SearchHit>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    Object? Function()? error,
  }) => SearchState(
    keyword: keyword ?? this.keyword,
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

  @override
  SearchState build() {
    ref.onDispose(() => _timer?.cancel());
    return const SearchState();
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
      state = const SearchState();
      return;
    }
    if (keyword == state.keyword && state.items.isNotEmpty) return;
    _emptyFollows = 0;
    state = SearchState(keyword: keyword, loading: true);
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
    state = state.copyWith(loading: true, error: () => null);
    await _load(state.page + 1);
  }

  Future<void> _load(int page) async {
    final gen = ++_generation;
    final result = await ref
        .read(searchRepositoryProvider)
        .search(state.keyword, page: page);
    if (gen != _generation) return; // 已有更新的搜索, 丢弃过期结果
    final data = result.valueOrNull;
    if (data == null) {
      _emptyFollows = 0;
      state = state.copyWith(loading: false, error: () => result.errorOrNull);
      return;
    }
    final follow =
        data.items.isEmpty && data.hasMore && _emptyFollows < _maxEmptyFollows;
    state = state.copyWith(
      items: [...state.items, ...data.items],
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
