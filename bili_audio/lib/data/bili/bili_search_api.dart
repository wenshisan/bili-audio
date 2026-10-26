import 'package:dio/dio.dart';

import '../../core/network/bili_http.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_error.dart';
import 'models/search_result.dart';

/// Bilibili 搜索 API (M2.2)
class BiliSearchApi {
  BiliSearchApi(this._http);

  final BiliHttp _http;

  /// 搜索视频
  ///
  /// [keyword] 关键词
  /// [page] 页码 (从 1 开始)
  /// [pageSize] 每页数量
  /// [tids] 分区 ID (默认 3=音乐主分区)
  ///
  /// [order] 为 `click` 时按播放量。 [duration] 为 1 时只要 10 分钟以内。
  Future<Result<SearchPage>> searchVideo({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    List<int> tids = const [3],
    String? order,
    int? duration,
  }) async {
    try {
      final response = await _http.dio.get<Map<String, dynamic>>(
        '/x/web-interface/wbi/search/type',
        queryParameters: {
          'search_type': 'video',
          'keyword': keyword,
          'page': page,
          'page_size': pageSize,
          if (tids.isNotEmpty) 'tids': tids.join(','),
          'order': ?order,
          'duration': ?duration,
        },
        options: Options(
          extra: {'wbi': true, 'risk_guarded': true, 'risk_retry': true},
        ),
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      final items =
          (data['result'] as List<dynamic>?)
              ?.map((item) => _parseSearchItem(item as Map<String, dynamic>))
              .where((item) => item != null)
              .cast<SearchResult>()
              .toList() ??
          [];

      final numResults = data['numResults'] as int? ?? 0;
      final numPages = data['numPages'] as int? ?? 1;

      return Result.success(
        SearchPage(
          items: items,
          page: page,
          pageSize: pageSize,
          total: numResults,
          hasMore: page < numPages,
        ),
      );
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppError) {
        return Result.failure(error);
      }
      return Result.failure(
        AppError.network(message: 'Search failed', cause: e),
      );
    } catch (e, st) {
      return Result.failure(
        AppError.unknown(message: 'Search error: $e', cause: e, stackTrace: st),
      );
    }
  }

  SearchResult? _parseSearchItem(Map<String, dynamic> item) {
    try {
      final bvid = item['bvid'] as String?;
      final title = item['title'] as String?;
      if (bvid == null || title == null) return null;

      final duration = _parseDuration(item['duration'] as String?);
      if (duration == null) return null;

      final cleanTitle = _cleanHtml(title);
      final filtered = duration > 900; // 15 分钟

      return SearchResult(
        bvid: bvid,
        title: title,
        cleanTitle: cleanTitle,
        duration: duration,
        cover: item['pic'] as String? ?? '',
        author: item['author'] as String? ?? '',
        play: item['play'] as int? ?? 0,
        description: item['description'] as String?,
        filtered: filtered,
      );
    } catch (_) {
      return null;
    }
  }

  /// 解析时长字符串 "m:ss" 或 "h:mm:ss"
  int? _parseDuration(String? durationStr) {
    if (durationStr == null) return null;
    final parts = durationStr.split(':').reversed.toList();
    var seconds = 0;
    for (var i = 0; i < parts.length; i++) {
      final value = int.tryParse(parts[i]);
      if (value == null) return null;
      seconds +=
          value *
          (i == 0
              ? 1
              : i == 1
              ? 60
              : 3600);
    }
    return seconds;
  }

  /// 去除 HTML 标签并反转义实体
  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<em[^>]*>'), '')
        .replaceAll('</em>', '')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }
}
