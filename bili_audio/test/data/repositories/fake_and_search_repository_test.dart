import 'dart:async';

import 'package:bili_audio/core/utils/result.dart';
import 'package:bili_audio/data/bili/bili_ranking_api.dart';
import 'package:bili_audio/data/bili/bili_search_api.dart';
import 'package:bili_audio/data/bili/models/search_result.dart';
import 'package:bili_audio/data/era/era_catalog.dart';
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
  _EraSearchApi({List<SearchResult>? items}) : items = items ?? _defaults;

  static final _defaults = [
    _item('BVera', '90年代 晴天', 180),
    _item('BVlong', '90年代 演唱会', 1200),
    _item('BVera', '90年代 晴天 重复', 200),
  ];

  final List<SearchResult> items;
  String? keyword;
  String? order;
  int? duration;
  int? pageSize;
  int? requestedPage;
  List<int>? tids;
  bool hasMore = false;

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
    requestedPage = page;
    this.tids = tids;
    return Result.success(
      SearchPage(
        items: items,
        page: page,
        pageSize: pageSize,
        total: items.length,
        hasMore: hasMore,
      ),
    );
  }
}

class _SongLookupApi implements BiliSearchApi {
  final keywords = <String>[];
  String? order;

  @override
  Future<Result<SearchPage>> searchVideo({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    List<int> tids = const [3],
    String? order,
    int? duration,
  }) async {
    keywords.add(keyword);
    this.order = order;
    final items = switch (keyword) {
      '周杰伦 晴天' => [
        _item('BVmix', '晴天 合集', 4000),
        _item('BVsong', '周杰伦 - 晴天', 260),
      ],
      '周杰伦 稻香' => [_item('BVlive', '周杰伦 稻香 演唱会', 5000)],
      _ => const <SearchResult>[],
    };
    return Result.success(
      SearchPage(
        items: items,
        page: page,
        pageSize: pageSize,
        total: items.length,
        hasMore: false,
      ),
    );
  }
}

class _FixedEraCatalog implements EraCatalog {
  @override
  Future<Result<EraCatalogPage>> page(DiscoverTab tab, {int page = 1}) async =>
      const Result.success((
        tracks: [
          EraTrack(name: '晴天', artist: '周杰伦', duration: Duration(seconds: 269)),
          EraTrack(name: '稻香', artist: '周杰伦', duration: Duration(seconds: 210)),
          EraTrack(
            name: '没有这首',
            artist: '未知',
            duration: Duration(seconds: 200),
          ),
        ],
        page: 1,
        total: 3,
        hasMore: false,
      ));
}

class _DownEraCatalog implements EraCatalog {
  @override
  Future<Result<EraCatalogPage>> page(DiscoverTab tab, {int page = 1}) async =>
      const Result.failure(AppError.network(message: 'down'));
}

class _ZoneSearchApi implements BiliSearchApi {
  final keywords = <String>[];
  final pages = <int>[];
  List<int>? tids;
  int? pageSize;

  /// 翻唱和歌曲翻到这一页为止，其余关键词只有一页。
  var followPages = 1;

  @override
  Future<Result<SearchPage>> searchVideo({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    List<int> tids = const [3],
    String? order,
    int? duration,
  }) async {
    keywords.add(keyword);
    pages.add(page);
    this.tids = tids;
    this.pageSize = pageSize;
    final followed = (keyword == '翻唱' || keyword == '歌曲') && followPages > 1;
    final items = keyword == '翻唱' && page == 1
        ? [
            _item('BVrank', '榜上翻唱 重复', 180),
            _item('BVlong', '翻唱合集', 1200),
            _item('BVshort', '过短', 20),
            _item('BVfound', '别的分区里的翻唱', 200),
          ]
        : followed
        ? [_item('BV${keyword.hashCode}_$page', '$keyword 第$page页', 180)]
        : const <SearchResult>[];
    return Result.success(
      SearchPage(
        items: items,
        page: page,
        pageSize: pageSize,
        total: items.length,
        hasMore: followed && page < followPages,
      ),
    );
  }
}

class _StubSearchApi implements BiliSearchApi {
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
    this.tids = tids;
    if (order == 'click') {
      return const Result.success(
        SearchPage(items: [], page: 1, pageSize: 20, total: 0, hasMore: false),
      );
    }
    return const Result.success(
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
    final api = _StubSearchApi();
    final repo = BiliSearchRepository(api, cleaner);

    final page = (await repo.search('x')).valueOrNull!;

    expect(api.tids, isEmpty);
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

  test('排行榜分区补上全站搜索结果', () async {
    final api = _ZoneSearchApi();
    final repo = BiliSearchRepository(
      api,
      TitleCleaner(const TitleRuleConfig(version: 1, rules: [])),
      ranking: _Chart(
        [_item('BVheat', '热门', 180)],
        zones: {
          MusicZone.cover: [_item('BVrank', '榜上翻唱', 200)],
        },
      ),
    );

    final charts = (await repo.dailyPopular()).valueOrNull!;
    final cover = charts.of(DiscoverTab.cover);

    expect(api.keywords, contains('翻唱'));
    expect(api.tids, isEmpty);
    expect(api.pageSize, BiliSearchRepository.zoneSearchSize);
    expect(cover.map((hit) => hit.result.bvid), ['BVrank', 'BVfound']);
    expect(charts.heat.single.result.bvid, 'BVheat');
  });

  test('榜上其他分区的稿件按标题进入分类', () async {
    final repo = BiliSearchRepository(
      _StubSearchApi(),
      TitleCleaner(const TitleRuleConfig(version: 1, rules: [])),
      ranking: _Chart([
        _item('BVai', '影视区 AIMV 大赛', 180),
        _item('BVcover', '舞蹈区翻唱', 200),
        _item('BVother', '游戏实况', 180),
      ]),
    );

    final charts = (await repo.dailyPopular()).valueOrNull!;

    expect(charts.of(DiscoverTab.ai).map((hit) => hit.result.bvid), ['BVai']);
    expect(charts.of(DiscoverTab.cover).map((hit) => hit.result.bvid), [
      'BVcover',
    ]);
    expect(charts.heat.map((hit) => hit.result.bvid), [
      'BVai',
      'BVcover',
      'BVother',
    ]);
  });

  test('排行榜按播放量连续翻页，热度榜后面接上更多歌曲', () async {
    final api = _ZoneSearchApi()
      ..followPages = BiliSearchRepository.zoneSearchPages;
    final repo = BiliSearchRepository(
      api,
      TitleCleaner(const TitleRuleConfig(version: 1, rules: [])),
      ranking: _Chart([_item('BVheat', '热门', 180)]),
    );

    final charts = (await repo.dailyPopular()).valueOrNull!;
    final coverPages = [
      for (var i = 0; i < api.keywords.length; i++)
        if (api.keywords[i] == '翻唱') api.pages[i],
    ];

    expect(coverPages, [
      for (var page = 1; page <= BiliSearchRepository.zoneSearchPages; page++)
        page,
    ]);
    expect(charts.heat.length, BiliSearchRepository.zoneSearchPages + 1);
    expect(charts.heat.first.result.bvid, 'BVheat');
    expect(
      charts.of(DiscoverTab.cover).length,
      1 + BiliSearchRepository.zoneSearchPages,
    );
  });

  test('年代推荐按播放量搜索，丢掉跨年代、过短、超长和重复', () async {
    final api = _EraSearchApi()..hasMore = true;
    final repo = BiliSearchRepository(
      api,
      TitleCleaner(const TitleRuleConfig(version: 1, rules: [])),
    );

    final page = (await repo.eraChart(DiscoverTab.y1990)).valueOrNull!;
    final items = page.items;

    expect(api.keyword, BiliSearchRepository.eraKeyword[DiscoverTab.y1990]);
    expect(api.order, 'click');
    expect(api.duration, isNull);
    expect(api.pageSize, BiliSearchRepository.eraPageSize);
    expect(api.requestedPage, 1);
    expect(api.tids, isEmpty);
    expect(page.page, 1);
    expect(page.hasMore, isTrue);
    await repo.eraChart(DiscoverTab.y1990, page: 2);
    expect(api.requestedPage, 2);
    expect(items.map((hit) => hit.result.bvid), ['BVera']);
    expect(items.single.result.duration, 180);
  });

  test('年代推荐只收这一年代，并把合集拆成单曲', () async {
    expect(BiliSearchRepository.erasMentioned('70、80、90年代经典老歌'), {
      DiscoverTab.y1970,
      DiscoverTab.y1980,
      DiscoverTab.y1990,
    });
    expect(BiliSearchRepository.erasMentioned('1990-1999年最强华语金曲'), {
      DiscoverTab.y1990,
    });
    expect(BiliSearchRepository.erasMentioned('2020年代流行歌曲'), {
      DiscoverTab.y2020,
    });
    expect(BiliSearchRepository.erasMentioned('2000-2009年最强华语金曲'), {
      DiscoverTab.y2000,
    });
    expect(BiliSearchRepository.erasMentioned('8090歌曲合集'), isEmpty);

    final calls = <String>[];
    final api = _EraSearchApi(
      items: [
        _item('BVmix', '70、80、90年代经典老歌', 5000),
        _item('BV80', '80年代经典老歌', 200),
        _item('BV90', '90年代经典歌曲合集', 3600),
        _item('BV90short', '九十年代 同桌的你', 200),
        _item('BVclip', '90年代 片头', 30),
      ],
    );
    final repo = BiliSearchRepository(
      api,
      TitleCleaner(const TitleRuleConfig(version: 1, rules: [])),
      pageList: (bvid) async {
        calls.add(bvid);
        if (bvid != 'BV90') {
          return const Result.failure(AppError.notFound());
        }
        return const Result.success([
          VideoPage(
            cid: 1,
            title: '片头',
            duration: Duration(seconds: 20),
            pageIndex: 1,
          ),
          VideoPage(
            cid: 2,
            title: '周杰伦 - 晴天',
            duration: Duration(seconds: 210),
            pageIndex: 2,
          ),
          VideoPage(
            cid: 3,
            title: '演唱会串烧',
            duration: Duration(seconds: 1000),
            pageIndex: 3,
          ),
        ]);
      },
    );

    final items = (await repo.eraChart(DiscoverTab.y1990)).valueOrNull!.items;

    expect(calls, ['BV90']);
    expect(items.map((hit) => hit.result.bvid), ['BV90', 'BV90short']);
    expect(items.first.result.cid, 2);
    expect(items.first.result.cleanTitle, '周杰伦 - 晴天');
    expect(items.first.result.duration, 210);
    expect(items.last.result.bvid, 'BV90short');
  });

  test('年代歌单用歌名到 B 站找单曲，对不上的丢掉', () async {
    final calls = <String>[];
    final api = _SongLookupApi();
    final repo = BiliSearchRepository(
      api,
      TitleCleaner(const TitleRuleConfig(version: 1, rules: [])),
      eraCatalog: _FixedEraCatalog(),
      pageList: (bvid) async {
        calls.add(bvid);
        if (bvid != 'BVlive') return const Result.failure(AppError.notFound());
        return const Result.success([
          VideoPage(
            cid: 1,
            title: '片头',
            duration: Duration(seconds: 20),
            pageIndex: 1,
          ),
          VideoPage(
            cid: 2,
            title: '周杰伦 - 稻香',
            duration: Duration(seconds: 210),
            pageIndex: 2,
          ),
        ]);
      },
    );

    final page = (await repo.eraChart(DiscoverTab.y2020)).valueOrNull!;

    expect(api.keywords, ['周杰伦 晴天', '周杰伦 稻香', '未知 没有这首']);
    expect(api.order, isNull);
    expect(calls, ['BVlive']);
    expect(page.items.map((hit) => hit.result.bvid), ['BVsong', 'BVlive']);
    expect(page.items.first.result.duration, 260);
    expect(page.items.last.result.cid, 2);
    expect(page.hasMore, isFalse);
  });

  test('年代歌单拿不到时仍用 B 站搜索', () async {
    final api = _EraSearchApi();
    final repo = BiliSearchRepository(
      api,
      TitleCleaner(const TitleRuleConfig(version: 1, rules: [])),
      eraCatalog: _DownEraCatalog(),
    );

    final items = (await repo.eraChart(DiscoverTab.y1990)).valueOrNull!.items;

    expect(api.keyword, BiliSearchRepository.eraKeyword[DiscoverTab.y1990]);
    expect(items.single.result.bvid, 'BVera');
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
