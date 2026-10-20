import 'package:freezed_annotation/freezed_annotation.dart';

import 'audio_track.dart';

part 'stream_url.freezed.dart';
part 'stream_url.g.dart';

/// 音频流地址 (M1.1)
///
/// B 站音频流地址有时效性 (通常 2-4 小时)，由 StreamUrlResolver 动态解析和缓存。
/// 数据库存储在 stream_urls 表 (bvid, cid, quality 联合主键)。
@freezed
sealed class StreamUrl with _$StreamUrl {
  const factory StreamUrl({
    /// B 站 BV 号
    required String bvid,

    /// 分P标识
    required int cid,

    /// 音质档位
    required AudioQuality quality,

    /// 流地址 (HTTPS)
    required String url,

    /// 备用流地址 (可选)
    String? backupUrl,

    /// 过期时间 (Unix timestamp)
    required int expiresAt,
  }) = _StreamUrl;

  const StreamUrl._();

  factory StreamUrl.fromJson(Map<String, dynamic> json) =>
      _$StreamUrlFromJson(json);

  /// 判断流地址是否已过期或即将过期 (提前 5 分钟)
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expiresAt - 300;
  }
}
