import 'package:dio/dio.dart';

import '../../core/network/bili_http.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_error.dart';
import 'models/search_result.dart';

/// 音乐区热门榜。发现页在用户还没搜索时用它做推荐。
abstract interface class MusicChartSource {
  /// 音乐区排行，并拆成热度、评价和子分区。
  Future<Result<MusicChartBundle>> dailyMusic();
}

/// 排行榜 v2 里适合当歌曲听的音乐子分区。
///
/// `tidv2` 见分区一览。乐评、教学、歌单和饭拍不单列。
enum MusicZone {
  original(2016),
  cover(2020),
  mv(2017),
  live(2018),
  perform(2021),
  vocaloid(2022),
  ai(2023);

  const MusicZone(this.tid);

  final int tid;

  static MusicZone? fromTid(int? tid) {
    if (tid == null) return null;
    for (final zone in values) {
      if (zone.tid == tid) return zone;
    }
    return null;
  }
}

/// 同一份音乐区排行拆出的推荐列表，顺序即展示顺序。
class MusicChartBundle {
  const MusicChartBundle({
    required this.heat,
    required this.rating,
    this.zones = const {},
  });

  /// 榜单原顺序。父分区不是音乐时，仍按子分区归入分类。
  final List<SearchResult> heat;

  /// 播放量达到门槛后，按投币、收藏、点赞相对播放量从高到低。
  final List<SearchResult> rating;

  /// [heat] 按子分区拆开，每个列表仍是榜单顺序。
  final Map<MusicZone, List<SearchResult>> zones;
}

/// B 站音乐区排行 (rid=1003)。
///
/// 分区 tid `3` 是搜索用的音乐区，排行榜 v2 的音乐 rid 是 `1003`。
/// 榜单按近期数据动态更新，用来代表当日播放热度高的音乐。
class BiliRankingApi implements MusicChartSource {
  BiliRankingApi(this._http);

  final BiliHttp _http;

  /// 排行榜 v2 里的音乐分区，也是稿件 `pid_v2`。不是搜索接口的 tid=3。
  static const musicRid = 1003;

  /// 评价榜忽略播放量过低的稿件，避免少量互动把比例抬上去。
  static const minRatingViews = 10000;

  @override
  Future<Result<MusicChartBundle>> dailyMusic() async {
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
      final entries = <_Ranked>[];
      if (raw is List) {
        for (final entry in raw) {
          if (entry is! Map) continue;
          final item = _parse(Map<String, dynamic>.from(entry));
          if (item != null) entries.add(item);
        }
      }
      return Result.success(_bundle(entries));
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

  MusicChartBundle _bundle(List<_Ranked> entries) {
    final rated = [
      for (final entry in entries)
        if (entry.rating >= 0) entry,
    ]..sort((a, b) => b.rating.compareTo(a.rating));
    final zones = <MusicZone, List<SearchResult>>{
      for (final zone in MusicZone.values) zone: [],
    };
    for (final entry in entries) {
      final zone = MusicZone.fromTid(entry.zoneTid);
      if (zone == null) continue;
      zones[zone]?.add(entry.result);
    }
    return MusicChartBundle(
      heat: [for (final entry in entries) entry.result],
      rating: [for (final entry in rated) entry.result],
      zones: zones,
    );
  }

  _Ranked? _parse(Map<String, dynamic> item) {
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
    final like = stat is Map ? _nonNegative(stat['like']) ?? 0 : 0;
    final coin = stat is Map ? _nonNegative(stat['coin']) ?? 0 : 0;
    final favorite = stat is Map ? _nonNegative(stat['favorite']) ?? 0 : 0;
    final pages = _positive(item['videos']) ?? 1;

    return _Ranked(
      zoneTid: _positive(item['tidv2']),
      result: SearchResult(
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
      ),
      view: play,
      like: like,
      coin: coin,
      favorite: favorite,
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

class _Ranked {
  _Ranked({
    required this.result,
    required this.view,
    required this.like,
    required this.coin,
    required this.favorite,
    this.zoneTid,
  });

  final SearchResult result;
  final int? zoneTid;
  final int view;
  final int like;
  final int coin;
  final int favorite;

  /// 不足门槛或不是单曲时长时返回 -1，不进入评价榜。
  double get rating {
    if (view < BiliRankingApi.minRatingViews) return -1;
    if (result.duration < 60 || result.duration > 900) return -1;
    return (like + coin * 4 + favorite * 2) / view;
  }
}
