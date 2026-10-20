import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:bili_audio/core/network/bili_http.dart';
import 'package:bili_audio/core/network/buvid_manager.dart';
import 'package:bili_audio/core/network/wbi_key_manager.dart';
import 'package:bili_audio/core/storage/secure_store.dart';
import 'package:bili_audio/data/bili/bili_stream_api.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late BiliStreamApi streamApi;

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

    streamApi = BiliStreamApi(http);
  });

  group('BiliStreamApi', () {
    test('获取音频流地址成功', () async {
      adapter.onGet(
        '/x/player/wbi/playurl',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'dash': {
              'audio': [
                {
                  'id': 30232,
                  'base_url': 'https://example.com/audio.m4a?deadline=1234567890',
                  'backup_url': ['https://backup.com/audio.m4a'],
                },
              ],
            },
          },
        }),
      );

      final result = await streamApi.getStreamUrl(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        quality: AudioQuality.k132,
      );

      expect(result.isSuccess, true);
      final streamUrl = result.valueOrNull!;

      expect(streamUrl.bvid, 'BV1xx411c7mD');
      expect(streamUrl.cid, 12345);
      expect(streamUrl.quality, AudioQuality.k132);
      expect(streamUrl.url, contains('audio.m4a'));
      expect(streamUrl.backupUrl, 'https://backup.com/audio.m4a');
      expect(streamUrl.expiresAt, 1234567890);
    });

    test('多个音质选择匹配的', () async {
      adapter.onGet(
        '/x/player/wbi/playurl',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'dash': {
              'audio': [
                {'id': 30216, 'base_url': 'https://example.com/64k.m4a'},
                {'id': 30232, 'base_url': 'https://example.com/132k.m4a'},
                {'id': 30280, 'base_url': 'https://example.com/192k.m4a'},
              ],
            },
          },
        }),
      );

      final result = await streamApi.getStreamUrl(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        quality: AudioQuality.k192,
      );

      expect(result.isSuccess, true);
      expect(result.valueOrNull!.url, contains('192k.m4a'));
    });

    test('未找到目标音质时降级到第一个', () async {
      adapter.onGet(
        '/x/player/wbi/playurl',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'dash': {
              'audio': [
                {'id': 30216, 'base_url': 'https://example.com/64k.m4a'},
              ],
            },
          },
        }),
      );

      final result = await streamApi.getStreamUrl(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        quality: AudioQuality.hiRes, // 请求 Hi-Res 但不存在
      );

      expect(result.isSuccess, true);
      expect(result.valueOrNull!.url, contains('64k.m4a'));
    });

    test('无音频流返回错误', () async {
      adapter.onGet(
        '/x/player/wbi/playurl',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'dash': {'audio': []},
          },
        }),
      );

      final result = await streamApi.getStreamUrl(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        quality: AudioQuality.k132,
      );

      expect(result.isFailure, true);
    });

    test('过期时间默认2小时', () async {
      adapter.onGet(
        '/x/player/wbi/playurl',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'dash': {
              'audio': [
                {'id': 30232, 'base_url': 'https://example.com/audio.m4a'},
              ],
            },
          },
        }),
      );

      final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final result = await streamApi.getStreamUrl(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        quality: AudioQuality.k132,
      );
      final after = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      expect(result.isSuccess, true);
      final expiresAt = result.valueOrNull!.expiresAt;

      // 应该在 before+7200 到 after+7200 之间
      expect(expiresAt, greaterThanOrEqualTo(before + 7200));
      expect(expiresAt, lessThanOrEqualTo(after + 7200));
    });
  });
}
