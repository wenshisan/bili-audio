import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/domain/title/title_cleaner.dart';
import 'package:bili_audio/domain/title/title_rule.dart';
import 'package:bili_audio/domain/entities/video.dart';

void main() {
  late TitleCleaner cleaner;

  setUp(() {
    // 使用测试规则配置
    final config = const TitleRuleConfig(
      version: 1,
      rules: [
        TitleRule(
          id: 'bracket_quality',
          type: 'remove',
          pattern: r'[【\[(（「](?:Hi-?Res|无损|FLAC|320K)[^】\])）」]*[】\])）」]',
        ),
        TitleRule(
          id: 'no_lyrics',
          type: 'flag',
          pattern: '伴奏|纯音乐|Instrumental',
          flag: 'noLyrics',
        ),
        TitleRule(
          id: 'sep_dash',
          type: 'split',
          pattern: r'\s[-—]\s',
          order: 'title_artist',
          priority: 10,
        ),
        TitleRule(
          id: 'extract_quotes',
          type: 'extract',
          pattern: r'[《「『]([^》」』]+)[》」』]',
          group: 'title',
          priority: 15,
        ),
      ],
    );
    cleaner = TitleCleaner(config);
  });

  group('TitleCleaner 基础功能', () {
    test('删除音质标签', () {
      final result = cleaner.clean('周杰伦 - 七里香【Hi-Res】');
      expect(result.name, '周杰伦');
      expect(result.artist, '七里香');
      expect(result.appliedRuleIds, contains('bracket_quality'));
    });

    test('标记纯音乐', () {
      final result = cleaner.clean('夜的钢琴曲5 纯音乐');
      expect(result.flags, contains('noLyrics'));
      expect(result.appliedRuleIds, contains('no_lyrics'));
    });

    test('破折号分隔', () {
      final result = cleaner.clean('七里香 - 周杰伦');
      expect(result.name, '七里香');
      expect(result.artist, '周杰伦');
      expect(result.appliedRuleIds, contains('sep_dash'));
    });

    test('提取书名号内容', () {
      final result = cleaner.clean('《稻香》周杰伦');
      expect(result.name, '稻香');
      expect(result.appliedRuleIds, contains('extract_quotes'));
    });

    test('规则优先级：提取优先于分隔', () {
      final result = cleaner.clean('《七里香》 - 周杰伦');
      expect(result.name, '七里香');
      // extract_quotes 优先级 15 > sep_dash 优先级 10
    });
  });

  group('PRD 示例验证', () {
    test('示例1: 七里香【Hi-Res】', () {
      final result = cleaner.clean('七里香【Hi-Res】');
      expect(result.name, '七里香');
    });

    test('示例2: 周杰伦 - 稻香', () {
      final result = cleaner.clean('周杰伦 - 稻香');
      expect(result.name, '周杰伦');
      expect(result.artist, '稻香');
    });

    test('示例3: 《夜曲》钢琴版', () {
      final result = cleaner.clean('《夜曲》钢琴版');
      expect(result.name, '夜曲');
    });
  });

  group('兜底逻辑', () {
    test('无规则匹配时保留原标题', () {
      final result = cleaner.clean('普通标题');
      expect(result.name, '普通标题');
      expect(result.artist, isNull);
    });

    test('使用UP主作为候选歌手', () {
      final video = const Video(
        bvid: 'BV1xx411c7mD',
        title: '测试视频',
        uploader: '周杰伦',
        uploaderMid: 123,
        cover: 'http://example.com/cover.jpg',
        pages: [],
      );
      final result = cleaner.clean('七里香', video: video);
      expect(result.artistCandidates, contains('周杰伦'));
    });
  });

  group('用户禁用规则', () {
    test('禁用规则不生效', () {
      final result = cleaner.clean(
        '七里香【Hi-Res】',
        disabledRuleIds: {'bracket_quality'},
      );
      // 规则被禁用，标签不应被删除
      expect(result.name, contains('Hi-Res'));
      expect(result.appliedRuleIds, isNot(contains('bracket_quality')));
    });
  });
}
