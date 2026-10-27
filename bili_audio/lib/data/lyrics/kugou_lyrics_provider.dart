import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/lyrics/lrc_parser.dart';
import '../../domain/lyrics/lyrics_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';
import '../../domain/title/title_cleaner.dart';
import 'lyrics_http.dart';

/// 酷狗歌词。
///
/// 先搜歌曲哈希，再按哈希拉同步歌词。排在 QQ 音乐后面、酷我前面。
class KugouLyricsProvider implements LyricsProvider {
  KugouLyricsProvider({Dio? search, Dio? lyrics, LyricsScorer? scorer})
    : _search =
          search ??
          lyricsClient(
            'https://mobileservice.kugou.com',
            headers: const {'User-Agent': 'Mozilla/5.0'},
          ),
      _lyrics =
          lyrics ??
          lyricsClient(
            'https://lyrics.kugou.com',
            headers: const {'User-Agent': 'Mozilla/5.0'},
          ),
      _scorer = scorer ?? LyricsScorer();

  final Dio _search;
  final Dio _lyrics;
  final LyricsScorer _scorer;

  @override
  String get name => 'kugou';

  @override
  int get priority => 7;

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
      final found = await _search.get<dynamic>(
        '/api/v3/search/song',
        queryParameters: {
          'format': 'json',
          'keyword': keyword,
          'page': 1,
          'pagesize': 5,
          'showtype': 1,
        },
        options: lyricsRequestOptions(),
      );
      final songs = _songs(
        lyricsJsonBody(found.data),
        title: title,
        artist: artist ?? '',
        duration: query.duration.inSeconds,
      );
      final candidates = await _collect(songs);
      _log(keyword, candidates);
      return candidates;
    } on DioException catch (e) {
      AppLogger.w('kugou "$keyword" failed: ${e.type}', tag: 'lyrics');
      throwIfLyricsTransport(e, 'kugou');
      return const [];
    } catch (e) {
      if (e is LyricsSourceUnavailable) rethrow;
      AppLogger.w('kugou "$keyword" failed: $e', tag: 'lyrics');
      return const [];
    }
  }

  Future<List<LyricsCandidate>> _collect(List<_KugouSong> songs) async {
    final candidates = <LyricsCandidate>[];
    for (final song in songs.take(3)) {
      final found = await _lyrics.get<dynamic>(
        '/search',
        queryParameters: {
          'ver': 1,
          'man': 'yes',
          'client': 'pc',
          'keyword': song.name,
          'duration': song.durationSeconds * 1000,
          'hash': song.hash,
        },
        options: lyricsRequestOptions(),
      );
      final text = await _download(lyricsJsonBody(found.data));
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

  Future<String?> _download(Map<String, dynamic>? body) async {
    final listed = body?['candidates'];
    if (listed is! List || listed.isEmpty) return null;
    final first = listed.first;
    if (first is! Map) return null;
    final id = _text(first['id']);
    final accessKey = _text(first['accesskey']);
    if (id == null || accessKey == null) return null;
    final file = await _lyrics.get<dynamic>(
      '/download',
      queryParameters: {
        'ver': 1,
        'client': 'pc',
        'id': id,
        'accesskey': accessKey,
        'fmt': 'lrc',
        'charset': 'utf8',
      },
      options: lyricsRequestOptions(),
    );
    final payload = lyricsJsonBody(file.data);
    final content = payload?['content'];
    return syncedLrcText(content is String ? content : null);
  }

  List<_KugouSong> _songs(
    Map<String, dynamic>? body, {
    required String title,
    required String artist,
    required int duration,
  }) {
    final data = body?['data'];
    final info = data is Map ? data['info'] : null;
    if (info is! List || info.isEmpty) return const [];
    final ranked = <_KugouSong>[];
    for (final item in info) {
      if (item is! Map) continue;
      final hash = _text(item['hash']);
      final name = _text(item['songname']);
      if (hash == null || name == null) continue;
      final names = _text(item['singername']) ?? '';
      final length = item['duration'];
      final seconds = length is num ? length.round() : 0;
      final score = _scorer.pick(
        trackTitle: title,
        trackArtist: artist,
        trackDuration: duration,
        lyricsTitle: name,
        lyricsArtist: names,
        lyricsDuration: seconds,
      );
      if (score == null) continue;
      ranked.add(_KugouSong(hash, name, names, seconds, score));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  String? _text(Object? value) {
    if (value is num) return value.toInt().toString();
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    return text;
  }

  void _log(String keyword, List<LyricsCandidate> candidates) {
    if (candidates.isEmpty) {
      AppLogger.d('kugou "$keyword" hits=0', tag: 'lyrics');
      return;
    }
    AppLogger.d(
      'kugou "$keyword" hits=${candidates.length} '
      'best=${candidates.first.originalTitle}',
      tag: 'lyrics',
    );
  }
}

class _KugouSong {
  const _KugouSong(
    this.hash,
    this.name,
    this.artist,
    this.durationSeconds,
    this.score,
  );

  final String hash;
  final String name;
  final String artist;
  final int durationSeconds;
  final double score;
}
