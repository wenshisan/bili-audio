/// 专辑资料查询条件。字段和歌词查询对齐，方便用同一套歌名清洗。
class AlbumQuery {
  const AlbumQuery({
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
  final String title;
  final String? artist;
  final Duration duration;

  /// 分 P 原始标题。管理器会再清洗一次。
  final String? rawTitle;

  /// 为 true 时不把 [artist] 传给远端，打分仍然使用它。
  final bool omitArtistFilter;
}

/// 一个源返回的专辑图、年份和介绍。
class AlbumCandidate {
  const AlbumCandidate({
    required this.source,
    required this.matchScore,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    this.albumName,
    this.year,
    this.coverUrl,
    this.description,
  });

  final String source;
  final double matchScore;
  final String title;
  final String artist;
  final int durationSeconds;
  final String? albumName;
  final int? year;
  final String? coverUrl;
  final String? description;

  AlbumCandidate withScore(double score) => AlbumCandidate(
    source: source,
    matchScore: score,
    title: title,
    artist: artist,
    durationSeconds: durationSeconds,
    albumName: albumName,
    year: year,
    coverUrl: coverUrl,
    description: description,
  );
}

/// 专辑源连不上或读响应超时。管理器会重试一次，再换下一个源。
class AlbumSourceUnavailable implements Exception {
  const AlbumSourceUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 专辑图和介绍的来源。
///
/// 数字越小越优先。图、年份、介绍可以来自不同的源：
/// 当前源缺了哪一项，就继续问后面的源。
abstract interface class AlbumProvider {
  String get name;
  int get priority;

  /// HTTP 错误返回空列表。连接或读取超时抛 [AlbumSourceUnavailable]。
  Future<List<AlbumCandidate>> search(AlbumQuery query);
}
