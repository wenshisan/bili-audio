import 'dart:async';

import 'package:bili_audio/app/providers.dart';
import 'package:bili_audio/core/utils/result.dart';
import 'package:bili_audio/data/bili/models/search_result.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/repositories/repositories.dart';
import 'package:bili_audio/domain/title/title_rule.dart';
import 'package:bili_audio/features/search/search_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

SearchHit _hit(String bvid) => (
  result: SearchResult(
    bvid: bvid,
    title: bvid,
    cleanTitle: bvid,
    duration: 180,
    cover: '',
    author: 'UP',
    play: 1,
  ),
  cleaned: CleanedTitle(name: bvid),
);

class _PartialSearch implements SearchRepository {
  final gate = Completer<void>();

  @override
  Future<Result<SearchHitPage>> search(
    String keyword, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async {
    onItems?.call([_hit('early')]);
    await gate.future;
    final items = [_hit('early'), _hit('late')];
    onItems?.call(items);
    return Result.success((
      items: items,
      page: page,
      total: items.length,
      hasMore: false,
    ));
  }

  @override
  Future<Result<DiscoverCharts>> dailyPopular({
    void Function(DiscoverCharts charts)? onCharts,
  }) async => const Result.success(DiscoverCharts());

  @override
  Future<Result<SearchHitPage>> eraChart(
    DiscoverTab tab, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async =>
      const Result.success((items: [], page: 1, total: 0, hasMore: false));
}

class _PartialEra implements SearchRepository {
  final gate = Completer<void>();

  @override
  Future<Result<DiscoverCharts>> dailyPopular({
    void Function(DiscoverCharts charts)? onCharts,
  }) async => const Result.success(DiscoverCharts());

  @override
  Future<Result<SearchHitPage>> eraChart(
    DiscoverTab tab, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async {
    onItems?.call([_hit('early')]);
    await gate.future;
    final items = [_hit('early'), _hit('late')];
    onItems?.call(items);
    return Result.success((
      items: items,
      page: page,
      total: items.length,
      hasMore: false,
    ));
  }

  @override
  Future<Result<SearchHitPage>> search(
    String keyword, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async =>
      const Result.success((items: [], page: 1, total: 0, hasMore: false));
}

class _ChartSearch implements SearchRepository {
  _ChartSearch({this.dailyGate, this.charts});

  final Completer<void>? dailyGate;
  final DiscoverCharts? charts;

  @override
  Future<Result<DiscoverCharts>> dailyPopular({
    void Function(DiscoverCharts charts)? onCharts,
  }) async {
    final gate = dailyGate;
    if (gate != null) await gate.future;
    final data =
        charts ??
        DiscoverCharts(heat: [_hit('daily')], rating: [_hit('daily')]);
    onCharts?.call(data);
    return Result.success(data);
  }

  @override
  Future<Result<SearchHitPage>> eraChart(
    DiscoverTab tab, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async {
    final items = [_hit(tab.name)];
    onItems?.call(items);
    return Result.success((items: items, page: page, total: 1, hasMore: false));
  }

  @override
  Future<Result<SearchHitPage>> search(
    String keyword, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async => Result.success((
    items: [_hit(keyword)],
    page: page,
    total: 1,
    hasMore: false,
  ));
}

void main() {
  test('有结果时先写入列表，不等这一页全部结束', () async {
    final db = AppDatabase.memory();
    final repo = _PartialSearch();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        searchRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(() async {
      await container.read(searchHistoryProvider.future);
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      await db.close();
    });

    final done = container.read(searchControllerProvider.notifier).search('歌');
    final mid = container.read(searchControllerProvider);
    expect(mid.loading, isTrue);
    expect(mid.items.map((hit) => hit.result.bvid), ['early']);

    repo.gate.complete();
    await done;
    final end = container.read(searchControllerProvider);
    expect(end.loading, isFalse);
    expect(end.items.map((hit) => hit.result.bvid), ['early', 'late']);
  });

  test('年代对上一首就写入列表，不等这一页全部结束', () async {
    final db = AppDatabase.memory();
    final repo = _PartialEra();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        searchRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(() async {
      if (!repo.gate.isCompleted) repo.gate.complete();
      await container.read(searchHistoryProvider.future);
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      await db.close();
    });

    final done = container
        .read(searchControllerProvider.notifier)
        .selectChart(DiscoverTab.y1990);
    final mid = container.read(searchControllerProvider);
    expect(mid.loading, isTrue);
    expect(mid.chart, DiscoverTab.y1990);
    expect(mid.items.map((hit) => hit.result.bvid), ['early']);

    repo.gate.complete();
    await done;
    final end = container.read(searchControllerProvider);
    expect(end.loading, isFalse);
    expect(end.items.map((hit) => hit.result.bvid), ['early', 'late']);
  });

  test('未搜索时加载今日推荐，清空搜索后重新加载', () async {
    final db = AppDatabase.memory();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        searchRepositoryProvider.overrideWithValue(_ChartSearch()),
      ],
    );
    addTearDown(() async {
      await container.read(searchHistoryProvider.future);
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      await db.close();
    });

    final notifier = container.read(searchControllerProvider.notifier);
    await notifier.loadDaily();
    expect(
      container.read(searchControllerProvider).items.single.result.bvid,
      'daily',
    );

    await notifier.search('歌');
    expect(container.read(searchControllerProvider).keyword, '歌');
    expect(
      container.read(searchControllerProvider).items.single.result.bvid,
      '歌',
    );

    await notifier.search('');
    final cleared = container.read(searchControllerProvider);
    expect(cleared.keyword, isEmpty);
    expect(cleared.loading, isFalse);
    expect(cleared.items.single.result.bvid, 'daily');
  });

  test('搜索开始后，迟到的今日推荐不再写回', () async {
    final db = AppDatabase.memory();
    final gate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        searchRepositoryProvider.overrideWithValue(
          _ChartSearch(dailyGate: gate),
        ),
      ],
    );
    addTearDown(() async {
      if (!gate.isCompleted) gate.complete();
      await container.read(searchHistoryProvider.future);
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      await db.close();
    });

    final notifier = container.read(searchControllerProvider.notifier);
    final daily = notifier.loadDaily();
    await notifier.search('歌');
    gate.complete();
    await daily;

    final end = container.read(searchControllerProvider);
    expect(end.keyword, '歌');
    expect(end.items.single.result.bvid, '歌');
  });

  test('推荐 tab 切换对应列表，清空搜索后仍停在该 tab', () async {
    final db = AppDatabase.memory();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        searchRepositoryProvider.overrideWithValue(
          _ChartSearch(
            charts: DiscoverCharts(
              heat: [_hit('hot')],
              rating: [_hit('rated')],
              zones: {
                DiscoverTab.original: [_hit('orig')],
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(() async {
      await container.read(searchHistoryProvider.future);
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      await db.close();
    });

    final notifier = container.read(searchControllerProvider.notifier);
    await notifier.loadDaily();
    expect(container.read(searchControllerProvider).chart, DiscoverTab.heat);
    expect(
      container.read(searchControllerProvider).items.single.result.bvid,
      'hot',
    );

    await notifier.selectChart(DiscoverTab.rating);
    expect(
      container.read(searchControllerProvider).items.single.result.bvid,
      'rated',
    );

    await notifier.selectChart(DiscoverTab.original);
    await notifier.search('歌');
    await notifier.search('');
    final end = container.read(searchControllerProvider);
    expect(end.keyword, isEmpty);
    expect(end.chart, DiscoverTab.original);
    expect(end.items.single.result.bvid, 'orig');
  });

  test('年代分区按需加载，切回排行榜后仍记得上次的年代', () async {
    final db = AppDatabase.memory();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        searchRepositoryProvider.overrideWithValue(_ChartSearch()),
      ],
    );
    addTearDown(() async {
      await container.read(searchHistoryProvider.future);
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      await db.close();
    });

    final notifier = container.read(searchControllerProvider.notifier);
    await notifier.loadDaily();
    await notifier.selectChart(DiscoverTab.y1990);
    expect(container.read(searchControllerProvider).chart, DiscoverTab.y1990);
    expect(
      container.read(searchControllerProvider).items.single.result.bvid,
      'y1990',
    );

    await notifier.selectChart(DiscoverTab.rating);
    expect(
      container.read(searchControllerProvider).items.single.result.bvid,
      'daily',
    );

    await notifier.selectChart(notifier.preferred(DiscoverGroup.era));
    final end = container.read(searchControllerProvider);
    expect(end.chart, DiscoverTab.y1990);
    expect(end.items.single.result.bvid, 'y1990');
    expect(end.loading, isFalse);
  });

  test('年代滑到底追加下一页，排行榜不再翻页', () async {
    final db = AppDatabase.memory();
    final repo = _PagingEra({
      1: (items: [_hit('p1')], hasMore: true),
      2: (items: [_hit('p1'), _hit('p2')], hasMore: false),
    });
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        searchRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(() async {
      await container.read(searchHistoryProvider.future);
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      await db.close();
    });

    final notifier = container.read(searchControllerProvider.notifier);
    await notifier.loadDaily();
    await notifier.loadMore();
    expect(repo.calls, isEmpty);
    expect(
      container.read(searchControllerProvider).items.single.result.bvid,
      'hot',
    );

    await notifier.selectChart(DiscoverTab.y1990);
    expect(repo.calls, [1]);
    expect(
      container.read(searchControllerProvider).items.map((h) => h.result.bvid),
      ['p1'],
    );
    expect(container.read(searchControllerProvider).hasMore, isTrue);

    await notifier.loadMore();
    final loaded = container.read(searchControllerProvider);
    expect(repo.calls, [1, 2]);
    expect(loaded.items.map((h) => h.result.bvid), ['p1', 'p2']);
    expect(loaded.page, 2);
    expect(loaded.hasMore, isFalse);
    expect(loaded.loading, isFalse);

    await notifier.loadMore();
    expect(repo.calls, [1, 2]);

    await notifier.selectChart(DiscoverTab.heat);
    await notifier.selectChart(DiscoverTab.y1990);
    final restored = container.read(searchControllerProvider);
    expect(restored.items.map((h) => h.result.bvid), ['p1', 'p2']);
    expect(restored.hasMore, isFalse);
    expect(repo.calls, [1, 2]);
  });

  test('年代这一页被滤空时自动请求下一页', () async {
    final db = AppDatabase.memory();
    final repo = _PagingEra({
      1: (items: const [], hasMore: true),
      2: (items: [_hit('p2')], hasMore: false),
    });
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        searchRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(() async {
      await container.read(searchHistoryProvider.future);
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      await db.close();
    });

    final notifier = container.read(searchControllerProvider.notifier);
    await notifier.loadDaily();
    await notifier.selectChart(DiscoverTab.y1990);
    final end = container.read(searchControllerProvider);
    expect(repo.calls, [1, 2]);
    expect(end.items.single.result.bvid, 'p2');
    expect(end.hasMore, isFalse);
    expect(end.loading, isFalse);
  });
}

class _PagingEra implements SearchRepository {
  _PagingEra(this._pages);

  final Map<int, ({List<SearchHit> items, bool hasMore})> _pages;
  final calls = <int>[];

  @override
  Future<Result<DiscoverCharts>> dailyPopular({
    void Function(DiscoverCharts charts)? onCharts,
  }) async {
    final data = DiscoverCharts(heat: [_hit('hot')]);
    onCharts?.call(data);
    return Result.success(data);
  }

  @override
  Future<Result<SearchHitPage>> eraChart(
    DiscoverTab tab, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async {
    calls.add(page);
    final data = _pages[page]!;
    if (data.items.isNotEmpty) onItems?.call(data.items);
    return Result.success((
      items: data.items,
      page: page,
      total: 2,
      hasMore: data.hasMore,
    ));
  }

  @override
  Future<Result<SearchHitPage>> search(
    String keyword, {
    int page = 1,
    void Function(List<SearchHit> items)? onItems,
  }) async =>
      const Result.success((items: [], page: 1, total: 0, hasMore: false));
}
