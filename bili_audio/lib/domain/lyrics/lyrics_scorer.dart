import 'dart:math';

import '../title/fuzzy_match.dart';
import '../title/title_cleaner.dart';

/// 歌词相似度评分器 (M1.5)
///
/// 用于评估搜索到的歌词是否匹配当前曲目。歌名和歌手走 [FuzzyMatcher]。
class LyricsScorer {
  LyricsScorer({
    this.autoThreshold = 0.80,
    this.manualThreshold = 0.60,
    FuzzyMatcher? fuzzy,
  }) : _fuzzy = fuzzy ?? const FuzzyMatcher();

  final double autoThreshold;
  final double manualThreshold;
  final FuzzyMatcher _fuzzy;

  /// 计算匹配得分
  ///
  /// 返回 0-1 之间的得分和匹配决策。
  LyricsMatch score({
    required String trackTitle,
    required String trackArtist,
    required int trackDuration,
    required String lyricsTitle,
    required String lyricsArtist,
    required int lyricsDuration,
  }) {
    final track = TitleCleaner.parseLoose(trackTitle);
    final lyrics = TitleCleaner.parseLoose(lyricsTitle);
    final titleA = track.name.isEmpty ? trackTitle : track.name;
    final titleB = lyrics.name.isEmpty ? lyricsTitle : lyrics.name;
    final artistA = trackArtist.trim().isNotEmpty
        ? trackArtist
        : (track.artist ?? '');
    final artistB = lyricsArtist.trim().isNotEmpty
        ? lyricsArtist
        : (lyrics.artist ?? '');

    final titleSim = _titleSimilarity(titleA, titleB);
    final artistSim = _artistSimilarity(artistA, artistB);
    final durationSim = _durationSimilarity(trackDuration, lyricsDuration);

    // 权重: title 55%, artist 25%, duration 20%
    // 如果 artist 为空，权重调整为 title 80%, duration 20%
    final score = artistA.isEmpty
        ? 0.80 * titleSim + 0.20 * durationSim
        : 0.55 * titleSim + 0.25 * artistSim + 0.20 * durationSim;

    final decision = score >= autoThreshold
        ? MatchDecision.auto
        : score >= manualThreshold
        ? MatchDecision.uncertain
        : MatchDecision.manual;

    return LyricsMatch(
      score: score,
      decision: decision,
      titleSimilarity: titleSim,
      artistSimilarity: artistSim,
      durationSimilarity: durationSim,
    );
  }

  /// 这条歌词是不是当前这首歌。
  ///
  /// 歌名对不上就丢掉。歌名和歌手写反时换一个方向再认一次，
  /// 但结果歌名只是对上了歌手、歌手对不上歌名的，仍然丢掉。
  /// 这样「周杰伦 / 米兰的小铁匠」不会出现在《搁浅》的待选里。
  double? pick({
    required String trackTitle,
    required String trackArtist,
    required int trackDuration,
    required String lyricsTitle,
    required String lyricsArtist,
    required int lyricsDuration,
  }) {
    final direct = _accepted(
      score(
        trackTitle: trackTitle,
        trackArtist: trackArtist,
        trackDuration: trackDuration,
        lyricsTitle: lyricsTitle,
        lyricsArtist: lyricsArtist,
        lyricsDuration: lyricsDuration,
      ),
      lyricsArtist: lyricsArtist,
    );
    final artist = trackArtist.trim();
    if (artist.isEmpty || artist == trackTitle.trim()) return direct?.score;
    final flipped = _accepted(
      score(
        trackTitle: artist,
        trackArtist: trackTitle,
        trackDuration: trackDuration,
        lyricsTitle: lyricsTitle,
        lyricsArtist: lyricsArtist,
        lyricsDuration: lyricsDuration,
      ),
      lyricsArtist: lyricsArtist,
    );
    if (direct == null) return flipped?.score;
    if (flipped == null) return direct.score;
    return max(direct.score, flipped.score);
  }

  LyricsMatch? _accepted(LyricsMatch match, {required String lyricsArtist}) {
    if (match.titleSimilarity < 0.5) return null;
    if (lyricsArtist.trim().isNotEmpty && match.artistSimilarity < 0.4) {
      return null;
    }
    return match;
  }

  double _titleSimilarity(String a, String b) => _fuzzy.similarity(a, b);

  /// 歌手相似度。多名歌手拆开后取最高的一对。
  double _artistSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;

    var maxSim = 0.0;
    for (final artA in _splitArtists(a)) {
      for (final artB in _splitArtists(b)) {
        maxSim = max(maxSim, _fuzzy.similarity(artA, artB));
      }
    }
    return maxSim;
  }

  /// 时长相似度
  double _durationSimilarity(int durationA, int durationB) {
    final delta = (durationA - durationB).abs();
    return max(0.0, 1.0 - delta / 10.0);
  }

  /// 拆分歌手列表
  List<String> _splitArtists(String artists) {
    return artists
        .split(RegExp(r'[、&,，]|feat\.?|ft\.?|\sx\s', caseSensitive: false))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

/// 匹配决策 (M1.5)
enum MatchDecision {
  /// 自动匹配 (≥0.80)
  auto,

  /// 不确定 (0.60-0.80)
  uncertain,

  /// 需要手动确认 (<0.60)
  manual,
}

/// 歌词匹配结果 (M1.5)
class LyricsMatch {
  LyricsMatch({
    required this.score,
    required this.decision,
    required this.titleSimilarity,
    required this.artistSimilarity,
    required this.durationSimilarity,
  });

  final double score;
  final MatchDecision decision;
  final double titleSimilarity;
  final double artistSimilarity;
  final double durationSimilarity;
}
