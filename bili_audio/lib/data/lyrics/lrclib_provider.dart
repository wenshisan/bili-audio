import 'package:dio/dio.dart';

import '../../domain/lyrics/lrc_parser.dart';
import '../../domain/lyrics/lyrics_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';

/// LRCLIB 歌词源 (M5.2)
///
/// `GET https://lrclib.net/api/search?track_name&artist_name`
/// 只取带同步歌词 (`syncedLyrics`) 的结果, 用 [LyricsScorer] 打分并按得分降序返回。
/// 超时 5s; 任何失败返回空列表。
class LrclibProvider implements LyricsProvider {
  LrclibProvider({
    Dio? dio,
    LyricsScorer? scorer,
    this.userAgent = 'BiliAudio/0.1.0 (https://github.com/)',
  })  : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://lrclib.net',
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            )),
        _scorer = scorer ?? LyricsScorer();

  final Dio _dio;
  final LyricsScorer _scorer;
  final String userAgent;

  @override
  String get name => 'lrclib';

  @override
  int get priority => 10;

  @override
  Future<List<LyricsCandidate>> search(LyricsQuery query) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '/api/search',
        queryParameters: {
          'track_name': query.title,
          if (query.artist != null && query.artist!.isNotEmpty)
            'artist_name': query.artist,
        },
        options: Options(headers: {'User-Agent': userAgent}),
      );
      final candidates = <LyricsCandidate>[];
      for (final item in res.data ?? const []) {
        if (item is! Map<String, dynamic>) continue;
        final synced = item['syncedLyrics'] as String?;
        if (synced == null || synced.trim().isEmpty) continue;
        final title = item['trackName'] as String? ?? '';
        final artist = item['artistName'] as String? ?? '';
        final seconds = (item['duration'] as num?)?.round() ?? 0;
        final match = _scorer.score(
          trackTitle: query.title,
          trackArtist: query.artist ?? '',
          trackDuration: query.duration.inSeconds,
          lyricsTitle: title,
          lyricsArtist: artist,
          lyricsDuration: seconds,
        );
        final lyrics = LrcParser.parse(synced);
        if (lyrics.lines.isEmpty) continue;
        candidates.add(LyricsCandidate(
          lyrics: lyrics.copyWith(source: name, matchScore: match.score),
          source: name,
          matchScore: match.score,
          originalTitle: title,
          originalArtist: artist,
          lrcText: synced,
        ));
      }
      candidates.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return candidates;
    } catch (_) {
      return const [];
    }
  }
}
