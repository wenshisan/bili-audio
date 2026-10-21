import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:bili_audio/core/network/bili_http.dart';
import 'package:bili_audio/core/network/buvid_manager.dart';
import 'package:bili_audio/core/network/wbi_key_manager.dart';
import 'package:bili_audio/core/storage/secure_store.dart';
import 'package:bili_audio/data/bili/bili_video_api.dart';
import 'package:bili_audio/domain/entities/app_error.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late BiliVideoApi videoApi;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.bilibili.com'));
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());

    final http = BiliHttp(
      dio: dio,
      store: MemorySecureStore(),
      buvidManager: BuvidManager(MemorySecureStore(), () async => ('B3', 'B4')),
      wbiKeyManager: WbiKeyManager(
        () async => (
          'https://i0.hdslb.com/bfs/wbi/7cd084941338484aae1ad9425b84077c.png',
          'https://i0.hdslb.com/bfs/wbi/4932caff0ff746eab6f01bf08b70ac45.png',
        ),
      ),
    );

    videoApi = BiliVideoApi(http);
  });

  group('BiliVideoApi', () {
    test('获取视频详情成功', () async {
      adapter.onGet(
        '/x/web-interface/view',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'bvid': 'BV1xx411c7mD',
            'title': '周杰伦 - 七里香',
            'pic': 'https://example.com/cover.jpg',
            'owner': {'name': 'UP主', 'mid': 12345},
            'pubdate': 1609459200,
            'stat': {'view': 10000},
            'pages': [
              {'cid': 1, 'page': 1, 'part': 'P1', 'duration': 270},
              {'cid': 2, 'page': 2, 'part': 'P2', 'duration': 300},
            ],
          },
        }),
      );

      final result = await videoApi.getVideoInfo('BV1xx411c7mD');

      expect(result.isSuccess, true);
      final video = result.valueOrNull!;

      expect(video.bvid, 'BV1xx411c7mD');
      expect(video.title, '周杰伦 - 七里香');
      expect(video.uploader, 'UP主');
      expect(video.uploaderMid, 12345);
      expect(video.pages.length, 2);
      expect(video.viewCount, 10000);

      final firstPage = video.pages[0];
      expect(firstPage.cid, 1);
      expect(firstPage.title, 'P1');
      expect(firstPage.duration.inSeconds, 270);
      expect(firstPage.pageIndex, 1);
    });

    test('过滤超过 15 分钟的分P', () async {
      adapter.onGet(
        '/x/web-interface/view',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'bvid': 'BV1xx411c7mD',
            'title': '测试视频',
            'pic': '',
            'owner': {'name': 'UP主', 'mid': 1},
            'pages': [
              {'cid': 1, 'page': 1, 'part': 'P1', 'duration': 900}, // = 15min
              {'cid': 2, 'page': 2, 'part': 'P2', 'duration': 901}, // > 15min
              {'cid': 3, 'page': 3, 'part': 'P3', 'duration': 300}, // < 15min
            ],
          },
        }),
      );

      final result = await videoApi.getVideoInfo('BV1xx411c7mD');

      expect(result.isSuccess, true);
      final video = result.valueOrNull!;

      expect(video.pages.length, 2); // P1 和 P3
      expect(video.pages[0].duration.inSeconds, 900);
      expect(video.pages[1].duration.inSeconds, 300);
    });

    test('所有分P都超过15分钟返回 NotFound', () async {
      adapter.onGet(
        '/x/web-interface/view',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'bvid': 'BV1xx411c7mD',
            'title': '长视频',
            'pic': '',
            'owner': {'name': 'UP主', 'mid': 1},
            'pages': [
              {'cid': 1, 'page': 1, 'part': 'P1', 'duration': 1000},
              {'cid': 2, 'page': 2, 'part': 'P2', 'duration': 2000},
            ],
          },
        }),
      );

      final result = await videoApi.getVideoInfo('BV1xx411c7mD');

      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<NotFoundError>());
    });

    test('获取视频标签', () async {
      adapter.onGet(
        '/x/tag/archive/tags',
        (server) => server.reply(200, {
          'code': 0,
          'data': [
            {'tag_name': '音乐'},
            {'tag_name': '周杰伦'},
            {'tag_name': '华语'},
          ],
        }),
      );

      final result = await videoApi.getVideoTags('BV1xx411c7mD');

      expect(result.isSuccess, true);
      final tags = result.valueOrNull!;

      expect(tags, ['音乐', '周杰伦', '华语']);
    });

    test('标签接口失败返回空列表', () async {
      adapter.onGet(
        '/x/tag/archive/tags',
        (server) => server.reply(200, {'code': -404}),
      );

      final result = await videoApi.getVideoTags('BV1xx411c7mD');

      expect(result.isSuccess, true);
      expect(result.valueOrNull, isEmpty);
    });

    test('分P列表保留超长分P', () async {
      adapter.onGet(
        '/x/player/pagelist',
        (server) => server.reply(200, {
          'code': 0,
          'data': [
            {'cid': 11, 'page': 1, 'part': '稻香', 'duration': 240},
            {'cid': 12, 'page': 2, 'part': '现场', 'duration': 1200},
          ],
        }),
      );

      final result = await videoApi.getPageList('BV1xx411c7mD');

      expect(result.isSuccess, true);
      final pages = result.valueOrNull!;
      expect(pages.map((p) => p.cid), [11, 12]);
      expect(pages[1].duration.inSeconds, 1200);
    });

    test('业务错误返回 Failure', () async {
      adapter.onGet(
        '/x/web-interface/view',
        (server) => server.reply(200, {'code': 62002, 'message': '视频不存在'}),
      );

      final result = await videoApi.getVideoInfo('BV1xx411c7mD');

      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<NotFoundError>());
    });
  });
}
