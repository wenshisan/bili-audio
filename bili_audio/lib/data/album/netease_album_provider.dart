import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/album/album_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';
import 'album_http.dart';
import 'album_text.dart';

/// 网易云专辑图、发行年份和专辑介绍。
class NeteaseAlbumProvider implements AlbumProvider {
  NeteaseAlbumProvider({Dio? dio, LyricsScorer? scorer})
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
  int get priority => 1;

  @override
  Future<List<AlbumCandidate>> search(AlbumQuery query) async {
    final terms = albumTerms(query);
    try {
      final found = await _dio.get<Map<String, dynamic>>(
        '/api/search/get/web',
        queryParameters: {
          's': terms.keyword,
          'type': 1,
          'offset': 0,
          'limit': 5,
        },
        options: lyricsRequestOptions(),
      );
      final songs = _songs(
        found.data,
        title: terms.title,
        artist: terms.artist,
        duration: query.duration.inSeconds,
      );
      if (songs.isEmpty) {
        AppLogger.d('netease album "${terms.keyword}" hits=0', tag: 'album');
        return const [];
      }
      final song = songs.first;
      var detail = const _NeteaseAlbum();
      if (song.albumId != null) {
        try {
          final album = await _dio.get<Map<String, dynamic>>(
            '/api/album/${song.albumId}',
            options: lyricsRequestOptions(),
          );
          detail = _album(album.data);
        } on DioException catch (e) {
          AppLogger.w(
            'netease album ${song.albumId} failed: ${e.type}',
            tag: 'album',
          );
          throwIfAlbumTransport(e, 'netease');
        }
      }
      final cover = httpsCover(detail.coverUrl) ?? httpsCover(song.coverUrl);
      final year = detail.year ?? song.year;
      final description = plainText(detail.description);
      final albumName = _name(detail.name) ?? _name(song.albumName);
      if (cover == null && year == null && description == null) {
        return const [];
      }
      AppLogger.d(
        'netease album "${terms.keyword}" -> ${albumName ?? ''} year=$year',
        tag: 'album',
      );
      return [
        AlbumCandidate(
          source: name,
          matchScore: song.score,
          title: song.name,
          artist: song.artist,
          durationSeconds: song.durationSeconds,
          albumName: albumName,
          year: year,
          coverUrl: cover,
          description: description,
        ),
      ];
    } on DioException catch (e) {
      AppLogger.w(
        'netease album "${terms.keyword}" failed: ${e.type}',
        tag: 'album',
      );
      throwIfAlbumTransport(e, 'netease');
      return const [];
    } catch (e) {
      if (e is AlbumSourceUnavailable) rethrow;
      AppLogger.w('netease album "${terms.keyword}" failed: $e', tag: 'album');
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
    final songs = result is Map ? result['songs'] : null;
    if (songs is! List || songs.isEmpty) return const [];
    final ranked = <_NeteaseSong>[];
    for (final item in songs) {
      if (item is! Map) continue;
      final name = item['name'];
      if (name is! String || name.isEmpty) continue;
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
      final album = item['album'];
      final albumMap = album is Map ? album : null;
      final albumId = albumMap?['id'];
      ranked.add(
        _NeteaseSong(
          name: name,
          artist: names,
          durationSeconds: seconds,
          score: score,
          albumId: albumId is num ? albumId.toInt() : null,
          albumName: albumMap?['name'] as String?,
          coverUrl: albumMap?['picUrl'] as String?,
          year: yearFromMillis(albumMap?['publishTime'] as num?),
        ),
      );
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  _NeteaseAlbum _album(Map<String, dynamic>? body) {
    final album = body?['album'];
    if (album is! Map) return const _NeteaseAlbum();
    final description = album['description'];
    final brief = album['briefDesc'];
    final text = description is String && description.trim().isNotEmpty
        ? description
        : (brief is String ? brief : null);
    final publish = album['publishTime'];
    return _NeteaseAlbum(
      name: album['name'] as String?,
      coverUrl: album['picUrl'] as String?,
      year: yearFromMillis(publish is num ? publish : null),
      description: text,
    );
  }

  String? _name(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class _NeteaseSong {
  const _NeteaseSong({
    required this.name,
    required this.artist,
    required this.durationSeconds,
    required this.score,
    this.albumId,
    this.albumName,
    this.coverUrl,
    this.year,
  });

  final String name;
  final String artist;
  final int durationSeconds;
  final double score;
  final int? albumId;
  final String? albumName;
  final String? coverUrl;
  final int? year;
}

class _NeteaseAlbum {
  const _NeteaseAlbum({this.name, this.coverUrl, this.year, this.description});

  final String? name;
  final String? coverUrl;
  final int? year;
  final String? description;
}
