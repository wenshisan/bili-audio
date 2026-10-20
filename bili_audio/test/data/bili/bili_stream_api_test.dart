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
                  'backup_url': ['https://backup1.com/audio.m4a', 'https://backup2.com/audio.m4a'],
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
        loggedIn: true,
      );

      expect(result.isSuccess, true);
      final selection = result.valueOrNull!;
      final streamUrl = selection.stream;

      expect(streamUrl.bvid, 'BV1xx411c7mD');
      expect(streamUrl.cid, 12345);
      expect(streamUrl.quality, AudioQuality.k132);
      expect(streamUrl.url, contains('audio.m4a'));
      expect(streamUrl.backupUrls, ['https://backup1.com/audio.m4a', 'https://backup2.com/audio.m4a']);
      expect(streamUrl.expiresAt, 1234567890);
      expect(selection.downgradedForGuest, false);
    });

    test('已登录选择最接近的音质', () async {
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
        loggedIn: true,
      );

      expect(result.isSuccess, true);
      expect(result.valueOrNull!.stream.quality, AudioQuality.k192);
      expect(result.valueOrNull!.downgradedForGuest, false);
    });

    test('未登录降级到 132K', () async {
      adapter.onGet(
        '/x/player/wbi/playurl',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'dash': {
              'audio': [
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
        loggedIn: false,
      );

      expect(result.isSuccess, true);
      expect(result.valueOrNull!.stream.quality, AudioQuality.k132);
      expect(result.valueOrNull!.downgradedForGuest, true);
    });

    test('包含 Dolby 和 Flac 候选', () async {
      adapter.onGet(
        '/x/player/wbi/playurl',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'dash': {
              'audio': [
                {'id': 30232, 'base_url': 'https://example.com/132k.m4a'},
              ],
              'dolby': {
                'audio': [
                  {'id': 30250, 'base_url': 'https://example.com/dolby.m4a'},
                ],
              },
              'flac': {
                'audio': {'id': 30251, 'base_url': 'https://example.com/flac.m4a'},
              },
            },
          },
        }),
      );

      final result = await streamApi.getStreamUrl(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        quality: AudioQuality.hiRes,
        loggedIn: true,
      );

      expect(result.isSuccess, true);
      expect(result.valueOrNull!.stream.quality, AudioQuality.hiRes);
    });

    test('没有不高于目标的时选最低档', () async {
      adapter.onGet(
        '/x/player/wbi/playurl',
        (server) => server.reply(200, {
          'code': 0,
          'data': {
            'dash': {
              'audio': [
                {'id': 30280, 'base_url': 'https://example.com/192k.m4a'},
              ],
            },
          },
        }),
      );

      final result = await streamApi.getStreamUrl(
        bvid: 'BV1xx411c7mD',
        cid: 12345,
        quality: AudioQuality.k64,
        loggedIn: true,
      );

      expect(result.isSuccess, true);
      expect(result.valueOrNull!.stream.quality, AudioQuality.k192);
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
  });
}
