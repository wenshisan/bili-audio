import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/lyrics/lrc_parser.dart';
import '../../domain/lyrics/lyrics_provider.dart';
import 'lyrics_http.dart';

/// 当前视频的 B 站 CC 字幕，转成 LRC。
///
/// 字幕属于正在播放的这一 P，命中后直接采用。
class BiliSubtitleProvider implements LyricsProvider {
  BiliSubtitleProvider({required this._api, Dio? files})
    : _files = files ?? lyricsClient('');

  final Dio _api;
  final Dio _files;

  @override
  String get name => 'bilibili_cc';

  @override
  int get priority => 5;

  @override
  Future<List<LyricsCandidate>> search(LyricsQuery query) async {
    try {
      final listed = await _api.get<Map<String, dynamic>>(
        '/x/player/wbi/v2',
        queryParameters: {'bvid': query.bvid, 'cid': query.cid},
        options: lyricsRequestOptions(
          extra: const {
            'wbi': true,
            'retry_attempt': 99,
            'skip_rate_limit': true,
          },
        ),
      );
      final url = _subtitleUrl(listed.data);
      if (url == null) {
        AppLogger.d(
          'bilibili_cc ${query.bvid} cid=${query.cid} none',
          tag: 'lyrics',
        );
        return const [];
      }
      final file = await _files.get<Map<String, dynamic>>(
        url,
        options: lyricsRequestOptions(),
      );
      final lrc = _toLrc(file.data);
      if (lrc == null) return const [];
      final lyrics = LrcParser.parse(lrc);
      if (lyrics.lines.length < 2) return const [];
      AppLogger.d(
        'bilibili_cc ${query.bvid} cid=${query.cid} lines=${lyrics.lines.length}',
        tag: 'lyrics',
      );
      return [
        LyricsCandidate(
          lyrics: lyrics.copyWith(source: name, matchScore: 0.95),
          source: name,
          matchScore: 0.95,
          originalTitle: query.title,
          originalArtist: query.artist,
          lrcText: lrc,
        ),
      ];
    } on DioException catch (e) {
      AppLogger.w('bilibili_cc ${query.bvid} failed: ${e.type}', tag: 'lyrics');
      throwIfLyricsTransport(e, 'bilibili_cc');
      return const [];
    } catch (e) {
      if (e is LyricsSourceUnavailable) rethrow;
      AppLogger.w('bilibili_cc ${query.bvid} failed: $e', tag: 'lyrics');
      return const [];
    }
  }

  String? _subtitleUrl(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map<dynamic, dynamic>) return null;
    final subtitle = data['subtitle'];
    if (subtitle is! Map<dynamic, dynamic>) return null;
    final list = subtitle['subtitles'];
    if (list is! List || list.isEmpty) return null;

    Map<dynamic, dynamic>? chosen;
    for (final item in list) {
      if (item is! Map<dynamic, dynamic>) continue;
      final url = item['subtitle_url'];
      if (url is! String || url.isEmpty) continue;
      final lan = '${item['lan'] ?? ''}';
      if (lan.startsWith('zh') || lan.startsWith('ai-zh')) {
        chosen = item;
        break;
      }
      chosen ??= item;
    }
    final raw = chosen?['subtitle_url'];
    if (raw is! String || raw.isEmpty) return null;
    if (raw.startsWith('//')) return 'https:$raw';
    return raw;
  }

  String? _toLrc(Map<String, dynamic>? body) {
    final lines = body?['body'];
    if (lines is! List || lines.isEmpty) return null;
    final buffer = StringBuffer();
    for (final item in lines) {
      if (item is! Map<dynamic, dynamic>) continue;
      final text = '${item['content'] ?? ''}'.trim();
      final from = item['from'];
      if (text.isEmpty || from is! num) continue;
      buffer.writeln('${_stamp(from.toDouble())}$text');
    }
    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _stamp(double seconds) {
    final ms = (seconds * 1000).round();
    final minute = ms ~/ 60000;
    final second = (ms % 60000) ~/ 1000;
    final centi = (ms % 1000) ~/ 10;
    String two(int value) => value.toString().padLeft(2, '0');
    return '[${two(minute)}:${two(second)}.${two(centi)}]';
  }
}
