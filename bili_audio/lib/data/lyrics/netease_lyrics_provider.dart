import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/lyrics/lrc_parser.dart';
import '../../domain/lyrics/lyrics_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';
import '../../domain/title/title_cleaner.dart';
import 'lyrics_http.dart';

/// 网易云歌词。搜索曲目后只拉取得分最高的一首同步歌词。
class NeteaseLyricsProvider implements LyricsProvider {
  NeteaseLyricsProvider({Dio? dio, LyricsScorer? scorer})
    : _dio =
          dio ??
          lyricsClient(
            'https://music.163.com',
            headers: const {
              'Referer': 'https://music.163.com',
              'User-Agent': 'Mozilla/5.0',
            },
          ),
      _scorer = scorer ?? LyricsScorer();

  final Dio _dio;
  final LyricsScorer _scorer;

  @override
  String get name => 'netease';

  @override
  int get priority => 8;

  @override
  Future<List<LyricsCandidate>> search(LyricsQuery query) async {
    final loose = TitleCleaner.parseLoose(query.title);
    final title = loose.name.trim().isEmpty ? query.title : loose.name.trim();
    final givenArtist = query.artist?.trim();
    final artist = (givenArtist != null && givenArtist.isNotEmpty)
        ? givenArtist
        : loose.artist;
    final keyword = [
      title,
      if (artist != null && artist.isNotEmpty) artist,
    ].join(' ');
    try {
      final found = await _dio.get<Map<String, dynamic>>(
        '/api/search/get/web',
        queryParameters: {'s': keyword, 'type': 1, 'offset': 0, 'limit': 5},
        options: lyricsRequestOptions(),
      );
      final songs = _songs(
        found.data,
        title: title,
        artist: artist ?? '',
        duration: query.duration.inSeconds,
      );
      if (songs.isEmpty) {
        AppLogger.d('netease "$keyword" hits=0', tag: 'lyrics');
        return const [];
      }
      final candidates = <LyricsCandidate>[];
      for (final song in songs.take(3)) {
        final lyric = await _dio.get<Map<String, dynamic>>(
          '/api/song/lyric',
          queryParameters: {'id': song.id, 'lv': 1, 'kv': 1, 'tv': -1},
          options: lyricsRequestOptions(),
        );
        final lrc = lyric.data?['lrc'];
        final text = lrc is Map<dynamic, dynamic> ? lrc['lyric'] as String? : null;
        if (text == null || !text.contains('[')) continue;
        final lyrics = LrcParser.parse(text);
        if (lyrics.lines.isEmpty) continue;
        candidates.add(
          LyricsCandidate(
            lyrics: lyrics.copyWith(source: name, matchScore: song.score),
            source: name,
            matchScore: song.score,
            originalTitle: song.name,
            originalArtist: song.artist,
            lrcText: text,
          ),
        );
      }
      AppLogger.d(
        'netease "$keyword" hits=${candidates.length} '
        'best=${candidates.isEmpty ? '-' : candidates.first.originalTitle}',
        tag: 'lyrics',
      );
      return candidates;
    } on DioException catch (e) {
      AppLogger.w('netease "$keyword" failed: ${e.type}', tag: 'lyrics');
      throwIfLyricsTransport(e, 'netease');
      return const [];
    } catch (e) {
      if (e is LyricsSourceUnavailable) rethrow;
      AppLogger.w('netease "$keyword" failed: $e', tag: 'lyrics');
      return const [];
    }
  }

  List<_NeteaseSong> _songs(
    Map<String, dynamic>? body, {
    required String title,
    required String artist,
    required int duration,
  }) {
    final result = body?['result'];
    final songs = result is Map<dynamic, dynamic> ? result['songs'] : null;
    if (songs is! List || songs.isEmpty) return const [];
    final ranked = <_NeteaseSong>[];
    for (final item in songs) {
      if (item is! Map<dynamic, dynamic>) continue;
      final id = item['id'];
      final name = item['name'];
      if (id is! num || name is! String || name.isEmpty) continue;
      final artists = item['artists'];
      final names = artists is List
          ? artists
                .whereType<Map<dynamic, dynamic>>()
                .map((artist) => '${artist['name'] ?? ''}')
                .where((name) => name.isNotEmpty)
                .join(' & ')
          : '';
      final ms = item['duration'];
      final seconds = ms is num ? (ms / 1000).round() : 0;
      final score = _scorer.pick(
        trackTitle: title,
        trackArtist: artist,
        trackDuration: duration,
        lyricsTitle: name,
        lyricsArtist: names,
        lyricsDuration: seconds,
      );
      if (score == null) continue;
      ranked.add(_NeteaseSong(id.toInt(), name, names, score));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }
}

class _NeteaseSong {
  const _NeteaseSong(this.id, this.name, this.artist, this.score);

  final int id;
  final String name;
  final String artist;
  final double score;
}
