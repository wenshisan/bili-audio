import 'package:bili_audio/core/network/bili_http.dart';
import 'package:bili_audio/core/network/buvid_manager.dart';
import 'package:bili_audio/core/network/wbi_key_manager.dart';
import 'package:bili_audio/core/storage/secure_store.dart';
import 'package:bili_audio/data/bili/bili_ranking_api.dart';
import 'package:bili_audio/domain/entities/app_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late BiliRankingApi api;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.bilibili.com'));
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    api = BiliRankingApi(
      BiliHttp(
        dio: dio,
        store: MemorySecureStore(),
        buvidManager: BuvidManager(
          MemorySecureStore(),
          () async => ('B3', 'B4'),
        ),
        wbiKeyManager: WbiKeyManager(
          () async => (
            'https://i0.hdslb.com/bfs/wbi/7cd084941338484aae1ad9425b84077c.png',
            'https://i0.hdslb.com/bfs/wbi/4932caff0ff746eab6f01bf08b70ac45.png',
          ),
        ),
      ),
    );
  });

  test('音乐区排行按榜单顺序解析，并跳过缺字段的条目', () async {
    adapter.onGet(
      '/x/web-interface/ranking/v2',
      (server) => server.reply(200, {
        'code': 0,
        'data': {
          'note': '根据稿件内容质量、近期的数据综合展示，动态更新',
          'list': [
            {
              'bvid': 'BV1short',
              'title': '周杰伦 - 晴天',
              'pic': 'http://i0.hdslb.com/bfs/archive/cover.jpg',
              'duration': 180,
              'cid': 42,
              'videos': 1,
              'desc': '单曲',
              'owner': {'name': 'UP主'},
              'stat': {'view': 12000},
            },
            {'title': '没有 bvid'},
            {
              'bvid': 'BV1long',
              'title': '演唱会',
              'pic': '//i0.hdslb.com/bfs/archive/long.jpg',
              'duration': 3600,
              'cid': 7,
              'videos': 1,
              'owner': {'name': 'UP主'},
              'stat': {'view': 99},
            },
          ],
        },
      }),
    );

    final result = await api.dailyMusic();

    expect(result.isSuccess, isTrue);
    final items = result.valueOrNull!.heat;
    expect(items.map((item) => item.bvid), ['BV1short', 'BV1long']);
    final first = items.first;
    expect(first.cleanTitle, '周杰伦 - 晴天');
    expect(first.duration, 180);
    expect(first.filtered, isFalse);
    expect(first.cid, 42);
    expect(first.author, 'UP主');
    expect(first.play, 12000);
    expect(first.cover, 'https://i0.hdslb.com/bfs/archive/cover.jpg');
    expect(items[1].filtered, isTrue);
    expect(items[1].cover, 'https://i0.hdslb.com/bfs/archive/long.jpg');
  });

  test('排行拆成热度、评价和音乐分区，并去掉音乐区以外的稿件', () async {
    adapter.onGet(
      '/x/web-interface/ranking/v2',
      (server) => server.reply(200, {
        'code': 0,
        'data': {
          'list': [
            _video(
              bvid: 'BVorig',
              title: '原创曲',
              view: 20000,
              like: 100,
              coin: 10,
              favorite: 10,
              pid: 1003,
              tidv2: 2016,
            ),
            _video(
              bvid: 'BVcover',
              title: '翻唱曲',
              view: 50000,
              like: 1000,
              coin: 8000,
              favorite: 1000,
              pid: 1003,
              tidv2: 2020,
            ),
            _video(
              bvid: 'BVmv',
              title: '一支 MV',
              view: 100,
              like: 90,
              pid: 1003,
              tidv2: 2017,
            ),
            _video(
              bvid: 'BVgame',
              title: '游戏实况',
              view: 80000,
              like: 1,
              pid: 4,
              tidv2: 999,
            ),
          ],
        },
      }),
    );

    final bundle = (await api.dailyMusic()).valueOrNull!;

    expect(bundle.heat.map((item) => item.bvid), ['BVorig', 'BVcover', 'BVmv']);
    expect(bundle.zones[MusicZone.original]!.map((item) => item.bvid), [
      'BVorig',
    ]);
    expect(bundle.zones[MusicZone.cover]!.map((item) => item.bvid), [
      'BVcover',
    ]);
    expect(bundle.zones[MusicZone.mv]!.map((item) => item.bvid), ['BVmv']);
    expect(bundle.rating.map((item) => item.bvid), ['BVcover', 'BVorig']);
  });

  test('排行请求失败时返回网络错误', () async {
    adapter.onGet(
      '/x/web-interface/ranking/v2',
      (server) => server.throws(
        500,
        DioException.badResponse(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/x/web-interface/ranking/v2'),
          response: Response(
            requestOptions: RequestOptions(path: '/x/web-interface/ranking/v2'),
            statusCode: 500,
          ),
        ),
      ),
    );

    final result = await api.dailyMusic();

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<NetworkError>());
  });
}

Map<String, Object> _video({
  required String bvid,
  required String title,
  required int view,
  int like = 0,
  int coin = 0,
  int favorite = 0,
  int? pid,
  int? tidv2,
}) => {
  'bvid': bvid,
  'title': title,
  'pic': '',
  'duration': 180,
  'cid': 1,
  'videos': 1,
  'owner': {'name': 'UP'},
  'stat': {'view': view, 'like': like, 'coin': coin, 'favorite': favorite},
  'pid_v2': ?pid,
  'tidv2': ?tidv2,
};
