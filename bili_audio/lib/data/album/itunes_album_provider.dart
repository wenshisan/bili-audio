import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/album/album_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';
import 'album_http.dart';
import 'album_text.dart';

/// iTunes 搜索里的专辑图和发行年份。这个源没有专辑介绍。
class ItunesAlbumProvider implements AlbumProvider {
  ItunesAlbumProvider({Dio? dio, LyricsScorer? scorer})
    : _dio =
          dio ??
          lyricsClient(
            'https://itunes.apple.com',
            headers: const {'User-Agent': 'Mozilla/5.0'},
          ),
      _scorer = scorer ?? LyricsScorer();

  final Dio _dio;
  final LyricsScorer _scorer;

  @override
  String get name => 'itunes';

  @override
  int get priority => 8;

  @override
  Future<List<AlbumCandidate>> search(AlbumQuery query) async {
    final terms = albumTerms(query);
    try {
      final cn = await _collect(query, terms, 'CN');
      if (cn.any((c) => c.matchScore >= 0.8)) return _sorted(cn);
      try {
        final us = await _collect(query, terms, 'US');
        return _sorted(_merge(cn, us));
      } on AlbumSourceUnavailable {
        if (cn.isEmpty) rethrow;
        return _sorted(cn);
      }
    } on DioException catch (e) {
      AppLogger.w(
        'itunes album "${terms.keyword}" failed: ${e.type}',
        tag: 'album',
      );
      throwIfAlbumTransport(e, 'itunes');
      return const [];
    } catch (e) {
      if (e is AlbumSourceUnavailable) rethrow;
      AppLogger.w('itunes album "${terms.keyword}" failed: $e', tag: 'album');
      return const [];
    }
  }

  Future<List<AlbumCandidate>> _collect(
    AlbumQuery query,
    ({String title, String artist, String keyword}) terms,
    String country,
  ) async {
    final found = await _dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {
        'term': terms.keyword,
        'media': 'music',
        'entity': 'song',
        'limit': 5,
        'country': country,
      },
      options: lyricsRequestOptions(),
    );
    return _songs(
      found.data,
      title: terms.title,
      artist: terms.artist,
      duration: query.duration.inSeconds,
    );
  }

  List<AlbumCandidate> _songs(
    Map<String, dynamic>? body, {
    required String title,
    required String artist,
    required int duration,
  }) {
    final results = body?['results'];
    if (results is! List || results.isEmpty) return const [];
    final ranked = <AlbumCandidate>[];
    for (final item in results) {
      if (item is! Map) continue;
      final name = item['trackName'];
      if (name is! String || name.isEmpty) continue;
      final artistName = item['artistName'];
      final names = artistName is String ? artistName : '';
      final ms = item['trackTimeMillis'];
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
      final album = item['collectionName'];
      final albumName = album is String && album.trim().isNotEmpty
          ? album.trim()
          : null;
      final release = item['releaseDate'];
      final art = item['artworkUrl100'] ?? item['artworkUrl60'];
      final cover = _artwork(art is String ? art : null);
      final year = yearFromDate(release is String ? release : null);
      if (cover == null && year == null) continue;
      ranked.add(
        AlbumCandidate(
          source: this.name,
          matchScore: score,
          title: name,
          artist: names,
          durationSeconds: seconds,
          albumName: albumName,
          year: year,
          coverUrl: cover,
        ),
      );
    }
    return ranked;
  }

  String? _artwork(String? url) {
    final abs = httpsCover(url);
    if (abs == null) return null;
    return abs.replaceFirst(RegExp(r'\d+x\d+bb'), '600x600bb');
  }

  List<AlbumCandidate> _merge(
    List<AlbumCandidate> left,
    List<AlbumCandidate> right,
  ) {
    final all = [...left];
    for (final candidate in right) {
      final index = all.indexWhere(
        (e) =>
            e.title == candidate.title &&
            e.artist == candidate.artist &&
            e.albumName == candidate.albumName,
      );
      if (index < 0) {
        all.add(candidate);
      } else if (candidate.matchScore > all[index].matchScore) {
        all[index] = candidate;
      }
    }
    return all;
  }

  List<AlbumCandidate> _sorted(List<AlbumCandidate> raw) {
    final copy = [...raw]..sort((a, b) => b.matchScore.compareTo(a.matchScore));
    AppLogger.d(
      'itunes album hits=${copy.length} '
      'best=${copy.isEmpty ? '-' : copy.first.title}',
      tag: 'album',
    );
    return copy;
  }
}
