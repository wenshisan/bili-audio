// ============================================================
// 录音条目 (recordings_feed.dart / file_manager.dart)
//
// 与 RecordingFile 的区别:
// - RecordingFile 是"卡片型"(dateText 已合并 "今天 21:22")
// - RecordingItem 是"表格行型"(dateText/timeText 分列, 用于 1218:4697 表格)
//
// 数据源相同: /sl/app/recording-file/list
// 字段映射:
//   fileId     → id
//   fileName   → title
//   createTime → dateText ("今天" / "5月8日" / "2025/5/8") + timeText ("21:22")
//   duration   → "00:48" (timecode 格式)
//   fileSize   → "56K" (由 fileSize 字节格式化)
//   syncStatus → 由 status 字段推断 (后端 status 0=waiting/1=completed/2=transcribing)
//   transcription → CSV 未直接给,来自 getTextRecordinglList (本字段暂留空)
// ============================================================
import '../utils/api_formatters.dart';

class RecordingItem {
  final String id;
  final String title;
  final String dateText;
  final String timeText;
  final String duration;
  final String syncStatus; // 'synced' | 'syncing' | 'waiting' | 'transcribing'
  final String transcription;
  final bool isAudio;
  final String fileSize; // Figma 1218:4679 表格列, 例如 "56K"

  RecordingItem({
    required this.id,
    required this.title,
    required this.dateText,
    required this.timeText,
    required this.duration,
    required this.syncStatus,
    required this.transcription,
    this.isAudio = true,
    this.fileSize = '56K',
  });

  /// 从 /sl/app/recording-file/list 单条响应构造
  factory RecordingItem.fromJson(Map<String, dynamic> json) {
    final id = asString(json['fileId'] ?? json['id']);
    final title = asString(json['fileName'] ?? json['title'], fallback: id);
    final createMs = asInt(json['createTime']);

    String dateText = '';
    String timeText = '';
    if (createMs > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(createMs);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final that = DateTime(dt.year, dt.month, dt.day);
      final diff = today.difference(that).inDays;
      if (diff == 0) {
        dateText = '今天';
      } else if (diff == 1) {
        dateText = '昨天';
      } else if (dt.year == now.year) {
        dateText = '${dt.month}月${dt.day}日';
      } else {
        dateText = '${dt.year}/${dt.month}/${dt.day}';
      }
      timeText = '${_p2(dt.hour)}:${_p2(dt.minute)}';
    } else {
      dateText = asString(json['dateText']);
      timeText = asString(json['timeText']);
    }

    final durationSec = asInt(json['duration']);
    final fileStatus = mapFileStatusToInternal(json['status']);
    final syncStatus = switch (fileStatus) {
      'completed' => 'synced',
      'transcribing' => 'transcribing',
      'waiting' => 'waiting',
      _ => 'synced',
    };

    final fileSizeBytes = asInt(json['fileSize']);
    final fileSize = fileSizeBytes > 0
        ? _humanSize(fileSizeBytes)
        : asString(json['fileSizeText'], fallback: '56K');

    return RecordingItem(
      id: id,
      title: title,
      dateText: dateText,
      timeText: timeText,
      duration: formatTimecode(durationSec),
      syncStatus: syncStatus,
      transcription: asString(json['transcription']),
      fileSize: fileSize,
    );
  }
}

String _p2(int n) => n.toString().padLeft(2, '0');

String _humanSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
}
