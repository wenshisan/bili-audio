import 'package:freezed_annotation/freezed_annotation.dart';

part 'lyrics.freezed.dart';
part 'lyrics.g.dart';

/// 歌词行 (M1.1)
@freezed
sealed class LyricLine with _$LyricLine {
  const factory LyricLine({
    /// 时间戳
    required Duration timestamp,

    /// 歌词文本
    required String text,

    /// 翻译 (可选)
    String? translation,
  }) = _LyricLine;

  factory LyricLine.fromJson(Map<String, dynamic> json) =>
      _$LyricLineFromJson(json);
}

/// 歌词 (M1.1)
///
/// 解析后的 LRC 格式歌词，用于显示和匹配。
/// 按时间排序，支持翻译行。
@freezed
sealed class Lyrics with _$Lyrics {
  const factory Lyrics({
    /// 歌词行列表 (按 timestamp 升序)
    required List<LyricLine> lines,

    /// 用户校准偏移 (默认 0)
    @Default(Duration.zero) Duration offset,

    /// 歌词来源 (lrclib / bilibili_cc / local)
    String? source,

    /// 匹配得分 (0-1)
    double? matchScore,
  }) = _Lyrics;

  factory Lyrics.fromJson(Map<String, dynamic> json) =>
      _$LyricsFromJson(json);
}
