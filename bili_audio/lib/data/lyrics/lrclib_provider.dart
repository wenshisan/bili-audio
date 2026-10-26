import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/lyrics/lrc_parser.dart';
import '../../domain/lyrics/lyrics_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';
import '../../domain/title/title_cleaner.dart';
import 'lyrics_http.dart';

/// LRCLIB 歌词源 (M5.2)
///
/// `GET https://lrclib.net/api/search?track_name&artist_name`
/// 只取带同步歌词 (`syncedLyrics`) 的结果, 用 [LyricsScorer] 打分并按得分降序返回。
/// 超时 [lyricsRequestTimeout]，失败抛 [LyricsSourceUnavailable]。
class LrclibProvider implements LyricsProvider {
  LrclibProvider({
    Dio? dio,
    LyricsScorer? scorer,
    this.userAgent = 'BiliAudio/0.1.0 (https://github.com/)',
  }) : _dio = dio ?? lyricsClient('https://lrclib.net'),
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
    final corpus = TitleCleaner.searchCorpus(query.title, artist: query.artist);
    final title = corpus.title;
    final artist = corpus.artist;
    try {
      final filtered = !query.omitArtistFilter;
      var candidates = <LyricsCandidate>[];
      try {
        candidates = await _collect(
          {
            'track_name': title,
            if (filtered && artist != null && artist.isNotEmpty)
              'artist_name': artist,
          },
          title: title,
          artist: artist ?? '',
          duration: query.duration.inSeconds,
        );
      } on LyricsSourceUnavailable {
        candidates = <LyricsCandidate>[];
      }
      if (!_hasSong(candidates, title)) {
        final keyword = [
          title,
          if (artist != null && artist.isNotEmpty) artist,
        ].join(' ');
        try {
          candidates = _merge(
            candidates,
            await _collect(
              {'q': keyword},
              title: title,
              artist: artist ?? '',
              duration: query.duration.inSeconds,
            ),
          );
        } on LyricsSourceUnavailable {
          if (candidates.isEmpty) rethrow;
        }
      }
      final ranked = [...candidates]
        ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
      candidates = ranked;
      final best = candidates.isEmpty ? null : candidates.first;
      AppLogger.d(
        'lrclib "${query.title}" -> "$title" artist="${artist ?? ''}" '
        'filter=$filtered hits=${candidates.length} '
        'best=${best == null ? '-' : best.matchScore.toStringAsFixed(2)} '
        '"${best?.originalTitle ?? ''}"',
        tag: 'lyrics',
      );
      return candidates;
    } catch (e) {
      if (e is LyricsSourceUnavailable) rethrow;
      AppLogger.w(
        'lrclib "$title" artist="${artist ?? ''}" failed: $e',
        tag: 'lyrics',
      );
      return const [];
    }
  }

  bool _hasSong(List<LyricsCandidate> candidates, String title) {
    for (final candidate in candidates) {
      final lyricsTitle = candidate.originalTitle ?? '';
      if (lyricsTitle.isEmpty) continue;
      final match = _scorer.score(
        trackTitle: title,
        trackArtist: '',
        trackDuration: 0,
        lyricsTitle: lyricsTitle,
        lyricsArtist: '',
        lyricsDuration: 0,
      );
      if (match.titleSimilarity >= 0.5) return true;
    }
    return false;
  }

  Future<List<LyricsCandidate>> _collect(
    Map<String, dynamic> query, {
    required String title,
    required String artist,
    required int duration,
  }) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '/api/search',
        queryParameters: query,
        options: lyricsRequestOptions(headers: {'User-Agent': userAgent}),
      );
      final candidates = <LyricsCandidate>[];
      for (final item in res.data ?? const <dynamic>[]) {
        if (item is! Map<String, dynamic>) continue;
        final synced = item['syncedLyrics'] as String?;
        if (synced == null || synced.trim().isEmpty) continue;
        final lyricsTitle = item['trackName'] as String? ?? '';
        final lyricsArtist = item['artistName'] as String? ?? '';
        final seconds = (item['duration'] as num?)?.round() ?? 0;
        final match = _scorer.score(
          trackTitle: title,
          trackArtist: artist,
          trackDuration: duration,
          lyricsTitle: lyricsTitle,
          lyricsArtist: lyricsArtist,
          lyricsDuration: seconds,
        );
        final lyrics = LrcParser.parse(synced);
        if (lyrics.lines.isEmpty) continue;
        candidates.add(
          LyricsCandidate(
            lyrics: lyrics.copyWith(source: name, matchScore: match.score),
            source: name,
            matchScore: match.score,
            originalTitle: lyricsTitle,
            originalArtist: lyricsArtist,
            lrcText: synced,
          ),
        );
      }
      return candidates;
    } on DioException catch (e) {
      AppLogger.w(
        'lrclib "$title" artist="$artist" failed: ${e.type}',
        tag: 'lyrics',
      );
      throwIfLyricsTransport(e, 'lrclib');
      return const [];
    }
  }

  List<LyricsCandidate> _merge(
    List<LyricsCandidate> first,
    List<LyricsCandidate> second,
  ) {
    final all = [...first];
    for (final candidate in second) {
      final exists = all.any(
        (e) =>
            e.originalTitle == candidate.originalTitle &&
            e.originalArtist == candidate.originalArtist,
      );
      if (!exists) all.add(candidate);
    }
    return all;
  }
}
