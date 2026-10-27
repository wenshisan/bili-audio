import 'package:bili_audio/data/lyrics/kuwo_lyrics_provider.dart';
import 'package:bili_audio/domain/lyrics/lyrics_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('把逐行时间轴收成同步歌词', () async {
    final search = Dio(BaseOptions(baseUrl: 'https://search.kuwo.cn'));
    final lyrics = Dio(BaseOptions(baseUrl: 'https://m.kuwo.cn'));
    DioAdapter(dio: search).onGet(
      '/r.s',
      (server) => server.reply(200, {
        'abslist': [
          {
            'MUSICRID': 'MUSIC_1',
            'SONGNAME': '其他歌',
            'ARTIST': '别人',
            'DURATION': '180',
          },
          {
            'MUSICRID': 'MUSIC_186016',
            'SONGNAME': '稻香',
            'ARTIST': '周杰伦',
            'DURATION': '223',
          },
        ],
      }),
    );
    DioAdapter(dio: lyrics).onGet(
      '/newh5/singles/songinfoandlrc',
      (server) => server.reply(200, {
        'data': {
          'lrclist': [
            {'time': '1.5', 'lineLyric': '对这个世界如果你有太多的抱怨'},
          ],
        },
      }),
      queryParameters: {'musicId': '186016'},
    );

    final result = await KuwoLyricsProvider(search: search, lyrics: lyrics)
        .search(
          const LyricsQuery(
            bvid: 'BV1',
            cid: 1,
            title: '007.周杰伦-稻香',
            duration: Duration(seconds: 224),
          ),
        );

    expect(result, hasLength(1));
    expect(result.first.source, 'kuwo');
    expect(result.first.originalTitle, '稻香');
    expect(result.first.originalArtist, '周杰伦');
    expect(result.first.matchScore, greaterThanOrEqualTo(0.8));
    expect(result.first.lyrics.lines.single.text, contains('太多的抱怨'));
    expect(
      result.first.lyrics.lines.single.timestamp,
      const Duration(milliseconds: 1500),
    );
  });

  test('没有歌词行时返回空列表', () async {
    final search = Dio(BaseOptions(baseUrl: 'https://search.kuwo.cn'));
    final lyrics = Dio(BaseOptions(baseUrl: 'https://m.kuwo.cn'));
    DioAdapter(dio: search).onGet(
      '/r.s',
      (server) => server.reply(200, {
        'abslist': [
          {
            'MUSICRID': 'MUSIC_186016',
            'SONGNAME': '稻香',
            'ARTIST': '周杰伦',
            'DURATION': '223',
          },
        ],
      }),
    );
    DioAdapter(dio: lyrics).onGet(
      '/newh5/singles/songinfoandlrc',
      (server) => server.reply(200, {
        'data': {'lrclist': <Object?>[]},
      }),
    );

    final result = await KuwoLyricsProvider(search: search, lyrics: lyrics)
        .search(
          const LyricsQuery(
            bvid: 'BV1',
            cid: 1,
            title: '稻香',
            artist: '周杰伦',
            duration: Duration(seconds: 223),
          ),
        );

    expect(result, isEmpty);
  });
}
