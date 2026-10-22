import 'package:bili_audio/data/album/itunes_album_provider.dart';
import 'package:bili_audio/data/album/netease_album_provider.dart';
import 'package:bili_audio/data/album/qq_album_provider.dart';
import 'package:bili_audio/domain/album/album_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('网易云优先于 QQ 音乐和 iTunes', () {
    expect(
      NeteaseAlbumProvider().priority,
      lessThan(QqAlbumProvider().priority),
    );
    expect(
      QqAlbumProvider().priority,
      lessThan(ItunesAlbumProvider().priority),
    );
  });

  test('选中曲目后带上专辑图、年份和介绍', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://music.163.com'));
    final adapter = DioAdapter(dio: dio);
    final published = DateTime(2008, 10, 15).millisecondsSinceEpoch;
    adapter.onGet(
      '/api/search/get/web',
      (server) => server.reply(200, {
        'code': 200,
        'result': {
          'songs': [
            {
              'name': '其他歌',
              'duration': 180000,
              'artists': [
                {'name': '别人'},
              ],
              'album': {'id': 1, 'name': '别的专辑'},
            },
            {
              'name': '稻香',
              'duration': 223000,
              'artists': [
                {'name': '周杰伦'},
              ],
              'album': {
                'id': 32311,
                'name': '魔杰座',
                'picUrl': 'http://p1.music.126.net/cover.jpg',
                'publishTime': published,
              },
            },
          ],
        },
      }),
    );
    adapter.onGet(
      '/api/album/32311',
      (server) => server.reply(200, {
        'code': 200,
        'album': {
          'name': '魔杰座',
          'picUrl': 'http://p1.music.126.net/cover.jpg',
          'publishTime': published,
          'description': '',
          'briefDesc': '2008年发行的录音室专辑',
        },
      }),
    );

    final result = await NeteaseAlbumProvider(dio: dio).search(
      const AlbumQuery(
        bvid: 'BV1',
        cid: 1,
        title: '007.周杰伦-稻香',
        duration: Duration(seconds: 224),
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.source, 'netease');
    expect(result.first.albumName, '魔杰座');
    expect(result.first.year, 2008);
    expect(result.first.coverUrl, 'https://p1.music.126.net/cover.jpg');
    expect(result.first.description, '2008年发行的录音室专辑');
    expect(result.first.matchScore, greaterThanOrEqualTo(0.8));
  });
}
