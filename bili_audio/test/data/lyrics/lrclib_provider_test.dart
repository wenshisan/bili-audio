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

  test('请求失败返回空列表', () async {
    adapter.onGet('/api/search', (s) => s.reply(503, null));
    expect(await provider.search(query), isEmpty);
  });
}
