import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/lyrics/lrc_parser.dart';
import '../../domain/lyrics/lyrics_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';
import '../../domain/title/title_cleaner.dart';
import 'lyrics_http.dart';

/// 酷我歌词。
///
/// 搜索曲目后把逐行时间轴收成 LRC。排在酷狗后面、LRCLIB 前面。
class KuwoLyricsProvider implements LyricsProvider {
  KuwoLyricsProvider({Dio? search, Dio? lyrics, LyricsScorer? scorer})
    : _search =
          search ??
          lyricsClient(
            'https://search.kuwo.cn',
            headers: const {
              'Referer': 'https://www.kuwo.cn/',
              'User-Agent': 'Mozilla/5.0',
            },
          ),
      _lyrics =
          lyrics ??
          lyricsClient(
            'https://m.kuwo.cn',
            headers: const {
              'Referer': 'https://m.kuwo.cn/',
              'User-Agent': 'Mozilla/5.0',
            },
          ),
      _scorer = scorer ?? LyricsScorer();

  final Dio _search;
  final Dio _lyrics;
  final LyricsScorer _scorer;

  @override
  String get name => 'kuwo';

  @override
  int get priority => 8;

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
        '/r.s',
        queryParameters: {
          'client': 'kt',
          'all': keyword,
          'pn': 0,
          'rn': 5,
          'uid': 0,
          'ver': 'kwplayer_ar_9.3.1.2',
          'vipver': 1,
          'ft': 'music',
          'cluster': 0,
          'strategy': 2012,
          'encoding': 'utf8',
          'rformat': 'json',
          'mobi': 1,
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
      AppLogger.w('kuwo "$keyword" failed: ${e.type}', tag: 'lyrics');
      throwIfLyricsTransport(e, 'kuwo');
      return const [];
    } catch (e) {
      if (e is LyricsSourceUnavailable) rethrow;
      AppLogger.w('kuwo "$keyword" failed: $e', tag: 'lyrics');
      return const [];
    }
  }

  Future<List<LyricsCandidate>> _collect(List<_KuwoSong> songs) async {
    final candidates = <LyricsCandidate>[];
    for (final song in songs.take(3)) {
      final lyric = await _lyrics.get<dynamic>(
        '/newh5/singles/songinfoandlrc',
        queryParameters: {'musicId': song.id},
        options: lyricsRequestOptions(),
      );
      final body = lyricsJsonBody(lyric.data);
      final data = body?['data'];
      final lines = data is Map ? data['lrclist'] : null;
      final text = _lrc(lines);
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

  String? _lrc(Object? raw) {
    if (raw is! List) return null;
    final buffer = StringBuffer();
    for (final item in raw) {
      if (item is! Map) continue;
      final line = item['lineLyric'];
      if (line is! String || line.trim().isEmpty) continue;
      final seconds = _seconds(item['time']);
      if (seconds == null || seconds < 0) continue;
      buffer.writeln('${_stamp(seconds)}${line.trim()}');
    }
    final text = buffer.toString().trim();
    if (!text.contains('[')) return null;
    return text;
  }

  List<_KuwoSong> _songs(
    Map<String, dynamic>? body, {
    required String title,
    required String artist,
    required int duration,
  }) {
    final list = body?['abslist'];
    if (list is! List || list.isEmpty) return const [];
    final ranked = <_KuwoSong>[];
    for (final item in list) {
      if (item is! Map) continue;
      final id = _musicId(item['MUSICRID']);
      final name = _text(item['SONGNAME']) ?? _text(item['NAME']);
      if (id == null || name == null) continue;
      final names = _text(item['ARTIST']) ?? '';
      final seconds = _wholeSeconds(item['DURATION']);
      final score = _scorer.pick(
        trackTitle: title,
        trackArtist: artist,
        trackDuration: duration,
        lyricsTitle: name,
        lyricsArtist: names,
        lyricsDuration: seconds,
      );
      if (score == null) continue;
      ranked.add(_KuwoSong(id, name, names, score));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  String? _musicId(Object? raw) {
    final text = _text(raw);
    if (text == null) return null;
    final id = text.replaceFirst(RegExp(r'^MUSIC_'), '');
    if (int.tryParse(id) == null) return null;
    return id;
  }

  String? _text(Object? value) {
    if (value is num) return value.toInt().toString();
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    return text;
  }

  int _wholeSeconds(Object? value) {
    final seconds = _seconds(value);
    if (seconds == null) return 0;
    return seconds.round();
  }

  double? _seconds(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  String _stamp(double seconds) {
    final total = (seconds * 100).round();
    final minutes = total ~/ 6000;
    final remain = total % 6000;
    final secs = remain ~/ 100;
    final centis = remain % 100;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    final ff = centis.toString().padLeft(2, '0');
    return '[$mm:$ss.$ff]';
  }

  void _log(String keyword, List<LyricsCandidate> candidates) {
    if (candidates.isEmpty) {
      AppLogger.d('kuwo "$keyword" hits=0', tag: 'lyrics');
      return;
    }
    AppLogger.d(
      'kuwo "$keyword" hits=${candidates.length} '
      'best=${candidates.first.originalTitle}',
      tag: 'lyrics',
    );
  }
}

class _KuwoSong {
  const _KuwoSong(this.id, this.name, this.artist, this.score);

  final String id;
  final String name;
  final String artist;
  final double score;
}
