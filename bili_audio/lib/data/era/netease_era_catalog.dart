import 'dart:convert';
import 'dart:math' show min;

import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_error.dart';
import '../repositories/bili_repositories.dart';
import '../repositories/repositories.dart';
import 'era_catalog.dart';
import 'era_titles.dart';

/// 用网易云歌单提供某一年代的歌曲名和歌手。
///
/// 只收歌单标题能确定属于这一年代的歌单，官方歌单优先。
class NeteaseEraCatalog implements EraCatalog {
  NeteaseEraCatalog({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://music.163.com',
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 8),
              headers: const {
                'Referer': 'https://music.163.com',
                'User-Agent': 'Mozilla/5.0',
              },
            ),
          );

  final Dio _dio;
  final _cache = <DiscoverTab, List<EraTrack>>{};

  static const pageSize = 12;

  /// 未登录时歌单详情只内嵌前 10 首，其余用曲目 id 再取，这里是上限。
  static const playlistLimit = 200;

  @override
  Future<Result<EraCatalogPage>> page(DiscoverTab tab, {int page = 1}) async {
    try {
      final tracks = await _tracksFor(tab);
      if (tracks == null) {
        return const Result.failure(
          AppError.unknown(message: 'era playlist missing'),
        );
      }
      final start = (page - 1) * pageSize;
      if (start >= tracks.length || start < 0) {
        return Result.success((
          tracks: const [],
          page: page,
          total: tracks.length,
          hasMore: false,
        ));
      }
      final end = min(start + pageSize, tracks.length);
      return Result.success((
        tracks: tracks.sublist(start, end),
        page: page,
        total: tracks.length,
        hasMore: end < tracks.length,
      ));
    } on DioException catch (e) {
      AppLogger.w(
        'era catalog $tab failed: ${e.type} ${e.message ?? e.error}',
        tag: 'search',
      );
      return Result.failure(
        AppError.network(message: 'era catalog failed', cause: e),
      );
    } on FormatException catch (e) {
      AppLogger.w('era catalog $tab bad json: $e', tag: 'search');
      return const Result.failure(
        AppError.unknown(message: 'era catalog bad json'),
      );
    }
  }

  Future<List<EraTrack>?> _tracksFor(DiscoverTab tab) async {
    final cached = _cache[tab];
    if (cached != null) return cached;
    final keyword = BiliSearchRepository.eraKeyword[tab];
    if (keyword == null) return null;
    final found = await _get('/api/search/get/web', {
      's': keyword,
      'type': 1000,
      'offset': 0,
      'limit': 20,
    });
    final picked = _pickPlaylist(found, tab);
    if (picked == null) {
      AppLogger.w('era catalog no playlist for $tab "$keyword"', tag: 'search');
      return null;
    }
    final detail = await _get('/api/v6/playlist/detail', {
      'id': picked.id,
      'n': playlistLimit,
    });
    final embedded = _readTracks(detail);
    final ids = _trackIds(detail).take(playlistLimit).toList();
    final tracks = await _songs(ids, fallback: embedded);
    _cache[tab] = tracks;
    AppLogger.i(
      'era catalog $tab playlist=${picked.id} "${picked.name}" '
      'songs=${tracks.length}/${ids.length}',
      tag: 'search',
    );
    return tracks;
  }

  /// 网易云经常用 text/plain 返回 JSON，按 Map 接收会直接抛类型错误。
  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, dynamic> query,
  ) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: query,
      options: Options(responseType: ResponseType.plain),
    );
    return _asJsonMap(response.data);
  }

  Future<List<EraTrack>> _songs(
    List<int> ids, {
    required List<EraTrack> fallback,
  }) async {
    if (ids.length <= fallback.length) return fallback;
    try {
      final byId = <int, EraTrack>{};
      const batch = 100;
      for (var start = 0; start < ids.length; start += batch) {
        final slice = ids.sublist(start, min(start + batch, ids.length));
        final response = await _dio.post<dynamic>(
          '/api/v3/song/detail',
          data: {
            'c': jsonEncode([
              for (final id in slice) {'id': id},
            ]),
          },
          options: Options(
            responseType: ResponseType.plain,
            contentType: Headers.formUrlEncodedContentType,
          ),
        );
        final songs = _asJsonMap(response.data)?['songs'];
        if (songs is! List) continue;
        for (final raw in songs) {
          if (raw is! Map) continue;
          final id = raw['id'];
          final track = _trackFrom(raw);
          if (id is num && track != null) byId[id.toInt()] = track;
        }
      }
      final ordered = [
        for (final id in ids)
          if (byId[id] != null) byId[id]!,
      ];
      return ordered.isEmpty ? fallback : ordered;
    } on DioException catch (e) {
      AppLogger.w('era catalog songs failed: ${e.type}', tag: 'search');
      return fallback;
    }
  }
}

Map<String, dynamic>? _asJsonMap(Object? body) {
  if (body is Map<String, dynamic>) return body;
  if (body is Map) return Map<String, dynamic>.from(body);
  if (body is! String || body.isEmpty) return null;
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  if (decoded is String) return _asJsonMap(decoded);
  return null;
}

class _PlaylistPick {
  const _PlaylistPick(this.id, this.name);

  final int id;
  final String name;
}

_PlaylistPick? _pickPlaylist(Map<String, dynamic>? body, DiscoverTab tab) {
  final result = body?['result'];
  final playlists = result is Map ? result['playlists'] : null;
  if (playlists is! List) return null;
  _PlaylistPick? best;
  var bestScore = -1;
  for (final raw in playlists) {
    if (raw is! Map) continue;
    final name = raw['name'];
    final id = raw['id'];
    if (name is! String || id is! num) continue;
    final mentioned = erasMentionedInTitle(name);
    if (mentioned.length != 1 || !mentioned.contains(tab)) continue;
    final plays = raw['playCount'];
    final playCount = plays is num ? plays.toInt() : 0;
    final official = raw['playlistType'] == 'PGC';
    final score = (official ? 1000000000000 : 0) + playCount;
    if (score <= bestScore) continue;
    bestScore = score;
    best = _PlaylistPick(id.toInt(), name);
  }
  return best;
}

List<int> _trackIds(Map<String, dynamic>? body) {
  final playlist = body?['playlist'];
  final ids = playlist is Map ? playlist['trackIds'] : null;
  if (ids is! List) return const [];
  return [
    for (final raw in ids)
      if (raw is num)
        raw.toInt()
      else if (raw is Map && raw['id'] is num)
        (raw['id'] as num).toInt(),
  ];
}

List<EraTrack> _readTracks(Map<String, dynamic>? body) {
  final playlist = body?['playlist'];
  final tracks = playlist is Map ? playlist['tracks'] : null;
  if (tracks is! List) return const [];
  final out = <EraTrack>[];
  for (final raw in tracks) {
    if (raw is! Map) continue;
    final track = _trackFrom(raw);
    if (track != null) out.add(track);
  }
  return out;
}

EraTrack? _trackFrom(Map<dynamic, dynamic> raw) {
  final name = raw['name'];
  if (name is! String || name.trim().isEmpty) return null;
  final seconds = switch (raw['dt']) {
    final num ms => (ms / 1000).round(),
    _ => 0,
  };
  if (seconds < 60 || seconds > 900) return null;
  final artists = raw['ar'];
  final artist = artists is List
      ? artists
            .whereType<Map>()
            .map((item) => '${item['name'] ?? ''}'.trim())
            .where((item) => item.isNotEmpty)
            .firstOrNull
      : null;
  return EraTrack(
    name: name.trim(),
    artist: artist ?? '',
    duration: Duration(seconds: seconds),
  );
}
