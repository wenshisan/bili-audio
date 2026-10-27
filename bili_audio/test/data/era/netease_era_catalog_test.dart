import 'dart:convert';

import 'package:bili_audio/data/era/netease_era_catalog.dart';
import 'package:bili_audio/data/repositories/repositories.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('网易云选本年代曲目更多的歌单，并按页返回单曲', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://music.163.com'));
    final adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    var details = 0;
    adapter.onPost(
      '/api/cloudsearch/pc',
      (server) => server.reply(
        200,
        jsonEncode({
          'code': 200,
          'result': {
            'playlists': [
              {
                'id': 1,
                'name': '80/90年代经典',
                'playCount': 9000000,
                'trackCount': 400,
                'playlistType': 'UGC',
              },
              {
                'id': 2,
                'name': '2020年代华语流行',
                'playCount': 800000,
                'trackCount': 198,
                'playlistType': 'UGC',
              },
              {
                'id': 3,
                'name': '2020年代热播金曲',
                'playCount': 1000,
                'trackCount': 40,
                'playlistType': 'PGC',
              },
            ],
          },
        }),
        headers: const {
          'content-type': ['text/plain'],
        },
      ),
    );
    adapter.onGet('/api/v6/playlist/detail', (server) {
      details++;
      server.reply(200, {
        'code': 200,
        'playlist': {
          'tracks': [
            {
              'name': '歌曲0',
              'dt': 180000,
              'ar': [
                {'name': '歌手0'},
              ],
            },
          ],
          'trackIds': [
            for (var i = 0; i < 31; i++) {'id': i + 1},
          ],
        },
      });
    }, queryParameters: {'id': 2, 'n': 200});
    adapter.onPost('/api/v3/song/detail', (server) {
      server.reply(
        200,
        jsonEncode({
          'songs': [
            for (var i = 30; i >= 0; i--)
              {
                'id': i + 1,
                'name': '歌曲$i',
                'dt': 180000,
                'ar': [
                  {'name': '歌手$i'},
                  {'name': '和声'},
                ],
              },
          ],
        }),
      );
    });

    final catalog = NeteaseEraCatalog(dio: dio);
    final first = (await catalog.page(DiscoverTab.y2020)).valueOrNull!;
    final second = (await catalog.page(
      DiscoverTab.y2020,
      page: 2,
    )).valueOrNull!;

    expect(details, 1);
    expect(first.tracks, hasLength(NeteaseEraCatalog.pageSize));
    expect(first.tracks.first.name, '歌曲0');
    expect(first.tracks.first.artist, '歌手0');
    expect(first.tracks.first.duration, const Duration(seconds: 180));
    expect(first.total, 31);
    expect(first.hasMore, isTrue);
    expect(second.tracks.single.name, '歌曲30');
    expect(second.hasMore, isFalse);
  });
}
