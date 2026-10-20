import '../../domain/entities/audio_track.dart';

/// 一条 DASH 音频候选流
typedef AudioCandidate = ({
  AudioQuality quality,
  String url,
  List<String> backupUrls,
});

/// 音质选择 (M2.4)
///
/// 规则: `min(用户偏好, 可用最高档)`; 未登录上限 132K (D2)。
/// 没有不高于目标档位的候选时, 退而选可用的最低档。
abstract final class AudioQualitySelector {
  static const AudioQuality guestCap = AudioQuality.k132;

  /// 音质由低到高的排序位置
  static int rank(AudioQuality q) => AudioQuality.values.indexOf(q);

  static AudioQuality? fromId(int id) {
    for (final q in AudioQuality.values) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// 从 playurl 的 `data.dash` 中收集 audio / dolby.audio / flac.audio 候选
  static List<AudioCandidate> collect(Map<String, dynamic> dash) {
    final raw = <Map<String, dynamic>>[
      ...?(dash['audio'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      ...?((dash['dolby'] as Map<String, dynamic>?)?['audio'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      if ((dash['flac'] as Map<String, dynamic>?)?['audio']
          case final Map<String, dynamic> flac)
        flac,
    ];

    final result = <AudioCandidate>[];
    for (final a in raw) {
      final q = fromId(a['id'] as int? ?? -1);
      final url = (a['base_url'] ?? a['baseUrl']) as String?;
      if (q == null || url == null || url.isEmpty) continue;
      final backups = ((a['backup_url'] ?? a['backupUrl']) as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];
      result.add((quality: q, url: url, backupUrls: backups));
    }
    return result;
  }

  static AudioCandidate? select(
    List<AudioCandidate> candidates,
    AudioQuality preferred, {
    required bool loggedIn,
  }) {
    if (candidates.isEmpty) return null;
    var target = preferred;
    if (!loggedIn && rank(target) > rank(guestCap)) target = guestCap;

    final sorted = [...candidates]
      ..sort((a, b) => rank(b.quality).compareTo(rank(a.quality)));
    for (final c in sorted) {
      if (rank(c.quality) <= rank(target)) return c;
    }
    return sorted.last;
  }
}
