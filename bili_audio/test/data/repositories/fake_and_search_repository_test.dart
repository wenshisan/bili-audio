import 'package:bili_audio/core/utils/result.dart';
import 'package:bili_audio/data/bili/bili_search_api.dart';
import 'package:bili_audio/data/bili/models/search_result.dart';
import 'package:bili_audio/data/repositories/bili_repositories.dart';
import 'package:bili_audio/data/repositories/fake_repositories.dart';
import 'package:bili_audio/domain/entities/app_error.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';
import 'package:bili_audio/domain/title/title_cleaner.dart';
import 'package:bili_audio/domain/title/title_rule.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubSearchApi implements BiliSearchApi {
  @override
  Future<Result<SearchPage>> searchVideo({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    List<int> tids = const [3],
  }) async =>
      const Result.success(SearchPage(
        items: [
          SearchResult(
            bvid: 'BV1',
            title: 't',
            cleanTitle: '周杰伦 - 稻香',
            duration: 200,
            cover: '',
            author: 'UP',
            play: 1,
          ),
        ],
        page: 1,
        pageSize: 20,
        total: 1,
        hasMore: false,
      ));
}

void main() {
  test('BiliSearchRepository 对每条结果做标题清洗', () async {
    final cleaner = TitleCleaner(const TitleRuleConfig(version: 1, rules: [
      TitleRule(
        id: 'dash',
        type: 'split',
        pattern: r'\s-\s',
        order: 'artist_title',
        priority: 10,
      ),
    ]));
    final repo = BiliSearchRepository(_StubSearchApi(), cleaner);

    final page = (await repo.search('x')).valueOrNull!;

    expect(page.items.single.cleaned.name, '稻香');
    expect(page.items.single.cleaned.artist, '周杰伦');
  });

  group('Fake 仓储', () {
    test('搜索按关键词过滤, 并标记超长视频', () async {
      final repo = FakeSearchRepository(latency: Duration.zero);

      final all = (await repo.search('')).valueOrNull!;
      final some = (await repo.search('七里香')).valueOrNull!;

      expect(all.items.length, 5);
      expect(all.items.where((h) => h.result.filtered == true).length, 1);
      expect(some.items.single.cleaned.name, '七里香');
    });

    test('视频仓储: 超长返回 NotFound, 正常返回 1 个分P', () async {
      final repo = FakeVideoRepository();

      expect((await repo.getTracks('BV1fake00005')).errorOrNull,
          isA<NotFoundError>());
      expect((await repo.getTracks('BV1fake00001')).valueOrNull!.length, 1);
    });

    test('流仓储返回固定可播放地址', () async {
      final tracks =
          (await FakeVideoRepository().getTracks('BV1fake00001')).valueOrNull!;
      final s = (await FakeStreamRepository()
              .resolve(tracks.first, AudioQuality.k132))
          .valueOrNull!;
      expect(s.stream.url, startsWith('https://'));
    });
  });
}
