import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:bili_audio/core/network/bili_http.dart';
import 'package:bili_audio/core/network/buvid_manager.dart';
import 'package:bili_audio/core/network/wbi_key_manager.dart';
import 'package:bili_audio/core/storage/secure_store.dart';
import 'package:bili_audio/data/bili/bili_search_api.dart';
import 'package:bili_audio/domain/entities/app_error.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late BiliSearchApi searchApi;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.bilibili.com'));
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());

    final http = BiliHttp(
      dio: dio,
      store: MemorySecureStore(),
      buvidManager: BuvidManager(MemorySecureStore(), () async => ('B3', 'B4')),
      wbiKeyManager: WbiKeyManager(() async => (
            'https://i0.hdslb.com/bfs/wbi/7cd084941338484aae1ad9425b84077c.png',
            'https://i0.hdslb.com/bfs/wbi/4932caff0ff746eab6f01bf08b70ac45.png',
          )),
    );

    searchApi = BiliSearchApi(http);
  });

  group('BiliSearchApi', () {
    test('搜索成功返回结果列表', () async {
      adapter.onGet(
        '/x/web-interface/wbi/search/type',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'numResults': 100,
            'numPages': 5,
            'result': [
              {
                'bvid': 'BV1xx411c7mD',
                'title': '周杰伦 - 七里香【Hi-Res】',
                'duration': '4:30',
                'pic': 'https://example.com/cover.jpg',
                'author': 'UP主',
                'play': 10000,
                'description': '经典歌曲',
              },
              {
                'bvid': 'BV1yy411c8mE',
                'title': '稻香 <em class="keyword">周杰伦</em>',
                'duration': '3:45',
                'pic': 'https://example.com/cover2.jpg',
                'author': 'UP主2',
                'play': 20000,
              },
            ],
          },
        }),
      );

      final result = await searchApi.searchVideo(keyword: '周杰伦');

      expect(result.isSuccess, true);
      final page = result.valueOrNull!;

      expect(page.items.length, 2);
      expect(page.page, 1);
      expect(page.total, 100);
      expect(page.hasMore, true);

      final first = page.items[0];
      expect(first.bvid, 'BV1xx411c7mD');
      expect(first.title, '周杰伦 - 七里香【Hi-Res】');
      expect(first.cleanTitle, '周杰伦 - 七里香【Hi-Res】');
      expect(first.duration, 270);
      expect(first.filtered, false);

      final second = page.items[1];
      expect(second.cleanTitle, '稻香 周杰伦'); // HTML 标签已去除
    });

    test('时长超过 15min 标记为 filtered', () async {
      adapter.onGet(
        '/x/web-interface/wbi/search/type',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'numResults': 1,
            'numPages': 1,
            'result': [
              {
                'bvid': 'BV1xx411c7mD',
                'title': '长视频',
                'duration': '16:00',
                'pic': '',
                'author': 'UP主',
                'play': 100,
              },
            ],
          },
        }),
      );

      final result = await searchApi.searchVideo(keyword: 'test');

      expect(result.isSuccess, true);
      final item = result.valueOrNull!.items.first;
      expect(item.duration, 960);
      expect(item.filtered, true);
    });

    test('解析时长: m:ss 和 h:mm:ss', () async {
      adapter.onGet(
        '/x/web-interface/wbi/search/type',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'numResults': 3,
            'numPages': 1,
            'result': [
              {
                'bvid': 'BV1',
                'title': 'T1',
                'duration': '5:30',
                'pic': '',
                'author': 'A',
                'play': 1,
              },
              {
                'bvid': 'BV2',
                'title': 'T2',
                'duration': '1:05:30',
                'pic': '',
                'author': 'A',
                'play': 1,
              },
              {
                'bvid': 'BV3',
                'title': 'T3',
                'duration': '15:00',
                'pic': '',
                'author': 'A',
                'play': 1,
              },
            ],
          },
        }),
      );

      final result = await searchApi.searchVideo(keyword: 'test');
      final items = result.valueOrNull!.items;

      expect(items[0].duration, 330); // 5:30
      expect(items[1].duration, 3930); // 1:05:30
      expect(items[2].duration, 900); // 15:00 (边界)
      expect(items[2].filtered, false); // = 15min 不过滤
    });

    test('HTML 实体反转义', () async {
      adapter.onGet(
        '/x/web-interface/wbi/search/type',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'numResults': 1,
            'numPages': 1,
            'result': [
              {
                'bvid': 'BV1',
                'title': '&lt;Title&gt; &amp; &quot;Test&#39;',
                'duration': '3:00',
                'pic': '',
                'author': 'A',
                'play': 1,
              },
            ],
          },
        }),
      );

      final result = await searchApi.searchVideo(keyword: 'test');
      final item = result.valueOrNull!.items.first;

      expect(item.cleanTitle, '<Title> & "Test\'');
    });

    test('业务错误返回 Failure', () async {
      adapter.onGet(
        '/x/web-interface/wbi/search/type',
        (server) => server.reply(200, {'code': -412, 'message': '请求过于频繁'}),
      );

      final result = await searchApi.searchVideo(keyword: 'test');

      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<RiskControlError>());
    });

    test('网络错误返回 NetworkError', () async {
      adapter.onGet(
        '/x/web-interface/wbi/search/type',
        (server) => server.throws(
          500,
          DioException.badResponse(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/x/web-interface/wbi/search/type'),
            response: Response(
              requestOptions: RequestOptions(path: '/x/web-interface/wbi/search/type'),
              statusCode: 500,
            ),
          ),
        ),
      );

      final result = await searchApi.searchVideo(keyword: 'test');

      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('空结果返回空列表', () async {
      adapter.onGet(
        '/x/web-interface/wbi/search/type',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'numResults': 0,
            'numPages': 0,
            'result': [],
          },
        }),
      );

      final result = await searchApi.searchVideo(keyword: 'nonexistent');

      expect(result.isSuccess, true);
      expect(result.valueOrNull!.items, isEmpty);
      expect(result.valueOrNull!.hasMore, false);
    });
  });
}
