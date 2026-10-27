import 'dart:convert';

import 'package:bili_audio/data/lyrics/kugou_lyrics_provider.dart';
import 'package:bili_audio/domain/lyrics/lyrics_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('按哈希下载 Base64 同步歌词', () async {
    final search = Dio(BaseOptions(baseUrl: 'https://mobileservice.kugou.com'));
    final lyrics = Dio(BaseOptions(baseUrl: 'https://lyrics.kugou.com'));
    DioAdapter(dio: search).onGet(
      '/api/v3/search/song',
      (server) => server.reply(200, {
        'data': {
          'info': [
            {
              'hash': 'other',
              'songname': '其他歌',
              'singername': '别人',
              'duration': 180,
            },
            {
              'hash': 'rice',
              'songname': '稻香',
              'singername': '周杰伦',
              'duration': 223,
            },
          ],
        },
      }),
    );
    final lyricApi = DioAdapter(dio: lyrics);
    lyricApi.onGet(
      '/search',
      (server) => server.reply(200, {
        'candidates': [
          {'id': 186016, 'accesskey': 'key'},
        ],
      }),
      queryParameters: {
        'ver': 1,
        'man': 'yes',
        'client': 'pc',
        'keyword': '稻香',
        'duration': 223000,
        'hash': 'rice',
      },
    );
    lyricApi.onGet(
      '/download',
      (server) => server.reply(200, {
        'content': base64Encode(utf8.encode('[00:01.00]对这个世界如果你有太多的抱怨')),
      }),
      queryParameters: {
        'ver': 1,
        'client': 'pc',
        'id': '186016',
        'accesskey': 'key',
        'fmt': 'lrc',
        'charset': 'utf8',
      },
    );

    final result = await KugouLyricsProvider(search: search, lyrics: lyrics)
        .search(
          const LyricsQuery(
            bvid: 'BV1',
            cid: 1,
            title: '007.周杰伦-稻香',
            duration: Duration(seconds: 224),
          ),
        );

    expect(result, hasLength(1));
    expect(result.first.source, 'kugou');
    expect(result.first.originalTitle, '稻香');
    expect(result.first.originalArtist, '周杰伦');
    expect(result.first.matchScore, greaterThanOrEqualTo(0.8));
    expect(result.first.lyrics.lines.single.text, contains('太多的抱怨'));
  });

  test('读取超时抛出歌词源不可用', () async {
    final search = Dio(BaseOptions(baseUrl: 'https://mobileservice.kugou.com'));
    search.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.receiveTimeout,
            ),
          );
        },
      ),
    );

    expect(
      KugouLyricsProvider(search: search).search(
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
