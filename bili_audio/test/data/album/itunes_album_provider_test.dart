import 'package:bili_audio/data/album/itunes_album_provider.dart';
import 'package:bili_audio/domain/album/album_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  const query = AlbumQuery(
    bvid: 'BV1',
    cid: 1,
    title: '稻香',
    artist: '周杰伦',
    duration: Duration(seconds: 223),
  );

  Map<String, dynamic> song({required String artwork}) => {
    'resultCount': 1,
    'results': [
      {
        'trackName': '稻香',
        'artistName': '周杰伦',
        'collectionName': '魔杰座',
        'releaseDate': '2008-10-15T07:00:00Z',
        'trackTimeMillis': 223000,
        'artworkUrl100': artwork,
      },
    ],
  };

  test('中国区已经匹配到就不查美国区，并放大封面', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://itunes.apple.com'));
    final adapter = DioAdapter(dio: dio);
    final countries = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          countries.add('${options.queryParameters['country']}');
          handler.next(options);
        },
      ),
    );
    adapter.onGet(
      '/search',
      (server) =>
          server.reply(200, song(artwork: 'https://example.com/100x100bb.jpg')),
    );

    final result = await ItunesAlbumProvider(dio: dio).search(query);

    expect(countries, ['CN']);
    expect(result, hasLength(1));
    expect(result.first.albumName, '魔杰座');
    expect(result.first.year, 2008);
    expect(result.first.coverUrl, 'https://example.com/600x600bb.jpg');
    expect(result.first.description, isNull);
  });

  test('中国区没有结果时改查美国区', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://itunes.apple.com'));
    final adapter = DioAdapter(dio: dio);
    final countries = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          countries.add('${options.queryParameters['country']}');
          handler.next(options);
        },
      ),
    );
    Map<String, dynamic> params(String country) => {
      'term': '稻香 周杰伦',
      'media': 'music',
      'entity': 'song',
      'limit': 5,
      'country': country,
    };
    adapter.onGet(
      '/search',
      (server) => server.reply(200, {'resultCount': 0, 'results': <Object>[]}),
      queryParameters: params('CN'),
    );
    adapter.onGet(
      '/search',
      (server) => server.reply(
        200,
        song(artwork: 'https://example.com/100x100bb.jpg'),
      ),
      queryParameters: params('US'),
    );

    final result = await ItunesAlbumProvider(dio: dio).search(query);

    expect(countries, ['CN', 'US']);
    expect(result.single.coverUrl, 'https://example.com/600x600bb.jpg');
  });
}
