import '../entities/lyrics.dart';

/// 歌词查询条件 (M5.1)
class LyricsQuery {
  const LyricsQuery({
    required this.bvid,
    required this.cid,
    required this.title,
    this.artist,
    required this.duration,
    this.rawTitle,
    this.omitArtistFilter = false,
  });

  final String bvid;
  final int cid;

  /// 用于搜索和打分的歌名
  final String title;
  final String? artist;
  final Duration duration;

  /// 分P原始标题。管理器会再清洗一次，避免库里的旧歌名带序号和修饰。
  final String? rawTitle;

  /// 为 true 时不把 [artist] 传给远端，打分仍然使用它。
  /// 艺人名写法不一致时，带艺人过滤会把正确歌词滤掉。
  final bool omitArtistFilter;
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

/// 歌词源连不上或读响应超时。管理器会重试一次，再换下一个歌词源。
class LyricsSourceUnavailable implements Exception {
  const LyricsSourceUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 歌词提供者 (M5.1)
///
/// 数字越小越优先; 按优先级依次查询, 首个得分 ≥ 自动阈值的候选即停止。
abstract interface class LyricsProvider {
  String get name;
  int get priority;

  /// HTTP 错误返回空列表。连接或读取超时抛 [LyricsSourceUnavailable]。
  Future<List<LyricsCandidate>> search(LyricsQuery query);
}
