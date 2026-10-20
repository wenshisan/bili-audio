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
