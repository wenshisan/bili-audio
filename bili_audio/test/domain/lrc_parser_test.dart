import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/domain/lyrics/lrc_parser.dart';

void main() {
  group('LrcParser 基础功能', () {
    test('解析 [mm:ss] 格式', () {
      const lrc = '[00:12]第一行\n[00:17]第二行';
      final lyrics = LrcParser.parse(lrc);

      expect(lyrics.lines.length, 2);
      expect(lyrics.lines[0].timestamp, const Duration(seconds: 12));
      expect(lyrics.lines[0].text, '第一行');
      expect(lyrics.lines[1].timestamp, const Duration(seconds: 17));
      expect(lyrics.lines[1].text, '第二行');
    });

    test('解析 [mm:ss.xx] 格式', () {
      const lrc = '[00:12.50]半秒';
      final lyrics = LrcParser.parse(lrc);

      expect(lyrics.lines[0].timestamp, const Duration(milliseconds: 12500));
      expect(lyrics.lines[0].text, '半秒');
    });

    test('解析 [mm:ss.xxx] 格式', () {
      const lrc = '[00:12.345]毫秒精度';
      final lyrics = LrcParser.parse(lrc);

      expect(lyrics.lines[0].timestamp, const Duration(milliseconds: 12345));
    });

    test('单行多时间戳', () {
      const lrc = '[00:12][00:24]重复行';
      final lyrics = LrcParser.parse(lrc);

      expect(lyrics.lines.length, 2);
      expect(lyrics.lines[0].timestamp, const Duration(seconds: 12));
      expect(lyrics.lines[0].text, '重复行');
      expect(lyrics.lines[1].timestamp, const Duration(seconds: 24));
      expect(lyrics.lines[1].text, '重复行');
    });

    test('解析 offset 偏移量', () {
      const lrc = '[offset:500]\n[00:12]偏移测试';
      final lyrics = LrcParser.parse(lrc);

      expect(lyrics.offset, const Duration(milliseconds: 500));
    });

    test('同时间戳合并为翻译', () {
      const lrc = '[00:12]Hello\n[00:12]你好';
      final lyrics = LrcParser.parse(lrc);

      expect(lyrics.lines.length, 1);
      expect(lyrics.lines[0].text, 'Hello');
      expect(lyrics.lines[0].translation, '你好');
    });

    test('元数据标签', () {
      const lrc = '[ti:歌曲名]\n[ar:歌手]\n[00:12]歌词';
      final lyrics = LrcParser.parse(lrc);

      expect(lyrics.lines.length, 1);
    });
  });

  group('LrcParser 鲁棒性', () {
    test('乱序时间戳自动排序', () {
      const lrc = '[00:30]第三行\n[00:10]第一行\n[00:20]第二行';
      final lyrics = LrcParser.parse(lrc);

      expect(lyrics.lines[0].timestamp, const Duration(seconds: 10));
      expect(lyrics.lines[1].timestamp, const Duration(seconds: 20));
      expect(lyrics.lines[2].timestamp, const Duration(seconds: 30));
    });

    test('空行忽略', () {
      const lrc = '[00:12]第一行\n\n\n[00:17]第二行';
      final lyrics = LrcParser.parse(lrc);

      expect(lyrics.lines.length, 2);
    });

    test('无时间戳行忽略', () {
      const lrc = '这是注释\n[00:12]正常行\n另一个注释';
      final lyrics = LrcParser.parse(lrc);

      expect(lyrics.lines.length, 1);
      expect(lyrics.lines[0].text, '正常行');
    });
  });

  group('LyricsTimeline', () {
    late LyricsTimeline timeline;

    setUp(() {
      const lrc = '''
[00:10]第一行
[00:20]第二行
[00:30]第三行
''';
      final lyrics = LrcParser.parse(lrc);
      timeline = LyricsTimeline(lyrics);
    });

    test('查找当前行', () {
      expect(timeline.indexAt(const Duration(seconds: 5)), -1);
      expect(timeline.indexAt(const Duration(seconds: 10)), 0);
      expect(timeline.indexAt(const Duration(seconds: 15)), 0);
      expect(timeline.indexAt(const Duration(seconds: 20)), 1);
      expect(timeline.indexAt(const Duration(seconds: 25)), 1);
      expect(timeline.indexAt(const Duration(seconds: 30)), 2);
      expect(timeline.indexAt(const Duration(seconds: 40)), 2);
    });

    test('获取当前行内容', () {
      final line = timeline.lineAt(const Duration(seconds: 15));
      expect(line?.text, '第一行');
    });

    test('应用 offset', () {
      const lrc = '[offset:-500]\n[00:10]测试';
      final lyrics = LrcParser.parse(lrc);
      final tl = LyricsTimeline(lyrics);

      // offset = -500ms, 所以 9.5s 时应该显示 10s 的歌词
      expect(tl.indexAt(const Duration(milliseconds: 9500)), 0);
    });
  });
}
