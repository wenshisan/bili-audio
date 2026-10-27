import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/lyrics/lrc_parser.dart';
import '../../domain/lyrics/lyrics_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';
import '../../domain/title/title_cleaner.dart';
import 'lyrics_http.dart';

/// QQ 音乐歌词。
///
/// 搜索曲目后只拉取得分最高的几首同步歌词。排在 B 站字幕后面、LRCLIB 前面。
class QqLyricsProvider implements LyricsProvider {
  QqLyricsProvider({Dio? dio, LyricsScorer? scorer})
    : _dio =
          dio ??
          lyricsClient(
            'https://c.y.qq.com',
            headers: const {
              'Referer': 'https://y.qq.com',
              'User-Agent': 'Mozilla/5.0',
            },
          ),
      _scorer = scorer ?? LyricsScorer();

  final Dio _dio;
  final LyricsScorer _scorer;

  @override
  String get name => 'qq';

  @override
  int get priority => 6;

  @override
  Future<List<LyricsCandidate>> search(LyricsQuery query) async {
    final corpus = TitleCleaner.searchCorpus(query.title, artist: query.artist);
    final title = corpus.title;
    final artist = corpus.artist;
    final keyword = lyricsKeyword(
      title,
      artist,
      omitArtist: query.omitArtistFilter,
    );
    try {
      final found = await _dio.get<dynamic>(
        '/soso/fcgi-bin/client_search_cp',
        queryParameters: {
          'w': keyword,
          'format': 'json',
          'n': 5,
          'p': 1,
          'cr': 1,
          'new_json': 1,
          'platform': 'yqq.json',
          'inCharset': 'utf8',
          'outCharset': 'utf-8',
          't': 0,
        },
        options: lyricsRequestOptions(),
      );
      final songs = _songs(
        lyricsJsonBody(found.data),
        title: title,
        artist: artist ?? '',
        duration: query.duration.inSeconds,
      );
      final candidates = await _lyrics(songs);
      _log(keyword, candidates);
      return candidates;
    } on DioException catch (e) {
      AppLogger.w('qq "$keyword" failed: ${e.type}', tag: 'lyrics');
      throwIfLyricsTransport(e, 'qq');
      return const [];
    } catch (e) {
      if (e is LyricsSourceUnavailable) rethrow;
      AppLogger.w('qq "$keyword" failed: $e', tag: 'lyrics');
      return const [];
    }
  }

  Future<List<LyricsCandidate>> _lyrics(List<_QqSong> songs) async {
    final candidates = <LyricsCandidate>[];
    for (final song in songs.take(3)) {
      final lyric = await _dio.get<dynamic>(
        '/lyric/fcgi-bin/fcg_query_lyric_new.fcg',
        queryParameters: {
          'songmid': song.mid,
          'format': 'json',
          'nobase64': 1,
          'g_tk': 5381,
        },
        options: lyricsRequestOptions(),
      );
      final body = lyricsJsonBody(lyric.data);
      final raw = body?['lyric'];
      final text = syncedLrcText(raw is String ? raw : null);
      if (text == null) continue;
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
      if (song.score >= _scorer.autoThreshold) break;
    }
    return candidates;
  }

  List<_QqSong> _songs(
    Map<String, dynamic>? body, {
    required String title,
    required String artist,
    required int duration,
  }) {
    final data = body?['data'];
    final song = data is Map ? data['song'] : null;
    final list = song is Map ? song['list'] : null;
    if (list is! List || list.isEmpty) return const [];
    final ranked = <_QqSong>[];
    for (final item in list) {
      if (item is! Map) continue;
      final mid = item['mid'] ?? item['songmid'];
      final name = item['name'] ?? item['songname'] ?? item['title'];
      if (mid is! String || mid.isEmpty || name is! String || name.isEmpty) {
        continue;
      }
      final names = _singerNames(item['singer']);
      final interval = item['interval'];
      final seconds = interval is num ? interval.round() : 0;
      final score = _scorer.pick(
        trackTitle: title,
        trackArtist: artist,
        trackDuration: duration,
        lyricsTitle: name,
        lyricsArtist: names,
        lyricsDuration: seconds,
      );
      if (score == null) continue;
      ranked.add(_QqSong(mid, name, names, score));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  String _singerNames(Object? singers) {
    if (singers is! List) return '';
    final names = <String>[];
    for (final singer in singers) {
      if (singer is! Map) continue;
      final name = singer['name'];
      if (name is String && name.trim().isNotEmpty) names.add(name.trim());
    }
    return names.join(' & ');
  }

  void _log(String keyword, List<LyricsCandidate> candidates) {
    if (candidates.isEmpty) {
      AppLogger.d('qq "$keyword" hits=0', tag: 'lyrics');
      return;
    }
    AppLogger.d(
      'qq "$keyword" hits=${candidates.length} '
      'best=${candidates.first.originalTitle}',
      tag: 'lyrics',
    );
  }
}

class _QqSong {
  const _QqSong(this.mid, this.name, this.artist, this.score);

  final String mid;
  final String name;
  final String artist;
  final double score;
}
