import 'package:bili_audio/data/lyrics/bili_subtitle_provider.dart';
import 'package:bili_audio/domain/lyrics/lyrics_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('中文字幕转成 LRC 并直接采用', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.bilibili.com'));
    final adapter = DioAdapter(dio: dio);
    adapter.onGet(
      '/x/player/wbi/v2',
      (server) => server.reply(200, {
        'code': 0,
        'data': {
          'subtitle': {
            'subtitles': [
              {'lan': 'en', 'subtitle_url': 'https://example.com/en.json'},
              {'lan': 'zh-CN', 'subtitle_url': 'https://example.com/zh.json'},
            ],
          },
        },
      }),
    );
    adapter.onGet(
      'https://example.com/zh.json',
      (server) => server.reply(200, {
        'body': [
          {'from': 1.5, 'to': 4, 'content': '窗外的麻雀'},
          {'from': 5, 'to': 8, 'content': '在电线杆上多嘴'},
        ],
      }),
    );

    final result = await BiliSubtitleProvider(api: dio, files: dio).search(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 9,
        title: '稻香',
        artist: '周杰伦',
        duration: Duration(seconds: 223),
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.source, 'bilibili_cc');
    expect(result.first.matchScore, 0.95);
    expect(result.first.lyrics.lines.first.text, '窗外的麻雀');
    expect(
      result.first.lyrics.lines.first.timestamp,
      const Duration(milliseconds: 1500),
    );
    expect(result.first.lrcText, contains('[00:01.50]窗外的麻雀'));
  });
}
