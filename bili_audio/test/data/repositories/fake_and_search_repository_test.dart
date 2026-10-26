import 'dart:async';

import 'package:bili_audio/core/utils/result.dart';
import 'package:bili_audio/data/bili/bili_ranking_api.dart';
import 'package:bili_audio/data/bili/bili_search_api.dart';
import 'package:bili_audio/data/bili/models/search_result.dart';
import 'package:bili_audio/data/repositories/bili_repositories.dart';
import 'package:bili_audio/data/repositories/repositories.dart';
import 'package:bili_audio/data/repositories/fake_repositories.dart';
import 'package:bili_audio/domain/entities/app_error.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';
import 'package:bili_audio/domain/entities/video.dart';
import 'package:bili_audio/domain/title/title_cleaner.dart';
import 'package:bili_audio/domain/title/title_rule.dart';
import 'package:flutter_test/flutter_test.dart';

SearchResult _item(String bvid, String title, int duration) => SearchResult(
  bvid: bvid,
  title: title,
  cleanTitle: title,
  duration: duration,
  cover: '',
  author: 'UP',
  play: 1,
  filtered: duration > 900,
);

class _ListSearchApi implements BiliSearchApi {
  _ListSearchApi(this.items);

  final List<SearchResult> items;

  @override
  Future<Result<SearchPage>> searchVideo({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    List<int> tids = const [3],
    String? order,
    int? duration,
  }) async => Result.success(
    SearchPage(
      items: items,
      page: page,
      pageSize: pageSize,
      total: items.length,
      hasMore: false,
    ),
  );
}

class _Chart implements MusicChartSource {
  _Chart(this.items, {this.zones = const {}});

  final List<SearchResult> items;
  final Map<MusicZone, List<SearchResult>> zones;

  @override
  Future<Result<MusicChartBundle>> dailyMusic() async => Result.success(
    MusicChartBundle(heat: items, rating: items, zones: zones),
  );
}

class _EraSearchApi implements BiliSearchApi {
  String? keyword;
  String? order;
  int? duration;
  int? pageSize;
  List<int>? tids;

  @override
  Future<Result<SearchPage>> searchVideo({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    List<int> tids = const [3],
    String? order,
    int? duration,
  }) async {
    this.keyword = keyword;
    this.order = order;
    this.duration = duration;
    this.pageSize = pageSize;
    this.tids = tids;
    return Result.success(
      SearchPage(
        items: [
          _item('BVera', '90年代 晴天', 180),
          _item('BVlong', '90年代 演唱会', 1200),
          _item('BVera', '90年代 晴天 重复', 200),
        ],
        page: page,
        pageSize: pageSize,
        total: 3,
        hasMore: false,
      ),
    );
  }
}

class _StubSearchApi implements BiliSearchApi {
  @override
  Future<Result<SearchPage>> searchVideo({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    List<int> tids = const [3],
    String? order,
    int? duration,
  }) async => const Result.success(
    SearchPage(
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
    ),
  );
}

void main() {
  test('BiliSearchRepository 对每条结果做标题清洗', () async {
    final cleaner = TitleCleaner(
      const TitleRuleConfig(
        version: 1,
        rules: [
          TitleRule(
            id: 'dash',
            type: 'split',
            pattern: r'\s-\s',
            order: 'artist_title',
            priority: 10,
          ),
        ],
      ),
    );
    final repo = BiliSearchRepository(_StubSearchApi(), cleaner);

    final page = (await repo.search('x')).valueOrNull!;

    expect(page.items.single.cleaned.name, '稻香');
    expect(page.items.single.cleaned.artist, '周杰伦');
  });

  test('超过 15 分钟的单视频不返回，分P按每一P展开', () async {
    final cleaner = TitleCleaner(
      const TitleRuleConfig(
        version: 1,
        rules: [
          TitleRule(
            id: 'dash',
            type: 'split',
            pattern: r'\s-\s',
            order: 'artist_title',
            priority: 10,
          ),
        ],
      ),
    );
    final repo = BiliSearchRepository(
      _ListSearchApi([
        _item('BVlong', '超长单曲', 960),
        _item('BVmulti', '歌曲合集', 2400),
        _item('BVshort', '周杰伦 - 晴天', 180),
      ]),
      cleaner,
      pageList: (bvid) async {
        if (bvid == 'BVlong') {
          return const Result.success([
            VideoPage(
              cid: 9,
              title: '完整版',
              duration: Duration(seconds: 960),
              pageIndex: 1,
            ),
          ]);
        }
        if (bvid == 'BVmulti') {
          return const Result.success([
            VideoPage(
              cid: 1,
              title: 'P1',
              duration: Duration(seconds: 200),
              pageIndex: 1,
            ),
            VideoPage(
              cid: 2,
              title: '周杰伦 - 稻香',
              duration: Duration(seconds: 210),
              pageIndex: 2,
            ),
            VideoPage(
              cid: 3,
              title: '现场',
              duration: Duration(seconds: 1000),
              pageIndex: 3,
            ),
          ]);
        }
        return const Result.failure(AppError.notFound());
      },
    );

    final items = (await repo.search('x')).valueOrNull!.items;

    expect(items.map((h) => h.result.bvid), ['BVmulti', 'BVmulti', 'BVshort']);
    expect(items[0].result.cid, 1);
    expect(items[0].cleaned.name, '歌曲合集');
    expect(items[0].result.pageIndex, 1);
    expect(items[0].result.totalPages, 3);
    expect(items[1].result.cid, 2);
    expect(items[1].cleaned.name, '稻香');
    expect(items[1].cleaned.artist, '周杰伦');
    expect(items[1].result.duration, 210);
    expect(items[2].result.bvid, 'BVshort');
    expect(items[2].result.cid, isNull);
  });

  test('短视频先交出去，不等待其余分P', () async {
    final cleaner = TitleCleaner(const TitleRuleConfig(version: 1, rules: []));
    final gates = {
      for (final bvid in ['BVlong', 'BVmulti', 'BVshort'])
        bvid: Completer<void>(),
    };
    final repo = BiliSearchRepository(
      _ListSearchApi([
        _item('BVlong', '超长单曲', 960),
        _item('BVmulti', '歌曲合集', 2400),
        _item('BVshort', '晴天', 180),
      ]),
      cleaner,
      pageList: (bvid) async {
        await gates[bvid]!.future;
        if (bvid == 'BVshort') {
          return const Result.success([
            VideoPage(
              cid: 7,
              title: 'P1',
              duration: Duration(seconds: 180),
              pageIndex: 1,
            ),
          ]);
        }
        if (bvid == 'BVmulti') {
          return const Result.success([
            VideoPage(
              cid: 1,
              title: '第一首',
              duration: Duration(seconds: 200),
              pageIndex: 1,
            ),
            VideoPage(
              cid: 2,
              title: '第二首',
              duration: Duration(seconds: 210),
              pageIndex: 2,
            ),
          ]);
        }
        return const Result.success([
          VideoPage(
            cid: 9,
            title: '完整版',
            duration: Duration(seconds: 960),
            pageIndex: 1,
          ),
        ]);
      },
    );

    final snapshots = <List<({String bvid, int? cid})>>[];
    final pending = repo.search(
      'x',
      onItems: (items) {
        snapshots.add([
          for (final hit in items) (bvid: hit.result.bvid, cid: hit.result.cid),
        ]);
      },
    );

    for (var i = 0; i < 20 && snapshots.isEmpty; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(snapshots.single.map((hit) => hit.bvid), ['BVshort']);
    expect(snapshots.single.single.cid, isNull);

    gates['BVshort']!.complete();
    for (var i = 0; i < 20 && snapshots.last.single.cid == null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(snapshots.last.map((hit) => hit.bvid), ['BVshort']);
    expect(snapshots.last.single.cid, 7);
    expect(
      snapshots.every((items) => items.every((hit) => hit.bvid == 'BVshort')),
      isTrue,
    );

    gates['BVlong']!.complete();
    gates['BVmulti']!.complete();
    final items = (await pending).valueOrNull!.items;
    expect(items.map((hit) => hit.result.bvid), [
      'BVmulti',
      'BVmulti',
      'BVshort',
    ]);
    expect(items.map((hit) => hit.result.cid), [1, 2, 7]);
  });

  test('今日热门保留榜单顺序，展开多 P，丢掉超长单视频', () async {
    final cleaner = TitleCleaner(
      const TitleRuleConfig(
        version: 1,
        rules: [
          TitleRule(
            id: 'dash',
            type: 'split',
            pattern: r'\s-\s',
            order: 'artist_title',
            priority: 10,
          ),
        ],
      ),
    );
    final repo = BiliSearchRepository(
      _StubSearchApi(),
      cleaner,
      ranking: _Chart(
        [
          _item('BVlong', '超长单曲', 960),
          _item('BVmulti', '歌曲合集', 2400).copyWith(totalPages: 3),
          _item('BVshort', '周杰伦 - 晴天', 180).copyWith(cid: 8),
        ],
        zones: {
          MusicZone.original: [_item('BVshort', '周杰伦 - 晴天', 180)],
        },
      ),
      pageList: (bvid) async {
        if (bvid != 'BVmulti') {
          return const Result.failure(AppError.notFound());
        }
        return const Result.success([
          VideoPage(
            cid: 1,
            title: 'P1',
            duration: Duration(seconds: 200),
            pageIndex: 1,
          ),
          VideoPage(
            cid: 2,
            title: '周杰伦 - 稻香',
            duration: Duration(seconds: 210),
            pageIndex: 2,
          ),
          VideoPage(
            cid: 3,
            title: '现场',
            duration: Duration(seconds: 1000),
            pageIndex: 3,
          ),
        ]);
      },
    );

    final charts = (await repo.dailyPopular()).valueOrNull!;
    final items = charts.heat;

    expect(items.map((hit) => hit.result.bvid), [
      'BVmulti',
      'BVmulti',
      'BVshort',
    ]);
    expect(items[0].result.cid, 1);
    expect(items[1].cleaned.name, '稻香');
    expect(items[1].result.duration, 210);
    expect(items[2].result.cid, 8);
    expect(items[2].cleaned.name, '晴天');
    expect(items[2].cleaned.artist, '周杰伦');
    expect(charts.of(DiscoverTab.original).single.result.bvid, 'BVshort');
  });

  test('年代推荐按播放量搜索短视频，并去掉超长和重复', () async {
    final api = _EraSearchApi();
    final repo = BiliSearchRepository(
      api,
      TitleCleaner(const TitleRuleConfig(version: 1, rules: [])),
    );

    final items = (await repo.eraChart(DiscoverTab.y1990)).valueOrNull!;

    expect(api.keyword, BiliSearchRepository.eraKeyword[DiscoverTab.y1990]);
    expect(api.order, 'click');
    expect(api.duration, BiliSearchRepository.eraDurationBand);
    expect(api.pageSize, BiliSearchRepository.eraPageSize);
    expect(api.tids, [3]);
    expect(items.map((hit) => hit.result.bvid), ['BVera']);
    expect(items.single.result.duration, 180);
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

      expect(
        (await repo.getTracks('BV1fake00005')).errorOrNull,
        isA<NotFoundError>(),
      );
      expect((await repo.getTracks('BV1fake00001')).valueOrNull!.length, 1);
    });

    test('流仓储返回固定可播放地址', () async {
      final tracks = (await FakeVideoRepository().getTracks('BV1fake00001'))
          .valueOrNull!;
      final s = (await FakeStreamRepository().resolve(
        tracks.first,
        AudioQuality.k132,
      )).valueOrNull!;
      expect(s.stream.url, startsWith('https://'));
    });
  });
}
