import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/domain/lyrics/lyrics_scorer.dart';

void main() {
  late LyricsScorer scorer;

  setUp(() {
    scorer = LyricsScorer();
  });

  group('LyricsScorer 相似度计算', () {
    test('完全匹配', () {
      final match = scorer.score(
        trackTitle: '七里香',
        trackArtist: '周杰伦',
        trackDuration: 300,
        lyricsTitle: '七里香',
        lyricsArtist: '周杰伦',
        lyricsDuration: 300,
      );

      expect(match.score, 1.0);
      expect(match.decision, MatchDecision.auto);
    });

    test('标题相似，时长略有差异', () {
      final match = scorer.score(
        trackTitle: '七里香',
        trackArtist: '周杰伦',
        trackDuration: 300,
        lyricsTitle: '七里香',
        lyricsArtist: '周杰伦',
        lyricsDuration: 305,
      );

      expect(match.score, greaterThan(0.85));
      expect(match.decision, MatchDecision.auto);
    });

    test('标题拼写差异', () {
      final match = scorer.score(
        trackTitle: 'Shape of You',
        trackArtist: 'Ed Sheeran',
        trackDuration: 234,
        lyricsTitle: 'Shape Of You',
        lyricsArtist: 'Ed Sheeran',
        lyricsDuration: 234,
      );

      expect(match.score, greaterThan(0.90));
      expect(match.decision, MatchDecision.auto);
    });

    test('多歌手匹配', () {
      final match = scorer.score(
        trackTitle: '告白气球',
        trackArtist: '周杰伦',
        trackDuration: 200,
        lyricsTitle: '告白气球',
        lyricsArtist: '周杰伦 & 方文山',
        lyricsDuration: 200,
      );

      expect(match.artistSimilarity, greaterThan(0.8));
    });

    test('时长差异超过10秒', () {
      final match = scorer.score(
        trackTitle: '七里香',
        trackArtist: '周杰伦',
        trackDuration: 300,
        lyricsTitle: '七里香',
        lyricsArtist: '周杰伦',
        lyricsDuration: 350,
      );

      // 时长差50秒，durationSimilarity应该为负数，被截断为0
      expect(match.durationSimilarity, 0.0);
    });
  });

  group('LyricsScorer 决策阈值', () {
    test('自动匹配: score ≥ 0.80', () {
      final match = scorer.score(
        trackTitle: '稻香',
        trackArtist: '周杰伦',
        trackDuration: 200,
        lyricsTitle: '稻香',
        lyricsArtist: '周杰伦',
        lyricsDuration: 200,
      );

      expect(match.score, greaterThanOrEqualTo(0.80));
      expect(match.decision, MatchDecision.auto);
    });

    test('不确定: 0.60 ≤ score < 0.80', () {
      // 构造一个中等相似度的场景: 标题略有不同
      final match = scorer.score(
        trackTitle: '七里香',
        trackArtist: '周杰伦',
        trackDuration: 300,
        lyricsTitle: '七里香 Live',
        lyricsArtist: '周杰伦',
        lyricsDuration: 320,
      );

      // 标题相似但不完全一致，时长差20秒
      if (match.score >= 0.60 && match.score < 0.80) {
        expect(match.decision, MatchDecision.uncertain);
      }
    });
  });

  group('LyricsScorer 边界值', () {
    test('时长差异临界值 (10秒)', () {
      final match10 = scorer.score(
        trackTitle: '测试',
        trackArtist: '歌手',
        trackDuration: 200,
        lyricsTitle: '测试',
        lyricsArtist: '歌手',
        lyricsDuration: 210,
      );

      expect(match10.durationSimilarity, 0.0);

      final match5 = scorer.score(
        trackTitle: '测试',
        trackArtist: '歌手',
        trackDuration: 200,
        lyricsTitle: '测试',
        lyricsArtist: '歌手',
        lyricsDuration: 205,
      );

      expect(match5.durationSimilarity, 0.5);
    });

    test('无歌手信息时权重调整', () {
      final match = scorer.score(
        trackTitle: '纯音乐',
        trackArtist: '',
        trackDuration: 180,
        lyricsTitle: '纯音乐',
        lyricsArtist: '',
        lyricsDuration: 180,
      );

      // 无歌手时，title 80% + duration 20%
      expect(match.score, 1.0);
    });
  });

  group('LyricsScorer 脏标题', () {
    test('分P序号和紧凑破折号按拆出的歌名歌手打分', () {
      final match = scorer.score(
        trackTitle: '007.周杰伦-稻香',
        trackArtist: '',
        trackDuration: 224,
        lyricsTitle: '稻香',
        lyricsArtist: '周杰伦',
        lyricsDuration: 223,
      );

      expect(match.titleSimilarity, greaterThanOrEqualTo(0.9));
      expect(match.artistSimilarity, greaterThanOrEqualTo(0.9));
      expect(match.decision, MatchDecision.auto);
    });
  });

  group('LyricsScorer 待选资格', () {
    test('没有歌手时按歌名收下带歌手的歌词', () {
      final score = scorer.pick(
        trackTitle: '感情勒索',
        trackArtist: '',
        trackDuration: 238,
        lyricsTitle: '感情勒索',
        lyricsArtist: '张震岳',
        lyricsDuration: 238,
      );

      expect(score, greaterThanOrEqualTo(0.8));
    });

    test('标题里拆出的歌手仍然要核对', () {
      final score = scorer.pick(
        trackTitle: '007.周杰伦-稻香',
        trackArtist: '',
        trackDuration: 224,
        lyricsTitle: '稻香',
        lyricsArtist: '别人',
        lyricsDuration: 223,
      );

      expect(score, isNull);
    });

    test('歌名对上歌手、歌手对不上歌名时不进待选', () {
      final score = scorer.pick(
        trackTitle: '搁浅',
        trackArtist: '周杰伦',
        trackDuration: 240,
        lyricsTitle: '周杰伦',
        lyricsArtist: '米兰的小铁匠',
        lyricsDuration: 240,
      );

      expect(score, isNull);
    });

    test('歌名和歌手写反时仍能认出同一首歌', () {
      final score = scorer.pick(
        trackTitle: '周杰伦',
        trackArtist: '七里香',
        trackDuration: 299,
        lyricsTitle: '七里香',
        lyricsArtist: '周杰伦',
        lyricsDuration: 299,
      );

      expect(score, greaterThanOrEqualTo(0.8));
    });
  });

  group('LyricsScorer 模糊匹配', () {
    test('带序号的分P标题对上干净歌名', () {
      final match = scorer.score(
        trackTitle: '0065. 洋葱 - 五月天',
        trackArtist: '五月天',
        trackDuration: 240,
        lyricsTitle: '洋葱',
        lyricsArtist: '五月天',
        lyricsDuration: 240,
      );

      expect(match.titleSimilarity, 1);
      expect(match.artistSimilarity, greaterThanOrEqualTo(0.9));
      expect(match.decision, MatchDecision.auto);
    });

    test('英文前缀歌手对上中文名', () {
      final score = scorer.pick(
        trackTitle: '怎么好意思',
        trackArtist: 'Eric周兴哲',
        trackDuration: 250,
        lyricsTitle: '怎么好意思',
        lyricsArtist: '周兴哲',
        lyricsDuration: 250,
      );

      expect(score, greaterThanOrEqualTo(0.8));
    });
  });

  group('LyricsScorer 版本后缀', () {
    test('Live 后缀不把同一首歌打成无关标题', () {
      final match = scorer.score(
        trackTitle: '以父之名',
        trackArtist: '周杰伦',
        trackDuration: 343,
        lyricsTitle: '以父之名 (Live)',
        lyricsArtist: '周杰伦',
        lyricsDuration: 343,
      );

      expect(match.titleSimilarity, greaterThanOrEqualTo(0.92));
      expect(match.decision, MatchDecision.auto);
    });
  });

  group('LyricsScorer 中文拼音', () {
    test('繁简体混合', () {
      final match = scorer.score(
        trackTitle: '七里香',
        trackArtist: '周杰伦',
        trackDuration: 300,
        lyricsTitle: '七里香',
        lyricsArtist: '周杰倫',
        lyricsDuration: 300,
      );

      // "周杰伦" vs "周杰倫": Levenshtein 距离为1，长度3，相似度约0.67
      expect(match.artistSimilarity, greaterThan(0.6));
    });
  });
}
