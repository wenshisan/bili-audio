import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result.freezed.dart';
part 'search_result.g.dart';

/// 搜索结果 (M2.2)
@freezed
sealed class SearchResult with _$SearchResult {
  const factory SearchResult({
    required String bvid,
    required String title, // 原始标题 (含 <em> 标签)
    required String cleanTitle, // 去除 HTML 标签后
    required int duration, // 秒
    required String cover,
    required String author,
    required int play,
    String? description,
    bool? filtered, // 超过 15min 标记为 true
    /// 分P的 cid。展开后点击只播放这一 P
    int? cid,

    /// 分P序号 (1-based)
    int? pageIndex,

    /// 分P总数，含未展示的超长分P
    int? totalPages,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);
}

/// 搜索分页器 (M2.2)
@freezed
sealed class SearchPage with _$SearchPage {
  const factory SearchPage({
    required List<SearchResult> items,
    required int page,
    required int pageSize,
    required int total,
    required bool hasMore,
  }) = _SearchPage;
}
