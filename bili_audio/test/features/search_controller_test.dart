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
}
