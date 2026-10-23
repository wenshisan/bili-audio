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
  Future<Result<DiscoverCharts>> dailyPopular() async =>
      const Result.success(DiscoverCharts());
}

class _ChartSearch implements SearchRepository {
  _ChartSearch({this.dailyGate, this.charts});

  final Completer<void>? dailyGate;
  final DiscoverCharts? charts;

  @override
  Future<Result<DiscoverCharts>> dailyPopular() async {
    final gate = dailyGate;
    if (gate != null) await gate.future;
    return Result.success(
      charts ??
          DiscoverCharts(
            heat: [_hit('daily')],
            rating: [_hit('daily')],
            chinese: [_hit('daily')],
          ),
    );
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
              chinese: [_hit('cn')],
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

    notifier.selectChart(DiscoverTab.rating);
    expect(
      container.read(searchControllerProvider).items.single.result.bvid,
      'rated',
    );

    notifier.selectChart(DiscoverTab.chinese);
    await notifier.search('歌');
    await notifier.search('');
    final end = container.read(searchControllerProvider);
    expect(end.keyword, isEmpty);
    expect(end.chart, DiscoverTab.chinese);
    expect(end.items.single.result.bvid, 'cn');
  });
}
