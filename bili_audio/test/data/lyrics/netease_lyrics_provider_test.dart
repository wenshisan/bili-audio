import 'package:bili_audio/data/lyrics/bili_subtitle_provider.dart';
import 'package:bili_audio/data/lyrics/lrclib_provider.dart';
import 'package:bili_audio/data/lyrics/netease_lyrics_provider.dart';
import 'package:bili_audio/domain/lyrics/lyrics_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('网易云排在 B 站字幕和 LRCLIB 前面', () {
    final netease = NeteaseLyricsProvider().priority;
    expect(netease, lessThan(BiliSubtitleProvider(api: Dio()).priority));
    expect(netease, lessThan(LrclibProvider().priority));
  });

  test('按歌名歌手选中曲目并解析同步歌词', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://music.163.com'));
    final adapter = DioAdapter(dio: dio);
    adapter.onGet(
      '/api/search/get/web',
      (server) => server.reply(200, {
        'code': 200,
        'result': {
          'songs': [
            {
              'id': 1,
              'name': '其他歌',
              'duration': 180000,
              'artists': [
                {'name': '别人'},
              ],
            },
            {
              'id': 186016,
              'name': '稻香',
              'duration': 223000,
              'artists': [
                {'name': '周杰伦'},
              ],
            },
          ],
        },
      }),
    );
    adapter.onGet(
      '/api/song/lyric',
      (server) => server.reply(200, {
        'code': 200,
        'lrc': {'lyric': '[00:01.00]对这个世界如果你有太多的抱怨'},
      }),
      queryParameters: const {'id': 186016, 'lv': 1, 'kv': 1, 'tv': -1},
    );

    final result = await NeteaseLyricsProvider(dio: dio).search(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '007.周杰伦-稻香',
        duration: Duration(seconds: 224),
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.source, 'netease');
    expect(result.first.originalTitle, '稻香');
    expect(result.first.originalArtist, '周杰伦');
    expect(result.first.matchScore, greaterThanOrEqualTo(0.8));
    expect(result.first.lyrics.lines.single.text, contains('太多的抱怨'));
  });

  test('四位分P序号不进入网易云搜索词', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://music.163.com'));
    String? keyword;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          keyword ??= options.queryParameters['s'] as String?;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'code': 200,
                'result': <String, dynamic>{'songs': <Object?>[]},
              },
            ),
          );
        },
      ),
    );

    await NeteaseLyricsProvider(dio: dio).search(
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
}
