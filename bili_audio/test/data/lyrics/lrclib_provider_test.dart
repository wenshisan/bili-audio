import 'package:bili_audio/data/lyrics/lrclib_provider.dart';
import 'package:bili_audio/domain/lyrics/lyrics_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late LrclibProvider provider;

  const query = LyricsQuery(
    bvid: 'BV1',
    cid: 1,
    title: '七里香',
    artist: '周杰伦',
    duration: Duration(seconds: 299),
  );

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://lrclib.net'));
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    provider = LrclibProvider(dio: dio);
  });

  test('解析同步歌词并按得分降序; 跳过纯文本歌词', () async {
    adapter.onGet(
      '/api/search',
      (s) => s.reply(200, [
        {
          'trackName': '七里香 (Live)',
          'artistName': '某翻唱',
          'duration': 260,
          'syncedLyrics': '[00:01.00]窗外的麻雀',
        },
        {
          'trackName': '七里香',
          'artistName': '周杰伦',
          'duration': 299,
          'syncedLyrics': '[00:01.00]窗外的麻雀\n[00:05.50]在电线杆上多嘴',
        },
        {
          'trackName': '七里香',
          'artistName': '周杰伦',
          'duration': 299,
          'plainLyrics': '只有纯文本',
          'syncedLyrics': null,
        },
      ]),
    );

    final result = await provider.search(query);

    expect(result.length, 2);
    expect(result.first.originalArtist, '周杰伦');
    expect(result.first.matchScore, greaterThanOrEqualTo(0.8));
    expect(result.first.matchScore, greaterThan(result.last.matchScore));
    expect(result.first.lyrics.lines.length, 2);
    expect(result.first.lyrics.source, 'lrclib');
    expect(result.first.lrcText, contains('[00:05.50]'));
  });

  test('分P标题拆成歌名和歌手后再请求', () async {
    adapter.onGet(
      '/api/search',
      (server) => server.reply(200, [
        {
          'trackName': '稻香',
          'artistName': '周杰伦',
          'duration': 223,
          'syncedLyrics': '[00:01.00]对这个世界如果你有太多的抱怨',
        },
      ]),
      queryParameters: const {'track_name': '稻香', 'artist_name': '周杰伦'},
    );

    final result = await provider.search(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '007.周杰伦-稻香',
        duration: Duration(seconds: 224),
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.matchScore, greaterThanOrEqualTo(0.8));
    expect(result.first.originalTitle, '稻香');
  });

  test('omitArtistFilter 不把歌手传给搜索', () async {
    adapter.onGet(
      '/api/search',
      (s) => s.reply(200, [
        {
          'trackName': '七里香',
          'artistName': '周杰伦',
          'duration': 299,
          'syncedLyrics': '[00:01.00]窗外的麻雀',
        },
      ]),
      queryParameters: const {'track_name': '七里香'},
    );

    final result = await provider.search(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '七里香',
        artist: '周杰伦',
        duration: Duration(seconds: 299),
        omitArtistFilter: true,
      ),
    );

    expect(result, isNotEmpty);
    expect(result.first.matchScore, greaterThanOrEqualTo(0.8));
  });

  test('精确搜索没有这首歌时改用歌名加歌手关键词', () async {
    adapter.onGet(
      '/api/search',
      (server) => server.reply(200, [
        {
          'trackName': '周杰伦',
          'artistName': '米兰的小铁匠',
          'duration': 230,
          'syncedLyrics': '[00:01.00]跑遍了牧场',
        },
      ]),
      queryParameters: const {'track_name': '搁浅', 'artist_name': '周杰伦'},
    );
    adapter.onGet(
      '/api/search',
      (server) => server.reply(200, [
        {
          'trackName': '搁浅',
          'artistName': '周杰伦',
          'duration': 236,
          'syncedLyrics': '[00:01.00]河滨的风',
        },
      ]),
      queryParameters: const {'q': '搁浅 周杰伦'},
    );

    final result = await provider.search(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '搁浅',
        artist: '周杰伦',
        duration: Duration(seconds: 240),
      ),
    );

    expect(result.first.originalTitle, '搁浅');
    expect(result.first.originalArtist, '周杰伦');
    expect(result.first.matchScore, greaterThanOrEqualTo(0.8));
  });

  test('请求失败返回空列表', () async {
    adapter.onGet('/api/search', (s) => s.reply(503, null));
    expect(await provider.search(query), isEmpty);
  });

  test('读取超时抛出歌词源不可用', () async {
    final failing = Dio(BaseOptions(baseUrl: 'https://lrclib.net'));
    failing.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.receiveTimeout,
              message: 'receive timeout',
            ),
          );
        },
      ),
    );

    expect(
      LrclibProvider(dio: failing).search(
        const LyricsQuery(
          bvid: 'BV1',
          cid: 1,
          title: '如烟',
          artist: '五月天',
          duration: Duration(seconds: 220),
        ),
      ),
      throwsA(isA<LyricsSourceUnavailable>()),
    );
  });
}
