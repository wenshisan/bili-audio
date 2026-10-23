import 'package:dio/dio.dart';

import '../../core/network/bili_http.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_error.dart';
import 'models/search_result.dart';

/// 音乐区热门榜。发现页在用户还没搜索时用它做推荐。
abstract interface class MusicChartSource {
  /// 音乐区排行榜。顺序是榜单名次，反映近期播放热度，不是累计播放量。
  Future<Result<List<SearchResult>>> dailyMusic();
}

/// B 站音乐区排行 (rid=1003)。
///
/// 分区 tid `3` 是搜索用的音乐区，排行榜 v2 的音乐 rid 是 `1003`。
/// 榜单按近期数据动态更新，用来代表当日播放热度高的音乐。
class BiliRankingApi implements MusicChartSource {
  BiliRankingApi(this._http);

  final BiliHttp _http;

  /// 排行榜 v2 里的音乐分区，不是搜索接口的 tid=3。
  static const musicRid = 1003;

  @override
  Future<Result<List<SearchResult>>> dailyMusic() async {
    try {
      final response = await _http.dio.get<Map<String, dynamic>>(
        '/x/web-interface/ranking/v2',
        queryParameters: {'rid': musicRid, 'type': 'all'},
      );
      final data = response.data?['data'];
      if (data is! Map) {
        return const Result.failure(
          AppError.unknown(message: 'Ranking data missing'),
        );
      }
      final raw = data['list'];
      final items = <SearchResult>[];
      if (raw is List) {
        for (final entry in raw) {
          if (entry is! Map) continue;
          final item = _parse(Map<String, dynamic>.from(entry));
          if (item != null) items.add(item);
        }
      }
      return Result.success(items);
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppError) return Result.failure(error);
      return Result.failure(
        AppError.network(message: 'Ranking failed', cause: e),
      );
    } catch (e, st) {
      return Result.failure(
        AppError.unknown(
          message: 'Ranking error: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  SearchResult? _parse(Map<String, dynamic> item) {
    final bvid = item['bvid'] as String?;
    final title = item['title'] as String?;
    final duration = _positive(item['duration']);
    if (bvid == null || bvid.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    if (duration == null) return null;

    final owner = item['owner'];
    final author = owner is Map ? owner['name'] as String? ?? '' : '';
    final stat = item['stat'];
    final play = stat is Map ? _nonNegative(stat['view']) ?? 0 : 0;
    final pages = _positive(item['videos']) ?? 1;

    return SearchResult(
      bvid: bvid,
      title: title,
      cleanTitle: title,
      duration: duration,
      cover: _cover(item['pic'] as String?),
      author: author,
      play: play,
      description: item['desc'] as String?,
      filtered: duration > 900,
      cid: _positive(item['cid']),
      pageIndex: 1,
      totalPages: pages,
    );
  }

  /// 排行榜封面常是 `http://` 或协议相对地址，统一成 https。
  String _cover(String? pic) {
    final raw = pic?.trim() ?? '';
    if (raw.startsWith('//')) return 'https:$raw';
    if (raw.startsWith('http://')) return 'https://${raw.substring(7)}';
    return raw;
  }

  int? _positive(Object? value) {
    final n = _nonNegative(value);
    if (n == null || n <= 0) return null;
    return n;
  }

  int? _nonNegative(Object? value) {
    if (value is int) return value < 0 ? null : value;
    if (value is num) return value < 0 ? null : value.toInt();
    return null;
  }
}
