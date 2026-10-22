import 'package:bili_audio/data/album/qq_album_provider.dart';
import 'package:bili_audio/domain/album/album_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('解析搜索结果和专辑介绍', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://c.y.qq.com'));
    final adapter = DioAdapter(dio: dio);
    adapter.onGet(
      '/soso/fcgi-bin/client_search_cp',
      (server) => server.reply(200, {
        'code': 0,
        'data': {
          'song': {
            'list': [
              {
                'name': '稻香',
                'interval': 223,
                'time_public': '2008-10-15',
                'singer': [
                  {'name': '周杰伦'},
                ],
                'album': {'name': '魔杰座', 'mid': '003DFRzD192KKD'},
              },
            ],
          },
        },
      }),
    );
    adapter.onGet(
      '/v8/fcg-bin/fcg_v8_album_info_cp.fcg',
      (server) => server.reply(
        200,
        'callback({"data":{"name":"魔杰座","aDate":"2008-10-15",'
        '"desc":"第一行<br>第二行","mid":"003DFRzD192KKD"}})',
      ),
    );

    final result = await QqAlbumProvider(dio: dio).search(
      const AlbumQuery(
        bvid: 'BV1',
        cid: 1,
        title: '稻香',
        artist: '周杰伦',
        duration: Duration(seconds: 223),
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.albumName, '魔杰座');
    expect(result.first.year, 2008);
    expect(
      result.first.coverUrl,
      'https://y.gtimg.cn/music/photo_new/T002R800x800M000003DFRzD192KKD.jpg',
    );
    expect(result.first.description, '第一行\n第二行');
    expect(result.first.matchScore, greaterThanOrEqualTo(0.8));
  });
}
