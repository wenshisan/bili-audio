import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/album/album_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';
import 'album_http.dart';
import 'album_text.dart';

/// QQ 音乐专辑图、发行年份和专辑介绍。
class QqAlbumProvider implements AlbumProvider {
  QqAlbumProvider({Dio? dio, LyricsScorer? scorer})
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
  int get priority => 5;

  @override
  Future<List<AlbumCandidate>> search(AlbumQuery query) async {
    final terms = albumTerms(query);
    try {
      final found = await _dio.get<dynamic>(
        '/soso/fcgi-bin/client_search_cp',
        queryParameters: {
          'w': terms.keyword,
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
        _body(found.data),
        title: terms.title,
        artist: terms.artist,
        duration: query.duration.inSeconds,
      );
      if (songs.isEmpty) {
        AppLogger.d('qq album "${terms.keyword}" hits=0', tag: 'album');
        return const [];
      }
      final song = songs.first;
      var detail = const _QqAlbum();
      final mid = song.albumMid;
      if (mid != null && mid.isNotEmpty) {
        try {
          final album = await _dio.get<dynamic>(
            '/v8/fcg-bin/fcg_v8_album_info_cp.fcg',
            queryParameters: {'albummid': mid, 'format': 'json'},
            options: lyricsRequestOptions(),
          );
          detail = _album(_body(album.data));
        } on DioException catch (e) {
          AppLogger.w('qq album $mid failed: ${e.type}', tag: 'album');
          throwIfAlbumTransport(e, 'qq');
        }
      }
      final cover = httpsCover(detail.coverUrl) ?? _cover(mid);
      final year = detail.year ?? song.year;
      final description = plainText(detail.description);
      final albumName = _name(detail.name) ?? _name(song.albumName);
      if (cover == null && year == null && description == null) {
        return const [];
      }
      AppLogger.d(
        'qq album "${terms.keyword}" -> ${albumName ?? ''} year=$year',
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
        'qq album "${terms.keyword}" failed: ${e.type}',
        tag: 'album',
      );
      throwIfAlbumTransport(e, 'qq');
      return const [];
    } catch (e) {
      if (e is AlbumSourceUnavailable) rethrow;
      AppLogger.w('qq album "${terms.keyword}" failed: $e', tag: 'album');
      return const [];
    }
  }

  Map<String, dynamic>? _body(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is! String) return null;
    final start = data.indexOf('{');
    final end = data.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(data.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
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
      final name = item['name'] ?? item['songname'] ?? item['title'];
      if (name is! String || name.isEmpty) continue;
      final singers = item['singer'];
      final names = singers is List
          ? singers
                .whereType<Map<dynamic, dynamic>>()
                .map((singer) => '${singer['name'] ?? ''}')
                .where((name) => name.isNotEmpty)
                .join(' & ')
          : '';
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
      final album = item['album'];
      final albumMap = album is Map ? album : null;
      final mid = albumMap?['mid'] ?? item['albummid'];
      final albumName =
          albumMap?['name'] ?? albumMap?['title'] ?? item['albumname'];
      final published = item['time_public'] ?? item['pubtime'];
      ranked.add(
        _QqSong(
          name: name,
          artist: names,
          durationSeconds: seconds,
          score: score,
          albumMid: mid is String ? mid : null,
          albumName: albumName is String ? albumName : null,
          year: yearFromDate(published is String ? published : null),
        ),
      );
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  _QqAlbum _album(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map) return const _QqAlbum();
    final desc = data['desc'];
    final date = data['aDate'];
    final mid = data['mid'];
    return _QqAlbum(
      name: data['name'] as String?,
      description: desc is String ? desc : null,
      year: yearFromDate(date is String ? date : null),
      coverUrl: mid is String ? _cover(mid) : null,
    );
  }

  String? _cover(String? mid) {
    final id = mid?.trim();
    if (id == null || id.isEmpty) return null;
    return 'https://y.gtimg.cn/music/photo_new/T002R800x800M000$id.jpg';
  }

  String? _name(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class _QqSong {
  const _QqSong({
    required this.name,
    required this.artist,
    required this.durationSeconds,
    required this.score,
    this.albumMid,
    this.albumName,
    this.year,
  });

  final String name;
  final String artist;
  final int durationSeconds;
  final double score;
  final String? albumMid;
  final String? albumName;
  final int? year;
}

class _QqAlbum {
  const _QqAlbum({this.name, this.description, this.year, this.coverUrl});

  final String? name;
  final String? description;
  final int? year;
  final String? coverUrl;
}
