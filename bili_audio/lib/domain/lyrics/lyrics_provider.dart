import '../entities/lyrics.dart';

/// 歌词查询条件 (M5.1)
class LyricsQuery {
  const LyricsQuery({
    required this.bvid,
    required this.cid,
    required this.title,
    this.artist,
    required this.duration,
  });

  final String bvid;
  final int cid;

  /// 清洗后歌名
  final String title;
  final String? artist;
  final Duration duration;
}

/// 歌词候选 (M5.1)
class LyricsCandidate {
  const LyricsCandidate({
    required this.lyrics,
    required this.source,
    required this.matchScore,
    this.originalTitle,
    this.originalArtist,
    this.lrcText,
  });

  final Lyrics lyrics;

  /// 来源标识, 如 'lrclib' / 'local'
  final String source;

  /// 0-1 匹配得分
  final double matchScore;
  final String? originalTitle;
  final String? originalArtist;

  /// 原始 LRC 文本, 写入本地缓存用
  final String? lrcText;
}

/// 歌词提供者 (M5.1)
///
/// 数字越小越优先; 按优先级依次查询, 首个得分 ≥ 自动阈值的候选即停止。
abstract interface class LyricsProvider {
  String get name;
  int get priority;

  /// 失败时返回空列表, 不抛异常 (不阻塞后续提供者)
  Future<List<LyricsCandidate>> search(LyricsQuery query);
}
