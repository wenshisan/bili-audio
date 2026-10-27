import 'dart:convert';

import 'package:bili_audio/data/lyrics/bili_subtitle_provider.dart';
import 'package:bili_audio/data/lyrics/kugou_lyrics_provider.dart';
import 'package:bili_audio/data/lyrics/kuwo_lyrics_provider.dart';
import 'package:bili_audio/data/lyrics/lrclib_provider.dart';
import 'package:bili_audio/data/lyrics/lyrics_http.dart';
import 'package:bili_audio/data/lyrics/netease_lyrics_provider.dart';
import 'package:bili_audio/data/lyrics/qq_lyrics_provider.dart';
import 'package:bili_audio/domain/lyrics/lyrics_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('QQ、酷狗、酷我排在 B 站字幕之后、LRCLIB 之前', () {
    final bili = BiliSubtitleProvider(api: Dio()).priority;
    final netease = NeteaseLyricsProvider().priority;
    final qq = QqLyricsProvider().priority;
    final kugou = KugouLyricsProvider().priority;
    final kuwo = KuwoLyricsProvider().priority;
    final lrclib = LrclibProvider().priority;

    expect(netease, lessThan(bili));
    expect(qq, greaterThan(bili));
    expect(kugou, greaterThan(qq));
    expect(kuwo, greaterThan(kugou));
    expect(lrclib, greaterThan(kuwo));
  });

  test('回调包裹的 JSON 和 Base64 歌词能解开', () {
    final wrapped = lyricsJsonBody(
      'MusicJsonCallback({"lyric":"[00:01.00]你好"})',
    );
    expect(syncedLrcText(wrapped?['lyric'] as String?), contains('你好'));

    final encoded = base64Encode(utf8.encode('[00:01.00]你好'));
    expect(syncedLrcText(encoded), contains('你好'));
  });

  test('按歌名歌手选中曲目并解析同步歌词', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://c.y.qq.com'));
    final adapter = DioAdapter(dio: dio);
    adapter.onGet(
      '/soso/fcgi-bin/client_search_cp',
      (server) => server.reply(200, {
        'data': {
          'song': {
            'list': [
              {
                'mid': 'other',
                'name': '其他歌',
                'interval': 180,
                'singer': [
                  {'name': '别人'},
                ],
              },
              {
                'mid': 'rice',
                'name': '稻香',
                'interval': 223,
                'singer': [
                  {'name': '周杰伦'},
                ],
              },
            ],
          },
        },
      }),
    );
    adapter.onGet(
      '/lyric/fcgi-bin/fcg_query_lyric_new.fcg',
      (server) => server.reply(200, {'lyric': '[00:01.00]对这个世界如果你有太多的抱怨'}),
      queryParameters: {
        'songmid': 'rice',
        'format': 'json',
        'nobase64': 1,
        'g_tk': 5381,
      },
    );

    final result = await QqLyricsProvider(dio: dio).search(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '007.周杰伦-稻香',
        duration: Duration(seconds: 224),
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.source, 'qq');
    expect(result.first.originalTitle, '稻香');
    expect(result.first.originalArtist, '周杰伦');
    expect(result.first.matchScore, greaterThanOrEqualTo(0.8));
    expect(result.first.lyrics.lines.single.text, contains('太多的抱怨'));
  });

  test('四位分P序号不进入 QQ 搜索词', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://c.y.qq.com'));
    String? keyword;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          keyword ??= options.queryParameters['w'] as String?;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'data': <String, dynamic>{}},
            ),
          );
        },
      ),
    );

    await QqLyricsProvider(dio: dio).search(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '0065. 洋葱 - 五月天',
        artist: '五月天',
        duration: Duration(seconds: 240),
      ),
    );

    expect(keyword, '洋葱 五月天');
  });

  test('省略歌手过滤时搜索词只剩歌名', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://c.y.qq.com'));
    String? keyword;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          keyword ??= options.queryParameters['w'] as String?;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'data': <String, dynamic>{}},
            ),
          );
        },
      ),
    );

    await QqLyricsProvider(dio: dio).search(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '稻香',
        artist: '周杰伦',
        duration: Duration(seconds: 224),
        omitArtistFilter: true,
      ),
    );

    expect(keyword, '稻香');
  });

  test('连接超时抛出歌词源不可用', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://c.y.qq.com'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
            ),
          );
        },
      ),
    );

    expect(
      QqLyricsProvider(dio: dio).search(
        const LyricsQuery(
          bvid: 'BV1',
          cid: 1,
          title: '稻香',
          duration: Duration(seconds: 224),
        ),
      ),
      throwsA(isA<LyricsSourceUnavailable>()),
    );
  });
}
