import 'dart:math';

import '../text_normalization.dart';
import '../title/title_cleaner.dart';

/// 歌词相似度评分器 (M1.5)
///
/// 用于评估搜索到的歌词是否匹配当前曲目。
class LyricsScorer {
  LyricsScorer({this.autoThreshold = 0.80, this.manualThreshold = 0.60});

  final double autoThreshold;
  final double manualThreshold;

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

  /// 标题相似度
  double _titleSimilarity(String a, String b) {
    final normA = normalizeForMatch(a);
    final normB = normalizeForMatch(b);

    // Levenshtein + Jaccard
    final lev = _levenshteinSimilarity(normA, normB);
    final jaccard = _jaccardSimilarity(_tokenize(normA), _tokenize(normB));

    // 中文串额外计算拼音相似度
    var pinyinSim = 0.0;
    if (_hasChinese(a) || _hasChinese(b)) {
      final pinyinA = toPinyin(normA);
      final pinyinB = toPinyin(normB);
      pinyinSim = _levenshteinSimilarity(pinyinA, pinyinB);
    }

    final contained = _containmentSimilarity(normA, normB);
    return [lev, jaccard, pinyinSim, contained].reduce(max);
  }

  /// 歌手相似度 (多歌手取最大值)
  double _artistSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;

    final artistsA = _splitArtists(a);
    final artistsB = _splitArtists(b);

    var maxSim = 0.0;
    for (final artA in artistsA) {
      for (final artB in artistsB) {
        final normA = normalizeForMatch(artA);
        final normB = normalizeForMatch(artB);
        var sim = _levenshteinSimilarity(normA, normB);
        if (sim < 1 && (_hasChinese(artA) || _hasChinese(artB))) {
          sim = max(
            sim,
            _levenshteinSimilarity(toPinyin(normA), toPinyin(normB)),
          );
        }
        maxSim = max(maxSim, sim);
      }
    }
    return maxSim;
  }

  /// 时长相似度
  double _durationSimilarity(int durationA, int durationB) {
    final delta = (durationA - durationB).abs();
    return max(0.0, 1.0 - delta / 10.0);
  }

  /// Levenshtein 距离相似度
  double _levenshteinSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final maxLen = max(a.length, b.length);
    final distance = _levenshteinDistance(a, b);
    return max(0.0, 1.0 - distance / maxLen);
  }

  /// Levenshtein 距离
  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }

    return matrix[a.length][b.length];
  }

  /// 一方包含另一方，且多出来的只是 Live / 无损 / 年份时视为同一首歌。
  double _containmentSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final shorter = a.length <= b.length ? a : b;
    final longer = a.length <= b.length ? b : a;
    if (shorter.length < 2 || !longer.contains(shorter)) return 0;
    final extra = longer
        .replaceFirst(shorter, '')
        .replaceAll(RegExp(r'[\s\d._+\-]+'), '');
    if (extra.isEmpty || _versionExtra.hasMatch(extra)) return 0.92;
    return 0;
  }

  static final _versionExtra = RegExp(
    r'^(?:live|remix|cover|inst|instrumental|acoustic|demo|ost|mv|pv|tv|ver|version|hires|flac|dsd|ape|wav|official|翻唱|现场|演唱会|钢琴|吉他|伴奏|纯音乐|女声|男声|烟嗓|完整|原版|歌词)+$',
    caseSensitive: false,
  );

  /// Jaccard 相似度
  double _jaccardSimilarity(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return intersection / union;
  }

  /// 分词
  Set<String> _tokenize(String text) {
    // 中文按字，拉丁按空白/标点
    final tokens = <String>{};
    final buffer = StringBuffer();

    for (final char in text.runes) {
      final str = String.fromCharCode(char);
      if (_isChinese(str)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(str);
      } else if (RegExp(r'[a-z0-9]').hasMatch(str)) {
        buffer.write(str);
      } else {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }

  /// 拆分歌手列表
  List<String> _splitArtists(String artists) {
    return artists
        .split(RegExp(r'[、&,，]|feat\.?|ft\.?|\sx\s', caseSensitive: false))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool _isChinese(String char) {
    final code = char.runes.first;
    return code >= 0x4e00 && code <= 0x9fff;
  }

  bool _hasChinese(String text) {
    return text.runes.any((code) => code >= 0x4e00 && code <= 0x9fff);
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
