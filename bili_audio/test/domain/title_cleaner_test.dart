import 'dart:io';

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

  group('播放日志样本', () {
    late TitleCleaner assetCleaner;

    setUp(() {
      assetCleaner = TitleCleaner.fromJson(
        File('assets/config/title_cleaning_rules.json').readAsStringSync(),
      );
    });

    void expectClean(String raw, String name, String? artist) {
      final result = assetCleaner.clean(raw);
      expect(result.name, name, reason: raw);
      expect(result.artist, artist, reason: raw);
    }

    test('合集序号 + 歌手-歌名', () {
      expectClean('97.我的地盘', '我的地盘', null);
      expectClean('011.周杰伦-以父之名', '以父之名', '周杰伦');
      expectClean('006.周杰伦-等你下课', '等你下课', '周杰伦');
      expectClean('007.周杰伦-稻香', '稻香', '周杰伦');
    });

    test('书名号歌名并保留外侧歌手', () {
      expectClean('《搁浅》周杰伦丨百万级录音棚试听丨【Hi-Res无损】', '搁浅', '周杰伦');
      expectClean('《七里香》周杰伦丨百万级录音棚试听丨【Hi-Res无损】', '七里香', '周杰伦');
    });

    test('空格破折号是歌名 - 歌手，括号里的剧名不是歌名', () {
      expectClean('如烟 - 张碧晨（《淮水竹亭》影视剧主题曲/片尾曲）', '如烟', '张碧晨');
    });

    test('解说尾巴和音质标签', () {
      expectClean('【女烟嗓版】如烟——听懂以后，才发现它写的是人的一生', '如烟', null);
      expectClean('【4K Hi-Res】如烟_五月天     还欠了他一生', '如烟', '五月天');
      expectClean('周杰伦-龙拳(无损音质4K60MV)[中文字幕]Hi-Res(FLAC24/48)', '龙拳', '周杰伦');
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
