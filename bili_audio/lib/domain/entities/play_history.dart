import 'package:freezed_annotation/freezed_annotation.dart';

part 'play_history.freezed.dart';
part 'play_history.g.dart';

/// 播放历史记录 (M1.1)
///
/// 每次播放达到一定阈值 (如播放时长超过30s或进度>50%) 后记录一条。
/// 用于 "最近播放" 歌单和统计分析 (v0.2.4)。
@freezed
sealed class PlayHistory with _$PlayHistory {
  const factory PlayHistory({
    /// 自增主键 (数据库生成)
    int? id,

    /// B 站 BV 号
    required String bvid,

    /// 分P标识
    required int cid,

    /// 播放时间 (Unix timestamp)
    required int playedAt,

    /// 播放进度 (毫秒)
    @Default(0) int positionMs,

    /// 完成度 (0-1)
    @Default(0.0) double completion,
  }) = _PlayHistory;

  factory PlayHistory.fromJson(Map<String, dynamic> json) =>
      _$PlayHistoryFromJson(json);
}
