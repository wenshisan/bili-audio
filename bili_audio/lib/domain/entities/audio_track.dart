import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_track.freezed.dart';
part 'audio_track.g.dart';

/// Track 实体 (M1.1)
///
/// 对应 B 站视频的单个分P，包含播放所需的最小信息。
/// 不包含流地址 (由 StreamUrlResolver 动态解析) 和歌词 (由 LyricsManager 管理)。
@freezed
sealed class Track with _$Track {
  const factory Track({
    /// B 站 BV 号
    required String bvid,

    /// 分P标识 (cid)
    required int cid,

    /// B 站原始标题 (视频标题或分P标题)
    required String title,

    /// 清洗后歌名 (由 TitleCleaner 处理)
    String? cleanedName,

    /// 清洗后歌手 (由 TitleCleaner 处理)
    String? artist,

    /// 时长
    required Duration duration,

    /// 封面 URL
    String? cover,

    /// UP 主名称
    String? uploader,

    /// 分P序号 (1-based)
    int? pageIndex,

    /// 总分P数
    int? totalPages,
  }) = _Track;

  const Track._();

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

  /// 显示用标题: 优先使用清洗后歌名
  String get displayTitle => cleanedName ?? title;

  /// 显示用歌手: 清洗后歌手 > UP主 > 未知
  String get displayArtist => artist ?? uploader ?? '未知';

  /// 缓存键: bvid_cid_quality
  String cacheKey(AudioQuality quality) => '${bvid}_${cid}_${quality.id}';
}

/// 音质档位 (M1.1)
enum AudioQuality {
  k64(id: 30216, name: '64K'),
  k132(id: 30232, name: '132K'),
  k192(id: 30280, name: '192K'),
  dolby(id: 30250, name: 'Dolby'),
  hiRes(id: 30251, name: 'Hi-Res');

  const AudioQuality({required this.id, required this.name});

  final int id;
  final String name;
}
