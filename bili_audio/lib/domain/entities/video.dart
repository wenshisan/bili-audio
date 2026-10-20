import 'package:freezed_annotation/freezed_annotation.dart';

part 'video.freezed.dart';
part 'video.g.dart';

/// 视频分P (M1.1)
@freezed
sealed class VideoPage with _$VideoPage {
  const factory VideoPage({
    /// 分P标识
    required int cid,

    /// 分P标题
    required String title,

    /// 时长
    required Duration duration,

    /// 分P序号 (1-based)
    required int pageIndex,
  }) = _VideoPage;

  factory VideoPage.fromJson(Map<String, dynamic> json) =>
      _$VideoPageFromJson(json);
}

/// 视频信息 (M1.1)
///
/// B 站视频元信息，包含所有分P列表。
@freezed
sealed class Video with _$Video {
  const factory Video({
    /// B 站 BV 号
    required String bvid,

    /// 视频标题
    required String title,

    /// UP 主名称
    required String uploader,

    /// UP 主 mid
    required int uploaderMid,

    /// 封面 URL
    required String cover,

    /// 分P列表
    required List<VideoPage> pages,

    /// 标签
    @Default([]) List<String> tags,

    /// 播放量
    int? viewCount,

    /// 发布时间 (Unix timestamp)
    int? publishTime,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}
